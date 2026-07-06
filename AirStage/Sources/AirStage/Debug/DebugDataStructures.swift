import Foundation
import CoreGraphics

public struct HandDebugPoint: Identifiable, Equatable {
    public let id = UUID()
    public let label: String
    public let rawNormalized: CGPoint
    public let canvasPoint: CGPoint
    public let confidence: CGFloat

    public init(label: String, rawNormalized: CGPoint, canvasPoint: CGPoint, confidence: CGFloat) {
        self.label = label
        self.rawNormalized = rawNormalized
        self.canvasPoint = canvasPoint
        self.confidence = confidence
    }
}

public struct CardDebugInfo: Identifiable, Equatable {
    public let id: UUID
    public let rect: CGRect
    public let scale: CGFloat
    public let isGrabbed: Bool
    public let activeHandle: ResizeHandle?
    public let nearestHandle: ResizeHandle?
    public let distanceToHandle: CGFloat?
    public let handleHitRadius: CGFloat
    public let dragSafeRect: CGRect
    public let interactionModeDescription: String

    public init(id: UUID, rect: CGRect, scale: CGFloat, isGrabbed: Bool, activeHandle: ResizeHandle?, nearestHandle: ResizeHandle?, distanceToHandle: CGFloat?, handleHitRadius: CGFloat, dragSafeRect: CGRect, interactionModeDescription: String) {
        self.id = id
        self.rect = rect
        self.scale = scale
        self.isGrabbed = isGrabbed
        self.activeHandle = activeHandle
        self.nearestHandle = nearestHandle
        self.distanceToHandle = distanceToHandle
        self.handleHitRadius = handleHitRadius
        self.dragSafeRect = dragSafeRect
        self.interactionModeDescription = interactionModeDescription
    }
}

public struct GestureDebugInfo: Equatable {
    public let isGrabActive: Bool
    public let isPinchActive: Bool
    public let pinchBaseline: CGFloat?
    public let pinchCurrent: CGFloat?
    public let pinchDelta: CGFloat?

    public init(isGrabActive: Bool, isPinchActive: Bool, pinchBaseline: CGFloat?, pinchCurrent: CGFloat?, pinchDelta: CGFloat?) {
        self.isGrabActive = isGrabActive
        self.isPinchActive = isPinchActive
        self.pinchBaseline = pinchBaseline
        self.pinchCurrent = pinchCurrent
        self.pinchDelta = pinchDelta
    }
}

public struct OnboardingDebugInfo: Equatable {
    public let step: String
    public let baselineScale: CGFloat?
    public let currentScale: CGFloat
    public let targetScale: CGFloat?
    public let successFrames: Int
    public let conditionMet: Bool

    public init(step: String, baselineScale: CGFloat?, currentScale: CGFloat, targetScale: CGFloat?, successFrames: Int, conditionMet: Bool) {
        self.step = step
        self.baselineScale = baselineScale
        self.currentScale = currentScale
        self.targetScale = targetScale
        self.successFrames = successFrames
        self.conditionMet = conditionMet
    }
}

public enum ResizeHandle: String, Equatable, CaseIterable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    public var signs: CGPoint {
        switch self {
        case .topLeft:
            return CGPoint(x: -1, y: -1)
        case .topRight:
            return CGPoint(x: 1, y: -1)
        case .bottomLeft:
            return CGPoint(x: -1, y: 1)
        case .bottomRight:
            return CGPoint(x: 1, y: 1)
        }
    }
}
