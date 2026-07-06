import Foundation

/// Protocol abstracting ScreenCaptureKit access so tests can use a fake.
public protocol WindowCaptureSource {
    /// Fetches available capture targets (windows and screens).
    func availableTargets(completion: @escaping ([CaptureTarget]) -> Void)

    /// Starts capturing the target with the given ID.
    /// Calls completion with nil on success, or an error string on failure.
    func startCapture(targetID: String, completion: @escaping (String?) -> Void)

    /// Stops any active capture.
    func stopCapture()
}
