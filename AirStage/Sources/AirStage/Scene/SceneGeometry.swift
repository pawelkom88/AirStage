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

    /// Rounds position to the nearest grid point.
    public static func snapToGrid(_ position: CGPoint, gridSize: CGFloat = SceneLimits.gridSize) -> CGPoint {
        return CGPoint(
            x: (position.x / gridSize).rounded() * gridSize,
            y: (position.y / gridSize).rounded() * gridSize
        )
    }

    /// Converts normalized Vision hand point (0.0 to 1.0) into canvas coordinates.
    /// Supports mirroring on the X axis.
    public static func convertHandPointToCanvas(
        _ point: CGPoint,
        canvasSize: CGSize,
        isMirrored: Bool
    ) -> CGPoint {
        let convertedX: CGFloat
        if isMirrored {
            convertedX = (1.0 - point.x) * canvasSize.width
        } else {
            convertedX = point.x * canvasSize.width
        }
        
        // Vision origin is bottom-left, canvas origin is top-left
        let convertedY = (1.0 - point.y) * canvasSize.height
        
        return CGPoint(x: convertedX, y: convertedY)
    }
}

public enum CameraContentMode {
    case fit
    case fill
}

public struct CanvasGeometry: Equatable {
    public var viewSize: CGSize
    public var sceneBounds: CGRect
    public var cameraImageRect: CGRect
    public var sourceAspectRatio: CGFloat
    public var isMirrored: Bool

    public init(
        viewSize: CGSize,
        sourceAspectRatio: CGFloat = 4.0 / 3.0,
        contentMode: CameraContentMode = .fill,
        isMirrored: Bool = false
    ) {
        self.viewSize = viewSize
        self.sceneBounds = CGRect(origin: .zero, size: viewSize)
        self.sourceAspectRatio = sourceAspectRatio
        self.isMirrored = isMirrored
        self.cameraImageRect = CanvasGeometry.imageRect(
            fittingAspectRatio: sourceAspectRatio,
            inside: CGRect(origin: .zero, size: viewSize),
            contentMode: contentMode
        )
    }

    public func convertHandPointToCanvas(_ point: CGPoint) -> CGPoint {
        let x = isMirrored ? (1.0 - point.x) : point.x
        let y = 1.0 - point.y

        return CGPoint(
            x: cameraImageRect.minX + x * cameraImageRect.width,
            y: cameraImageRect.minY + y * cameraImageRect.height
        )
    }

    public static func imageRect(
        fittingAspectRatio aspect: CGFloat,
        inside bounds: CGRect,
        contentMode: CameraContentMode
    ) -> CGRect {
        guard bounds.width > 0, bounds.height > 0 else { return .zero }

        let boundsAspect = bounds.width / bounds.height
        let size: CGSize

        switch contentMode {
        case .fit:
            if boundsAspect > aspect {
                size = CGSize(width: bounds.height * aspect, height: bounds.height)
            } else {
                size = CGSize(width: bounds.width, height: bounds.width / aspect)
            }

        case .fill:
            if boundsAspect > aspect {
                size = CGSize(width: bounds.width, height: bounds.width / aspect)
            } else {
                size = CGSize(width: bounds.height * aspect, height: bounds.height)
            }
        }

        return CGRect(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }
}
