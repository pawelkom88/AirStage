import CoreGraphics

public enum GestureEvent: Equatable {
    case none
    case pinchBegan(at: CGPoint)
    case pinchMoved(to: CGPoint)
    case pinchEnded
}

public struct GestureEngine {
    private var isPinching = false

    public init() {}

    public mutating func process(_ frame: HandPoseFrame) -> GestureEvent {
        guard let center = frame.pinchCandidateCenter else {
            guard isPinching else { return .none }
            isPinching = false
            AppLog.gestures.info("Pinch ended hand=primary")
            return .pinchEnded
        }

        if isPinching {
            AppLog.gestures.debug("Pinch moved x=\(center.x) y=\(center.y)")
            return .pinchMoved(to: center)
        }

        isPinching = true
        AppLog.gestures.info("Pinch began hand=primary")
        return .pinchBegan(at: center)
    }
}
