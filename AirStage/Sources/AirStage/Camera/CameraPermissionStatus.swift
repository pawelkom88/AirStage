/// Platform-agnostic camera permission status.
/// Maps 1-to-1 with AVAuthorizationStatus so the real adapter is trivial.
public enum CameraPermissionStatus: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
}
