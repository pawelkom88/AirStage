/// Extends CameraPermissionService with the ability to asynchronously request permission.
public protocol RequestableCameraPermissionService: CameraPermissionService {
    func requestPermission(completion: @escaping (Bool) -> Void)
}
