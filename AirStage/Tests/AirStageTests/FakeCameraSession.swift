import AirStage

final class FakeCameraSession: CameraSession {
    var didStart = false
    var didStop = false
    var failOnStart = false

    init() {}

    func start(completion: @escaping (String?) -> Void) {
        if failOnStart {
            completion("Fake camera start failure")
        } else {
            didStart = true
            completion(nil)
        }
    }

    func stop() {
        didStop = true
    }
}
