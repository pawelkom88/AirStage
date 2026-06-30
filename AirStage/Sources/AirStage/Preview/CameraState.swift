/// The observable state of the preview window's camera surface.
public enum CameraState: Equatable {
    /// Permission has not been granted; show the friendly placeholder.
    case permissionRequired
    /// Permission is granted; the camera session can start.
    case ready
    /// Camera session is actively running.
    case running
    /// Camera session failed.
    case failed(String)

    public static func == (lhs: CameraState, rhs: CameraState) -> Bool {
        switch (lhs, rhs) {
        case (.permissionRequired, .permissionRequired): return true
        case (.ready, .ready):                           return true
        case (.running, .running):                       return true
        case (.failed(let a), .failed(let b)):           return a == b
        default:                                         return false
        }
    }
}
