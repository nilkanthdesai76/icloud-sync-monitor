import SwiftUI

struct ContentView: View {
    @StateObject private var cplInspector = CPLRuntimeInspector()
    @StateObject private var governor = SystemHealthGovernor()
    @StateObject private var photoAnalyzer = PhotoLibraryAnalyzer()

    @State private var showingNightMode = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    heroTurboBanner
                    CPLDiagnosticCard(inspector: cplInspector)
                    SystemGovernorCard(governor: governor)
                    PhotoLibraryStatsCard(analyzer: photoAnalyzer)
                    quickActionShortcuts
                }
                .padding()
            }
            .navigationTitle("iCloud Photo Monitor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        cplInspector.refreshStatus()
                        governor.evaluateHealth()
                        photoAnalyzer.scanLibrary()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable {
                cplInspector.refreshStatus()
                governor.evaluateHealth()
                photoAnalyzer.scanLibrary()
            }
            .fullScreenCover(isPresented: $showingNightMode) {
                ColdOLEDNightView(
                    cplInspector: cplInspector,
                    governor: governor
                )
            }
        }
    }

    private var heroTurboBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("OVERNIGHT ACCELERATOR")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.8))
                    Text("Overnight Turbo Mode")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }

                Spacer()

                Image(systemName: "moon.stars.fill")
                    .font(.title)
                    .foregroundStyle(.yellow)
            }

            Text("Prevents iOS from sleeping while turning the display pitch-black (0% OLED power), keeping the iPhone cool and network hot for maximum iCloud upload speed.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.85))

            Button {
                showingNightMode = true
            } label: {
                Label("Launch Overnight Turbo Mode", systemImage: "bolt.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.9), Color.indigo.opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    private var quickActionShortcuts: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("System Controls")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                Button {
                    if let url = URL(string: "photos-redirect://") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Apple Photos", systemImage: "photo.on.rectangle")
                        .font(.footnote.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("App Settings", systemImage: "gear")
                        .font(.footnote.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}
