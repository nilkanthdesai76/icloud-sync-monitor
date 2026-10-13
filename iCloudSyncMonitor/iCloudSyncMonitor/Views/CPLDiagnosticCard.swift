import SwiftUI

struct CPLDiagnosticCard: View {
    @ObservedObject var inspector: CPLRuntimeInspector

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("iCloud Photos System Daemon", systemImage: "icloud.and.arrow.up.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                if inspector.isInspecting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(inspector.queueStatus.isSyncing ? Color.green : (inspector.queueStatus.totalPendingUpload > 0 ? Color.orange : Color.blue))
                            .frame(width: 8, height: 8)
                        Text(inspector.queueStatus.isSyncing ? "Syncing" : "Active")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("CURRENT DAEMON STATUS")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(inspector.queueStatus.statusDescription)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(inspector.queueStatus.isSyncing ? Color.primary : (inspector.queueStatus.totalPendingUpload > 0 ? Color.orange : Color.primary))
            }

            if inspector.queueStatus.totalPendingUpload > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.orange)
                    Text("\(inspector.queueStatus.totalPendingUpload.formatted()) items queued for iCloud backup")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }

            if let reason = inspector.queueStatus.pauseReason, !reason.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("Paused: \(reason)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if inspector.queueStatus.isBlockedByLowPowerMode {
                HStack(spacing: 8) {
                    Image(systemName: "battery.25")
                        .foregroundStyle(.yellow)
                    Text("Sync paused by Low Power Mode. Connect charger to resume.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(inspector.diagnosticLog)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 10) {
                Button {
                    inspector.refreshStatus()
                } label: {
                    Label("Check Status", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)

                Button {
                    inspector.requestSyncNudge()
                } label: {
                    Label("Nudge Sync", systemImage: "bolt.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
