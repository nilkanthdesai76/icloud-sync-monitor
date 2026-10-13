import Foundation
import UIKit
import Network
import Combine

@MainActor
final class SystemHealthGovernor: ObservableObject {
    @Published var health = SystemHealthStatus()

    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.nilkanthdesai.networkmonitor")
    private var cancellables = Set<AnyCancellable>()

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        setupNetworkMonitoring()
        setupSystemObservers()
        evaluateHealth()
    }

    private func setupNetworkMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let netType: NetworkInterfaceType
                if path.status == .satisfied {
                    if path.usesInterfaceType(.wifi) {
                        netType = .wifi
                    } else if path.usesInterfaceType(.cellular) {
                        netType = .cellular
                    } else {
                        netType = .unknown
                    }
                } else {
                    netType = .offline
                }
                self?.health.networkType = netType
                self?.evaluateHealth()
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }

    private func setupSystemObservers() {
        NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.evaluateHealth() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.evaluateHealth() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: ProcessInfo.thermalStateDidChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.evaluateHealth() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSNotification.Name.NSProcessInfoPowerStateDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.evaluateHealth() }
            .store(in: &cancellables)
    }

    func evaluateHealth() {
        let device = UIDevice.current
        let pInfo = ProcessInfo.processInfo

        let bLevel = device.batteryLevel >= 0 ? device.batteryLevel : 1.0
        let isPluggedIn = device.batteryState == .charging || device.batteryState == .full
        let thermal = pInfo.thermalState
        let lowPower = pInfo.isLowPowerModeEnabled
        let net = health.networkType

        health.batteryLevel = bLevel
        health.isCharging = isPluggedIn
        health.thermalState = thermal
        health.isLowPowerModeEnabled = lowPower

        var throttled = false
        var recommendation = ""

        if lowPower {
            throttled = true
            recommendation = "⚠️ Low Power Mode is Active: Apple completely pauses background iCloud photo uploads. Turn off Low Power Mode to resume backup."
        } else if thermal == .serious || thermal == .critical {
            throttled = true
            recommendation = "🔥 Thermal Throttling Active (\(health.thermalTitle)): The device is too warm. Apple halts cloud uploads to protect the battery. Keep phone in a cool environment."
        } else if net == .offline {
            throttled = true
            recommendation = "🚫 Disconnected from Internet: Connect to Wi-Fi to allow iCloud photo syncing."
        } else if !isPluggedIn && bLevel < 0.3 {
            throttled = true
            recommendation = "⚡ Low Battery (\(Int(bLevel * 100))%): Connect to a 20W+ charger. Apple restricts large photo uploads until power is connected."
        } else if net == .cellular {
            recommendation = "📶 On Cellular Data: Sync may be limited unless 'Unlimited Updates' is enabled in Settings -> Photos. High-speed 5GHz Wi-Fi is recommended."
        } else if isPluggedIn && thermal == .nominal {
            recommendation = "🚀 Optimal Upload State: Phone is plugged in, SoC is cool, and high-speed network is connected. Apple's cloudphotod runs at full priority."
        } else {
            recommendation = "⚡ Good Condition: Keep phone charging and connected to Wi-Fi to expedite photo backup."
        }

        health.isThrottled = throttled
        health.syncRecommendation = recommendation
    }
}
