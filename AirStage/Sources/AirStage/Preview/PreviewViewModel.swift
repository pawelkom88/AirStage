import Foundation

/// Observable state for the preview window.
/// Kept free of AppKit/SwiftUI so it can be unit-tested directly.
public final class PreviewViewModel {

    public private(set) var cameraState: CameraState
    /// Non-nil when permission was denied; contains a user-friendly recovery message.
    public private(set) var permissionDeniedMessage: String?

    private let permissionService: CameraPermissionService
    private let cameraSession: CameraSession?

    public init(
        permissionService: CameraPermissionService,
        cameraSession: CameraSession? = nil
    ) {
        self.permissionService = permissionService
        self.cameraSession = cameraSession
        let resolved = Self.resolve(permissionService.currentStatus)
        self.cameraState = resolved
        AppLog.camera.info("Camera permission status=\(String(describing: permissionService.currentStatus), privacy: .public)")
        AppLog.camera.info("Preview camera state=\(String(describing: resolved), privacy: .public)")
    }

    // MARK: - Permission

    /// Requests camera permission if not already determined.
    public func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        guard let requestable = permissionService as? RequestableCameraPermissionService else {
            completion(permissionService.currentStatus == .authorized)
            return
        }
        requestable.requestPermission { [weak self] granted in
            guard let self else { return }
            if granted {
                self.cameraState = .ready
                self.permissionDeniedMessage = nil
                AppLog.camera.info("Camera permission granted")
            } else {
                self.cameraState = .permissionRequired
                self.permissionDeniedMessage = "Camera access was denied. Open System Settings → Privacy & Security → Camera to allow AirStage."
                AppLog.camera.info("Camera permission denied — recovery message set")
            }
            completion(granted)
        }
    }

    // MARK: - Session

    /// Starts the camera session if permission is granted.
    public func startCameraSessionIfReady() {
        guard cameraState == .ready, let session = cameraSession else { return }
        AppLog.camera.info("Camera session starting")
        session.start { [weak self] error in
            guard let self else { return }
            if let error {
                self.cameraState = .failed(error)
                AppLog.camera.error("Camera session failed error=\(error, privacy: .public)")
            } else {
                self.cameraState = .running
                AppLog.camera.info("Camera session running")
            }
        }
    }

    public func stopCameraSession() {
        cameraSession?.stop()
        AppLog.camera.info("Camera session stopped")
    }

    // MARK: - Helpers

    private static func resolve(_ status: CameraPermissionStatus) -> CameraState {
        switch status {
        case .authorized:                       return .ready
        case .notDetermined, .denied, .restricted: return .permissionRequired
        }
    }
}
