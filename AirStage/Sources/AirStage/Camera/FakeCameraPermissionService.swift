/// Test double for CameraPermissionService.
public final class FakeCameraPermissionService: CameraPermissionService {
    public var currentStatus: CameraPermissionStatus

    public init(status: CameraPermissionStatus) {
        self.currentStatus = status
    }
}
