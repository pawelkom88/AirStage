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
}
