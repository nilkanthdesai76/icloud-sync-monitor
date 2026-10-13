import Foundation
import Photos

@MainActor
final class PhotoLibraryAnalyzer: ObservableObject {
    @Published var snapshot = LibrarySnapshot()
    @Published var isScanning: Bool = false
    @Published var authStatus: PHAuthorizationStatus = .notDetermined

    init() {
        self.authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        scanLibrary()
    }

    func requestPermissionAndScan() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        self.authStatus = status
        if status == .authorized || status == .limited {
            scanLibrary()
        }
    }

    func scanLibrary() {
        guard authStatus == .authorized || authStatus == .limited else { return }

        isScanning = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let photosFetch = PHAsset.fetchAssets(with: .image, options: nil)
            let videosFetch = PHAsset.fetchAssets(with: .video, options: nil)

            let calendar = Calendar.current
            let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            let recentOptions = PHFetchOptions()
            recentOptions.predicate = NSPredicate(format: "creationDate >= %@", yesterday as NSDate)
            recentOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let recentFetch = PHAsset.fetchAssets(with: recentOptions)

            // Fast sample check on up to 40 recent items to estimate local vs cloud ratio
            var sampleLocal = 0
            var sampleCloud = 0
            let sampleLimit = min(40, recentFetch.count)

            let imgOptions = PHImageRequestOptions()
            imgOptions.isNetworkAccessAllowed = false
            imgOptions.isSynchronous = true
            imgOptions.deliveryMode = .fastFormat

            let imageManager = PHImageManager.default()

            for i in 0..<sampleLimit {
                let asset = recentFetch.object(at: i)
                imageManager.requestImageDataAndOrientation(for: asset, options: imgOptions) { data, _, _, info in
                    let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
                    let isInCloud = info?[PHImageResultIsInCloudKey] as? Bool ?? false
                    if isInCloud || (data == nil && !isDegraded) {
                        sampleCloud += 1
                    } else {
                        sampleLocal += 1
                    }
                }
            }

            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.snapshot.totalPhotos = photosFetch.count
                self.snapshot.totalVideos = videosFetch.count
                self.snapshot.recentlyAdded24h = recentFetch.count
                self.snapshot.sampleLocalCount = sampleLocal
                self.snapshot.sampleCloudCount = sampleCloud
                self.snapshot.lastScanDate = Date()
                self.isScanning = false
            }
        }
    }
}
