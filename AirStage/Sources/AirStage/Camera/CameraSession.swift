/// Abstraction over AVCaptureSession so the preview view model stays testable.
public protocol CameraSession: AnyObject {
    /// Start the session. Calls completion with nil on success or an error message on failure.
    func start(completion: @escaping (String?) -> Void)
    func stop()
}
