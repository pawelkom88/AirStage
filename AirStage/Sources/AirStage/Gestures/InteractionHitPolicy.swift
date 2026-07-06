import Foundation
import CoreGraphics

public enum InteractionHitPolicy {
    /// Resize handle hit radius.
    ///
    /// Important:
    /// - Uses the smaller side of the rect, not width-only scale.
    /// - Has a lower bound so tiny cards still have usable handles.
    /// - Has an upper bound so wide/large cards do not create huge resize zones.
    public static func resizeHandleRadius(for rect: CGRect) -> CGFloat {
        let minSide = max(0, min(rect.width, rect.height))
        let proportional = minSide * 0.24
        return min(max(proportional, 14), 42)
    }

    /// The area where drag should clearly win over resize.
    ///
    /// If this rect contains the point, the interaction should be drag.
    public static func dragSafeRect(for rect: CGRect) -> CGRect {
        let radius = resizeHandleRadius(for: rect)
        let insetX = min(radius, rect.width / 2)
        let insetY = min(radius, rect.height / 2)
        return rect.insetBy(dx: insetX, dy: insetY)
    }

    /// Whether the layer is large enough to have a meaningful drag body.
    public static func hasUsableDragBody(_ rect: CGRect) -> Bool {
        let safe = dragSafeRect(for: rect)
        return safe.width >= 12 && safe.height >= 12
    }
}
