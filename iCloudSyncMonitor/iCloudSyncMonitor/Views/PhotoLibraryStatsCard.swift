import SwiftUI
import Photos

struct PhotoLibraryStatsCard: View {
    @ObservedObject var analyzer: PhotoLibraryAnalyzer

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Local Photo Library", systemImage: "photo.stack.fill")
                    .font(.headline)

                Spacer()

                if analyzer.isScanning {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button {
                        analyzer.scanLibrary()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption.weight(.semibold))
                    }
                }
            }

            if analyzer.authStatus == .authorized || analyzer.authStatus == .limited {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TOTAL ASSETS")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                        Text("\(analyzer.snapshot.totalAssets.formatted())")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                    }

                    Divider().frame(height: 36)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("PHOTOS")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                        Text("\(analyzer.snapshot.totalPhotos.formatted())")
                            .font(.headline)
                    }

                    Divider().frame(height: 36)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("VIDEOS")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                        Text("\(analyzer.snapshot.totalVideos.formatted())")
                            .font(.headline)
                    }
                }

                if analyzer.snapshot.recentlyAdded24h > 0 {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.blue)
                        Text("\(analyzer.snapshot.recentlyAdded24h.formatted()) items added in the last 24h")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.blue)
                    }
                    .padding(.top, 2)
                }

                if analyzer.snapshot.sampleLocalCount + analyzer.snapshot.sampleCloudCount > 0 {
                    HStack(spacing: 8) {
                        Text("Sample Recent Assets:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("💾 \(analyzer.snapshot.sampleLocalCount) Local")
                            .font(.caption2.weight(.semibold))
                        Text("☁️ \(analyzer.snapshot.sampleCloudCount) In Cloud")
                            .font(.caption2.weight(.semibold))
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Photo Library access required to inspect local assets.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button("Grant Photo Access") {
                        Task {
                            await analyzer.requestPermissionAndScan()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
