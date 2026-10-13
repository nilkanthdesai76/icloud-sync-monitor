import SwiftUI

struct SystemGovernorCard: View {
    @ObservedObject var governor: SystemHealthGovernor

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Sync Environment & Thermals", systemImage: "gauge.with.needle.fill")
                    .font(.headline)
                Spacer()
                Text(governor.health.isThrottled ? "THROTTLED" : "OPTIMAL")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(governor.health.isThrottled ? Color.red.opacity(0.15) : Color.green.opacity(0.15), in: Capsule())
                    .foregroundStyle(governor.health.isThrottled ? .red : .green)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(
                        governor.health.isCharging ? "Charging (\(Int(governor.health.batteryLevel * 100))%)" : "On Battery (\(Int(governor.health.batteryLevel * 100))%)",
                        systemImage: governor.health.isCharging ? "bolt.batteryblock.fill" : "battery.50"
                    )
                    .font(.subheadline)
                    .foregroundStyle(governor.health.isCharging ? .green : .secondary)

                    Spacer()

                    Label(
                        governor.health.thermalTitle,
                        systemImage: "thermometer.medium"
                    )
                    .font(.subheadline)
                    .foregroundStyle(Color(governor.health.thermalColor))
                }

                HStack {
                    Label(
                        governor.health.networkType.rawValue,
                        systemImage: governor.health.networkType == .wifi ? "wifi" : (governor.health.networkType == .cellular ? "antenna.radiowaves.left.and.right" : "wifi.slash")
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Spacer()

                    if governor.health.isLowPowerModeEnabled {
                        Label("Low Power Mode", systemImage: "battery.25")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding(.vertical, 2)

            Text(governor.health.syncRecommendation)
                .font(.footnote)
                .foregroundStyle(governor.health.isThrottled ? .red : .secondary)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
