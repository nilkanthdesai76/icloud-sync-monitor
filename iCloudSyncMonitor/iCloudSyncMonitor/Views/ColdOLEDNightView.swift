import SwiftUI

struct ColdOLEDNightView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var cplInspector: CPLRuntimeInspector
    @ObservedObject var governor: SystemHealthGovernor

    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button {
                        UIApplication.shared.isIdleTimerDisabled = false
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Exit Turbo Mode")
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.gray)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1), in: Capsule())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)

                Spacer()

                VStack(spacing: 8) {
                    Text(currentTime, style: .time)
                        .font(.system(size: 64, weight: .thin, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.85))

                    Text("OVERNIGHT TURBO SYNC ACTIVE")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(.green)
                }

                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(cplInspector.queueStatus.isSyncing ? Color.green : Color.blue)
                                .frame(width: 8, height: 8)
                            Text(cplInspector.queueStatus.isSyncing ? "iCloud Syncing" : "Queue Monitored")
                                .font(.caption.monospaced())
                                .foregroundStyle(.gray)
                        }

                        HStack(spacing: 6) {
                            Image(systemName: governor.health.isCharging ? "bolt.fill" : "battery.50")
                                .foregroundStyle(governor.health.isCharging ? .green : .yellow)
                            Text("\(Int(governor.health.batteryLevel * 100))%")
                                .font(.caption.monospaced())
                                .foregroundStyle(.gray)
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "thermometer.medium")
                                .foregroundStyle(Color(governor.health.thermalColor))
                            Text(governor.health.thermalTitle.components(separatedBy: " ").first ?? "Cool")
                                .font(.caption.monospaced())
                                .foregroundStyle(.gray)
                        }
                    }

                    if cplInspector.queueStatus.totalPendingUpload > 0 {
                        Text("\(cplInspector.queueStatus.totalPendingUpload.formatted()) items pending in Apple upload queue")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.white.opacity(0.7))
                    } else {
                        Text("\(cplInspector.queueStatus.statusDescription) • Screen at 0% OLED power")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                Spacer()

                Text("Double tap screen or tap Exit to leave")
                    .font(.caption2)
                    .foregroundStyle(.gray.opacity(0.6))
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onReceive(timer) { newTime in
            currentTime = newTime
            governor.evaluateHealth()
        }
        .onTapGesture(count: 2) {
            UIApplication.shared.isIdleTimerDisabled = false
            dismiss()
        }
    }
}
