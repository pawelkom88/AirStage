import Foundation
import CoreGraphics

public struct SceneLimits {
    public static let maxTotalLayers = 6
    public static let maxWindowLayers = 1
    public static let maxImageLayers = 3
    public static let maxNoteLayers = 4
    public static let removalMargin: CGFloat = 60
    public static let tutorialMoveCompletionDistance: CGFloat = 64
    public static let tutorialZoomCompletionScale: CGFloat = 1.5
    public static let tutorialVanishScale: CGFloat = 0.3

    public static let minNoteSize = CGSize(width: 80, height: 80)
    public static let minImageSize = CGSize(width: 80, height: 80)
    public static let minWindowSize = CGSize(width: 100, height: 100)
    public static let minTutorialSize = CGSize(width: 40, height: 40)

    /// Grid spacing in points for snap-to-grid.
    public static let gridSize: CGFloat = 20
}

public func shouldRemoveLayer(center: CGPoint, sceneBounds: CGRect, margin: CGFloat = SceneLimits.removalMargin) -> Bool {
    let expandedBounds = sceneBounds.insetBy(dx: -margin, dy: -margin)
    return !expandedBounds.contains(center)
}

public func didCompleteTutorialMove(distance: CGFloat) -> Bool {
    distance >= SceneLimits.tutorialMoveCompletionDistance
}

public func didCompleteTutorialZoom(scale: CGFloat) -> Bool {
    scale >= SceneLimits.tutorialZoomCompletionScale
}

public func shouldStartTutorialVanishHold(scale: CGFloat) -> Bool {
    scale <= SceneLimits.tutorialVanishScale
}
