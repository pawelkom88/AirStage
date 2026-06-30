/// Test double for RequestableCameraPermissionService.
public final class FakeRequestableCameraPermissionService: RequestableCameraPermissionService {

    public var currentStatus: CameraPermissionStatus
    private let grantOnRequest: Bool

    public init(initial: CameraPermissionStatus, grantOnRequest: Bool) {
        self.currentStatus = initial
        self.grantOnRequest = grantOnRequest
    }

    public func requestPermission(completion: @escaping (Bool) -> Void) {
        if grantOnRequest {
            currentStatus = .authorized
        } else {
            currentStatus = .denied
        }
        completion(grantOnRequest)
    }
}
