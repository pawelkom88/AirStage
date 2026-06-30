import AVFoundation
import AirStage

/// Real AVFoundation-backed implementation of RequestableCameraPermissionService.
final class AVCameraPermissionService: RequestableCameraPermissionService {

    var currentStatus: CameraPermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:    return .authorized
        case .denied:        return .denied
        case .restricted:    return .restricted
        case .notDetermined: return .notDetermined
        @unknown default:    return .notDetermined
        }
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                AppLog.camera.info("Camera permission status=\(granted ? "authorized" : "denied", privacy: .public)")
                completion(granted)
            }
        }
    }
}
