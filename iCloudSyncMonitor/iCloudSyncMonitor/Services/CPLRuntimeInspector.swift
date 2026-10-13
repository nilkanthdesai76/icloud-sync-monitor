import Foundation

@MainActor
final class CPLRuntimeInspector: ObservableObject {
    @Published var queueStatus = CPLQueueStatus()
    @Published var isInspecting: Bool = false
    @Published var diagnosticLog: String = "Monitoring Cloud Photo Library status..."

    init() {
        refreshStatus()
    }

    func refreshStatus() {
        isInspecting = true
        defer { isInspecting = false }

        let report = CPLEngineProbe.probeStatus()

        queueStatus.isFrameworkAvailable = report.isAvailable
        if let desc = report.statusDescription, !desc.isEmpty {
            queueStatus.statusDescription = desc
        } else if report.hasChangesToProcess {
            queueStatus.statusDescription = "Changes Pending Upload"
        } else {
            queueStatus.statusDescription = "All Photos Synced / Idle"
        }

        queueStatus.pendingUploadCount = report.pendingCountEstimate
        queueStatus.hasChangesToProcess = report.hasChangesToProcess
        queueStatus.isBlockedByLowPowerMode = report.isBlockedByLowPowerMode
        queueStatus.hasThermalPressure = report.hasThermalPressure
        queueStatus.pauseReason = report.blockedReason

        let descLower = (report.statusDescription ?? "").lowercased()
        let isActivelyUploading = descLower.contains("uploading") || descLower.contains("syncing") || report.hasChangesToProcess
        queueStatus.isSyncing = isActivelyUploading
        queueStatus.lastCheckDate = Date()

        if let log = report.diagnosticLog, !log.isEmpty {
            self.diagnosticLog = log
        } else if report.pendingCountEstimate > 0 {
            self.diagnosticLog = "Pending upload count: \(report.pendingCountEstimate) items detected."
        } else {
            self.diagnosticLog = "Daemon is idle or waiting for scheduled window."
        }
    }

    func requestSyncNudge() {
        diagnosticLog = "Triggering sync nudge via CloudPhotoLibrary engine..."
        let success = CPLEngineProbe.nudgeSync()

        if success {
            diagnosticLog = "Sync nudge command delivered to background daemon."
        } else {
            diagnosticLog = "Sync request submitted (system may schedule based on thermal state)."
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.refreshStatus()
        }
    }
}
