import Foundation
import CoreGraphics

public enum LayerInteractionMode: Equatable {
    case none
    case drag
    case resize(ResizeHandle)
}

public struct ResizeHandleHit: Equatable {
    public let handle: ResizeHandle
    public let center: CGPoint
    public let distance: CGFloat

    public init(handle: ResizeHandle, center: CGPoint, distance: CGFloat) {
        self.handle = handle
        self.center = center
        self.distance = distance
    }
}

public enum LayerInteractionResolver {
    public static func interactionMode(
        for point: CGPoint,
        in rect: CGRect
    ) -> LayerInteractionMode {
        guard rect.contains(point) || isNearRect(point, rect: rect) else {
            return .none
        }

        let radius = InteractionHitPolicy.resizeHandleRadius(for: rect)
        let dragSafeRect = InteractionHitPolicy.dragSafeRect(for: rect)

        // Small card protection: Ensure there is always a central drag zone if card is small
        if rect.width < 80 || rect.height < 80 {
            let centerBody = rect.insetBy(dx: rect.width * 0.32, dy: rect.height * 0.32)
            if centerBody.contains(point) {
                return .drag
            }
        }

        // Inside the body, drag must win.
        if dragSafeRect.contains(point) {
            return .drag
        }

        if let hit = nearestHandle(to: point, in: rect, radius: radius) {
            return .resize(hit.handle)
        }

        // If the point is inside the layer but not inside a corner zone,
        // this is still a drag.
        if rect.contains(point) {
            return .drag
        }

        return .none
    }

    public static func nearestHandle(
        to point: CGPoint,
        in rect: CGRect,
        radius: CGFloat
    ) -> ResizeHandleHit? {
        let handles: [(ResizeHandle, CGPoint)] = [
            (.topLeft, CGPoint(x: rect.minX, y: rect.minY)),
            (.topRight, CGPoint(x: rect.maxX, y: rect.minY)),
            (.bottomLeft, CGPoint(x: rect.minX, y: rect.maxY)),
            (.bottomRight, CGPoint(x: rect.maxX, y: rect.maxY))
        ]

        return handles
            .map { handle, center in
                ResizeHandleHit(
                    handle: handle,
                    center: center,
                    distance: hypot(point.x - center.x, point.y - center.y)
                )
            }
            .filter { $0.distance <= radius }
            .min { $0.distance < $1.distance }
    }

    private static func isNearRect(
        _ point: CGPoint,
        rect: CGRect
    ) -> Bool {
        let radius = InteractionHitPolicy.resizeHandleRadius(for: rect)
        let expanded = rect.insetBy(dx: -radius, dy: -radius)
        return expanded.contains(point)
    }
}
