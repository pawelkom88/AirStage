/// Test double for CameraSession.
public final class FakeCameraSession: CameraSession {
    public var didStart = false
    public var didStop = false
    public var failOnStart = false

    public init() {}

    public func start(completion: @escaping (String?) -> Void) {
        if failOnStart {
            completion("Fake camera start failure")
        } else {
            didStart = true
            completion(nil)
        }
    }

    public func stop() {
        didStop = true
    }
}
