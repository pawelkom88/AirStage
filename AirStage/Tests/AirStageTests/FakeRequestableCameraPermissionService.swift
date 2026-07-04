import AirStage

final class FakeRequestableCameraPermissionService: RequestableCameraPermissionService {

    var currentStatus: CameraPermissionStatus
    private let grantOnRequest: Bool

    init(initial: CameraPermissionStatus, grantOnRequest: Bool) {
        self.currentStatus = initial
        self.grantOnRequest = grantOnRequest
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        if grantOnRequest {
            currentStatus = .authorized
        } else {
            currentStatus = .denied
        }
        completion(grantOnRequest)
    }
}
