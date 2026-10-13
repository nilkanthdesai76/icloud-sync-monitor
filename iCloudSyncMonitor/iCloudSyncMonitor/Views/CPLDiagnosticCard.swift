import SwiftUI

struct CPLDiagnosticCard: View {
    @ObservedObject var inspector: CPLRuntimeInspector

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("iCloud Photos System Daemon", systemImage: "icloud.and.arrow.up.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                if inspector.isInspecting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Circle()
                        .fill(inspector.queueStatus.isSyncing ? Color.green : (inspector.queueStatus.totalPendingUpload > 0 ? Color.orange : Color.blue))
                        .frame(width: 10, height: 10)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PENDING UPLOAD")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text("\(inspector.queueStatus.totalPendingUpload.formatted())")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(inspector.queueStatus.totalPendingUpload > 0 ? .orange : .green)
                }

                Divider()
                    .frame(height: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text("PHOTOS")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text("\(inspector.queueStatus.numberOfImagesToUpload.formatted())")
                        .font(.headline)
                }

                Divider()
                    .frame(height: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text("VIDEOS")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text("\(inspector.queueStatus.numberOfVideosToUpload.formatted())")
                        .font(.headline)
                }
            }
            .padding(.vertical, 4)

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
