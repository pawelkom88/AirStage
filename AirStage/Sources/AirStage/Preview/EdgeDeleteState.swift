import Foundation

public enum EdgeDeleteSide: Equatable {
    case left
    case right
}

public enum EdgeDeleteState: Equatable {
    case idle
    case arming(side: EdgeDeleteSide, layerID: UUID, startedAt: Date)
    case disintegrating(side: EdgeDeleteSide, layerID: UUID)
}

public extension EdgeDeleteState {
    var side: EdgeDeleteSide? {
        switch self {
        case .idle:
            return nil
        case .arming(let side, _, _),
             .disintegrating(let side, _):
            return side
        }
    }

    var layerID: UUID? {
        switch self {
        case .idle:
            return nil
        case .arming(_, let id, _),
             .disintegrating(_, let id):
            return id
        }
    }

    var isArmed: Bool {
        if case .arming = self { return true }
        return false
    }

    var isDisintegrating: Bool {
        if case .disintegrating = self { return true }
        return false
    }

    static func badgePosition(side: EdgeDeleteSide, cardFrame: CGRect, sceneBounds: CGRect) -> CGPoint {
        let y = min(max(cardFrame.midY, sceneBounds.minY + 60), sceneBounds.maxY - 60)
        switch side {
        case .left:
            return CGPoint(x: sceneBounds.minX + 56, y: y)
        case .right:
            return CGPoint(x: sceneBounds.maxX - 56, y: y)
        }
    }
}

public func commitProgress(for state: EdgeDeleteState, now: Date, deleteDelay: TimeInterval) -> Double {
    guard case .arming(_, _, let startedAt) = state else { return 0 }
    let duration = now.timeIntervalSince(startedAt)
    if duration <= 0 || deleteDelay <= 0 { return 0 }
    return min(duration / deleteDelay, 1.0)
}
