import AirStage

final class FakeCameraPermissionService: CameraPermissionService {
    var currentStatus: CameraPermissionStatus

    init(status: CameraPermissionStatus) {
        self.currentStatus = status
    }
}
