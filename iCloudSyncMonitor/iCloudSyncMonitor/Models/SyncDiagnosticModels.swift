import Foundation
import UIKit
import Photos

struct CPLQueueStatus: Equatable {
    var numberOfImagesToUpload: Int = 0
    var numberOfVideosToUpload: Int = 0
    var numberOfOtherItemsToUpload: Int = 0
    var isSyncing: Bool = false
    var hasChangesToProcess: Bool = false
    var isFrameworkAvailable: Bool = false
    var pauseReason: String? = nil
    var lastCheckDate: Date = Date()

    var totalPendingUpload: Int {
        numberOfImagesToUpload + numberOfVideosToUpload + numberOfOtherItemsToUpload
    }
}

enum NetworkInterfaceType: String {
    case wifi = "5GHz / High-Speed Wi-Fi"
    case cellular = "Cellular Data"
    case offline = "Disconnected / Offline"
    case unknown = "Local Network"
}

struct SystemHealthStatus: Equatable {
    var batteryLevel: Float = 1.0
    var isCharging: Bool = false
    var thermalState: ProcessInfo.ThermalState = .nominal
    var isLowPowerModeEnabled: Bool = false
    var networkType: NetworkInterfaceType = .wifi
    var syncRecommendation: String = "Evaluating system conditions..."
    var isThrottled: Bool = false

    var thermalTitle: String {
        switch thermalState {
        case .nominal: return "Nominal (Cool)"
        case .fair: return "Fair (Warm)"
        case .serious: return "Serious (Hot - Pausing)"
        case .critical: return "Critical (Overheating)"
        @unknown default: return "Unknown"
        }
    }

    var thermalColor: UIColor {
        switch thermalState {
        case .nominal: return .systemGreen
        case .fair: return .systemYellow
        case .serious: return .systemOrange
        case .critical: return .systemRed
        @unknown default: return .systemGray
        }
    }
}

struct LibrarySnapshot: Equatable {
    var totalPhotos: Int = 0
    var totalVideos: Int = 0
    var recentlyAdded24h: Int = 0
    var sampleLocalCount: Int = 0
    var sampleCloudCount: Int = 0
    var lastScanDate: Date = Date()

    var totalAssets: Int {
        totalPhotos + totalVideos
    }
}
