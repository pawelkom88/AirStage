import Foundation
import CoreGraphics

public enum SceneGeometry {
    /// Clamps the position of a layer to ensure it remains at least partially visible within the bounds.
    /// Specifically, it keeps at least 20pt of the layer's edges inside the scene bounds.
    public static func clampPosition(_ position: CGPoint, size: CGSize, in bounds: CGRect) -> CGPoint {
        let minX = bounds.minX - size.width / 2 + 20
        let maxX = bounds.maxX + size.width / 2 - 20
        let minY = bounds.minY - size.height / 2 + 20
        let maxY = bounds.maxY + size.height / 2 - 20
        
        return CGPoint(
            x: Swift.max(minX, Swift.min(position.x, maxX)),
            y: Swift.max(minY, Swift.min(position.y, maxY))
        )
    }
}
