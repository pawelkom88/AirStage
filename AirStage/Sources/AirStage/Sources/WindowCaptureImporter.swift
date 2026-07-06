import Foundation
import CoreGraphics
import OSLog

public enum WindowCaptureImportError: LocalizedError, Equatable {
    case limitExceeded
    case sceneFull
    case captureError(String)

    public var errorDescription: String? {
        switch self {
        case .limitExceeded:
            return "Cannot add window capture. Only one window or screen layer is allowed at a time."
        case .sceneFull:
            return "Cannot add window capture. The scene is full — remove a layer first."
        case .captureError(let msg):
            return "Window capture failed: \(msg)"
        }
    }
}

/// Handles adding a window/screen capture layer to the scene, enforcing the one-window limit.
public final class WindowCaptureImporter {
    private let store: SceneStore

    public init(store: SceneStore) {
        self.store = store
    }

    /// Attempts to add a window capture layer.
    /// Returns `.success(layerID)` or `.failure(error)`.
    public func importCapture(
        title: String,
        captureID: String,
        position: CGPoint = CGPoint(x: 320, y: 240),
        size: CGSize = CGSize(width: 240, height: 180)
    ) -> Result<UUID, WindowCaptureImportError> {
        AppLog.sources.info("Importing window capture title=\(title, privacy: .public) captureID=\(captureID, privacy: .public)")

        let result = store.addWindowCapture(
            title: title,
            position: position,
            size: size
        )

        switch result {
        case .success(let id):
            AppLog.sources.info("Window capture layer added id=\(id.uuidString, privacy: .public)")
            return .success(id)
        case .failure(let reason):
            switch reason {
            case .kindLimitExceeded:
                AppLog.sources.error("Window capture limit exceeded")
                return .failure(.limitExceeded)
            case .sceneFull:
                AppLog.sources.error("Scene full, cannot add window capture")
                return .failure(.sceneFull)
            }
        }
    }
}
