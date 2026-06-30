import Foundation
import CoreGraphics

struct SceneLayer: Identifiable, Equatable {
    enum Kind: String, Equatable {
        case note
        case image
        case windowCapture
        case tutorial
    }

    let id: UUID
    var kind: Kind
    var title: String
    var position: CGPoint
    var size: CGSize
    var scale: CGFloat
    var rotationDegrees: CGFloat
    var zIndex: Int
    var isSelected: Bool
    var isBeingRemoved: Bool
}

struct SceneLimits {
    static let maxTotalLayers = 6
    static let maxWindowLayers = 1
    static let maxImageLayers = 3
    static let maxNoteLayers = 4
    static let removalMargin: CGFloat = 60
    static let tutorialMoveCompletionDistance: CGFloat = 64
    static let tutorialZoomCompletionScale: CGFloat = 1.5
    static let tutorialVanishScale: CGFloat = 0.3
}

func shouldRemoveLayer(center: CGPoint, sceneBounds: CGRect, margin: CGFloat = SceneLimits.removalMargin) -> Bool {
    let expandedBounds = sceneBounds.insetBy(dx: -margin, dy: -margin)
    return !expandedBounds.contains(center)
}

func didCompleteTutorialMove(distance: CGFloat) -> Bool {
    distance >= SceneLimits.tutorialMoveCompletionDistance
}

func didCompleteTutorialZoom(scale: CGFloat) -> Bool {
    scale >= SceneLimits.tutorialZoomCompletionScale
}

func shouldStartTutorialVanishHold(scale: CGFloat) -> Bool {
    scale <= SceneLimits.tutorialVanishScale
}
