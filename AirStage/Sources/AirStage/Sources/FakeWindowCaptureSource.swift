import Foundation

/// Fake capture source for unit tests. Returns queued windows and configurable errors.
public final class FakeWindowCaptureSource: WindowCaptureSource {
    public var availableWindows: [CaptureTarget] = []
    public var shouldFailWithError: String?
    public private(set) var isCapturing = false
    public private(set) var capturedTargetID: String?

    public init() {}

    public func availableTargets(completion: @escaping ([CaptureTarget]) -> Void) {
        completion(availableWindows)
    }

    public func startCapture(targetID: String, completion: @escaping (String?) -> Void) {
        if let error = shouldFailWithError {
            completion(error)
            return
        }
        isCapturing = true
        capturedTargetID = targetID
        completion(nil)
    }

    public func stopCapture() {
        isCapturing = false
        capturedTargetID = nil
    }
}
