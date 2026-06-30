/// Abstraction over AVCaptureDevice.authorizationStatus so tests never need a real camera.
public protocol CameraPermissionService {
    var currentStatus: CameraPermissionStatus { get }
}
