import Foundation
import UniformTypeIdentifiers
import OSLog
import AppKit

public enum ImageImportError: LocalizedError, Equatable {
    case unsupportedFormat
    case limitExceeded
    case other(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "The selected file is not a supported image format. Please select a PNG, JPEG, HEIC, or TIFF image."
        case .limitExceeded:
            return "Cannot add image layer. The maximum limit of 3 image layers has been reached."
        case .other(let msg):
            return msg
        }
    }
}

public final class ImageImporter {
    private let store: SceneStore

    public init(store: SceneStore) {
        self.store = store
    }

    public func importImage(
        from url: URL,
        replaceOldestIfFull: Bool = false
    ) -> Result<UUID, ImageImportError> {
        // Log selected image path as private
        AppLog.sources.info("Importing image from path=\(url.path, privacy: .private)")

        // Check if supported image format
        guard isSupportedImage(url: url) else {
            AppLog.sources.error("Failed to import image: unsupported format path=\(url.path, privacy: .private)")
            return .failure(.unsupportedFormat)
        }

        // Generate title from filename
        let filename = url.lastPathComponent
        
        var initialSize = CGSize(width: 200, height: 150)
        if let image = NSImage(contentsOf: url) {
            let imageSize = image.size
            if imageSize.width > 0 && imageSize.height > 0 {
                let maxDim: CGFloat = 250
                let ratio = imageSize.width / imageSize.height
                if ratio > 1 {
                    initialSize = CGSize(width: maxDim, height: maxDim / ratio)
                } else {
                    initialSize = CGSize(width: maxDim * ratio, height: maxDim)
                }
            }
        }
        
        // Spawn at a default position (e.g. center) and default size (e.g. 200x150)
        let result = store.addImage(
            title: filename,
            imageURL: url,
            position: CGPoint(x: 320, y: 240),
            size: initialSize,
            replaceOldestIfFull: replaceOldestIfFull
        )

        switch result {
        case .success(let id):
            return .success(id)
        case .failure(let reason):
            AppLog.sources.error("Failed to add image layer to store: \(String(describing: reason), privacy: .public)")
            return .failure(.limitExceeded)
        }
    }

    private func isSupportedImage(url: URL) -> Bool {
        // UTType conforms to .image
        if let type = UTType(filenameExtension: url.pathExtension) {
            return type.conforms(to: .image)
        }
        // Fallback for some common extensions if UTType is nil
        let allowed = ["png", "jpg", "jpeg", "heic", "tiff", "tif", "webp", "gif"]
        return allowed.contains(url.pathExtension.lowercased())
    }
}
