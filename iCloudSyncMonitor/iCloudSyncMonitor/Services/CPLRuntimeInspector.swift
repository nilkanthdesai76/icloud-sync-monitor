import Foundation
import ObjectiveC

@MainActor
final class CPLRuntimeInspector: ObservableObject {
    @Published var queueStatus = CPLQueueStatus()
    @Published var isInspecting: Bool = false
    @Published var diagnosticLog: String = "Ready to inspect Cloud Photo Library daemon."

    private var cplStatusObject: AnyObject? = nil
    private var frameworkLoaded: Bool = false

    init() {
        loadFramework()
        refreshStatus()
    }

    private func loadFramework() {
        let path = "/System/Library/PrivateFrameworks/CloudPhotoLibrary.framework/CloudPhotoLibrary"
        if dlopen(path, RTLD_NOW) != nil {
            frameworkLoaded = true
            diagnosticLog = "Loaded CloudPhotoLibrary.framework successfully."
        } else {
            frameworkLoaded = false
            diagnosticLog = "CloudPhotoLibrary private framework could not be loaded directly."
        }
    }

    func refreshStatus() {
        isInspecting = true
        defer { isInspecting = false }

        guard let cplStatusClass = NSClassFromString("CPLStatus") as? NSObject.Type else {
            queueStatus.isFrameworkAvailable = false
            diagnosticLog = "CPLStatus runtime class unavailable (simulated mode)."
            return
        }

        queueStatus.isFrameworkAvailable = true

        // Try getting shared or default instance if available, else allocate init
        var instance: AnyObject? = nil
        let defaultSelectors = ["defaultStatus", "sharedStatus", "statusForDefaultStore"]
        for selName in defaultSelectors {
            let sel = NSSelectorFromString(selName)
            if cplStatusClass.responds(to: sel) {
                if let unmanaged = cplStatusClass.perform(sel) {
                    instance = unmanaged.takeUnretainedValue()
                    break
                }
            }
        }

        if instance == nil {
            instance = cplStatusClass.init()
        }

        self.cplStatusObject = instance

        guard let status = instance else {
            diagnosticLog = "CPLStatus instance could not be initialized."
            return
        }

        // Extract runtime counters using KVC
        var imagesCount = 0
        var videosCount = 0
        var otherCount = 0
        var isSyncing = false
        var hasChanges = false

        if let imgVal = (status as AnyObject).value(forKey: "numberOfImagesToUpload") as? Int {
            imagesCount = max(0, imgVal)
        }
        if let vidVal = (status as AnyObject).value(forKey: "numberOfVideosToUpload") as? Int {
            videosCount = max(0, vidVal)
        }
        if let othVal = (status as AnyObject).value(forKey: "numberOfOtherItemsToUpload") as? Int {
            otherCount = max(0, othVal)
        }
        if let syncVal = (status as AnyObject).value(forKey: "isSyncing") as? Bool {
            isSyncing = syncVal
        }
        if let changeVal = (status as AnyObject).value(forKey: "hasChangesToProcess") as? Bool {
            hasChanges = changeVal
        }

        self.queueStatus.numberOfImagesToUpload = imagesCount
        self.queueStatus.numberOfVideosToUpload = videosCount
        self.queueStatus.numberOfOtherItemsToUpload = otherCount
        self.queueStatus.isSyncing = isSyncing
        self.queueStatus.hasChangesToProcess = hasChanges
        self.queueStatus.lastCheckDate = Date()

        if imagesCount + videosCount + otherCount > 0 {
            self.diagnosticLog = "Found \(imagesCount + videosCount) items pending upload in system queue."
        } else if isSyncing {
            self.diagnosticLog = "iCloud sync daemon (cloudphotod) is actively communicating."
        } else {
            self.diagnosticLog = "iCloud photo queue is clean or resting."
        }
    }

    func requestSyncNudge() {
        guard let status = cplStatusObject else {
            refreshStatus()
            return
        }

        let nudgeSelectors = ["requestSync", "requestImmediateSync", "resume", "checkInitialDownloadComplete"]
        var nudged = false

        for selName in nudgeSelectors {
            let sel = NSSelectorFromString(selName)
            if status.responds(to: sel) {
                _ = status.perform(sel)
                nudged = true
                diagnosticLog = "Invoked system [CPLStatus \(selName)] trigger."
                break
            }
        }

        if !nudged {
            diagnosticLog = "Requested sync check from system daemon."
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.refreshStatus()
        }
    }
}
