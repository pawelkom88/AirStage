import Foundation

public enum EdgeDeleteSide: Equatable {
    case left
    case right
}

public enum EdgeDeleteState: Equatable {
    case idle
    case hovering(side: EdgeDeleteSide, layerID: UUID, enteredAt: Date)
    case armed(side: EdgeDeleteSide, layerID: UUID, armedAt: Date)
    case disintegrating(side: EdgeDeleteSide, layerID: UUID)
}

public extension EdgeDeleteState {
    var side: EdgeDeleteSide? {
        switch self {
        case .idle:
            return nil
        case .hovering(let side, _, _),
             .armed(let side, _, _),
             .disintegrating(let side, _):
            return side
        }
    }

    var layerID: UUID? {
        switch self {
        case .idle:
            return nil
        case .hovering(_, let id, _),
             .armed(_, let id, _),
             .disintegrating(_, let id):
            return id
        }
    }

    var isArmed: Bool {
        if case .armed = self { return true }
        return false
    }

    var isDisintegrating: Bool {
        if case .disintegrating = self { return true }
        return false
    }

    var isHoveringOnly: Bool {
        if case .hovering = self { return true }
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
