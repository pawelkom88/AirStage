import CoreGraphics
import OSLog

/// Bridges gesture events from the GestureEngine to the SceneStore,
/// selecting and moving layers via pinch-to-grab.
public struct GestureLayerController {
    private let sceneStore: SceneStore
    private var sceneBounds: CGRect
    private var grabbedLayerID: UUID?
    
    public mutating func updateSceneBounds(_ bounds: CGRect) {
        sceneBounds = bounds
    }
    
    public private(set) var isResizing: Bool = false
    private var activeResizeHandle: ResizeHandle?
    private var startSize: CGSize = .zero
    private var startPinchPoint: CGPoint = .zero
    private var startPosition: CGPoint = .zero
    
    public var onOnboardingEvent: ((CGFloat, CGFloat) -> Void)?

    public mutating func cancelActiveGesture() {
        grabbedLayerID = nil
        isResizing = false
        activeResizeHandle = nil
        startSize = .zero
        startPinchPoint = .zero
        startPosition = .zero
    }

    public init(sceneStore: SceneStore, sceneBounds: CGRect) {
        self.sceneStore = sceneStore
        self.sceneBounds = sceneBounds
    }

    /// Processes a gesture event when hand control is enabled.
    /// When hand control is disabled, all events are silently ignored.
    public mutating func handle(_ event: GestureEvent, handControlEnabled: Bool) {
        guard handControlEnabled else { return }

        switch event {
        case .pinchBegan(let point):
            if let topLayer = topLayer(at: point) {
                sceneStore.selectLayer(topLayer.id)
                grabbedLayerID = topLayer.id
                
                let rect = CGRect(
                    x: topLayer.position.x - topLayer.size.width / 2,
                    y: topLayer.position.y - topLayer.size.height / 2,
                    width: topLayer.size.width,
                    height: topLayer.size.height
                )
                
                switch LayerInteractionResolver.interactionMode(for: point, in: rect) {
                case .resize(let handle):
                    isResizing = true
                    activeResizeHandle = handle
                    startSize = topLayer.size
                    startPinchPoint = point
                    startPosition = topLayer.position
                    sceneStore.beginResize(withID: topLayer.id)
                    AppLog.gestures.info("Pinch resize began layer=\(topLayer.id.uuidString, privacy: .public) handle=\(handle.rawValue, privacy: .public)")
                case .drag:
                    isResizing = false
                    activeResizeHandle = nil
                    startSize = topLayer.size
                    startPinchPoint = point
                    startPosition = topLayer.position
                    AppLog.gestures.info("Pinch grab began layer=\(topLayer.id.uuidString, privacy: .public) x=\(point.x) y=\(point.y)")
                case .none:
                    grabbedLayerID = nil
                    isResizing = false
                    activeResizeHandle = nil
                }
            }

        case .pinchMoved(let point):
            guard let id = grabbedLayerID, let layer = sceneStore.layer(withID: id) else { return }
            
            if isResizing, let handle = activeResizeHandle {
                if layer.kind == .tutorial {
                    let signs = handle.signs
                    let translation = CGSize(
                        width: point.x - startPinchPoint.x,
                        height: point.y - startPinchPoint.y
                    )

                    let projectedDelta = ((translation.width * signs.x) + (translation.height * signs.y)) / 2.0
                    let startSide = max(startSize.width, startSize.height)
                    let side = max(SceneLimits.minTutorialSize.width, startSide + projectedDelta)
                    let appliedDelta = side - startSide

                    let newPosition = CGPoint(
                        x: startPosition.x + (appliedDelta * signs.x / 2.0),
                        y: startPosition.y + (appliedDelta * signs.y / 2.0)
                    )

                    sceneStore.resizeLayer(
                        withID: id,
                        size: CGSize(width: side, height: side),
                        position: newPosition,
                        sceneBounds: sceneBounds
                    )

                    onOnboardingEvent?(0, side / 150.0)
                } else {
                    let deltaW = point.x - startPinchPoint.x
                    let deltaH = point.y - startPinchPoint.y
                    
                    // Simple freeform logic using active handle direction
                    let signs = handle.signs
                    let newW = startSize.width + (deltaW * signs.x)
                    let newH = startSize.height + (deltaH * signs.y)
                    
                    let newPos = CGPoint(
                        x: startPosition.x + deltaW / 2,
                        y: startPosition.y + deltaH / 2
                    )
                    sceneStore.resizeLayer(withID: id, size: CGSize(width: max(10, newW), height: max(10, newH)), position: newPos, sceneBounds: sceneBounds)
                    AppLog.gestures.debug("Pinch resize moved layer=\(id.uuidString, privacy: .public)")
                }
            } else {
                sceneStore.dragLayer(withID: id, to: point, sceneBounds: sceneBounds)
                AppLog.gestures.debug("Pinch grab moved layer=\(id.uuidString, privacy: .public) x=\(point.x) y=\(point.y)")
                
                if layer.kind == .tutorial {
                    let dist = hypot(point.x - 320, point.y - 240)
                    onOnboardingEvent?(dist, 0)
                }
            }

        case .pinchEnded:
            if let id = grabbedLayerID, let layer = sceneStore.layer(withID: id) {
                if isResizing {
                    sceneStore.endResize(withID: id, finalSize: layer.size)
                    AppLog.gestures.info("Pinch resize released layer=\(id.uuidString, privacy: .public)")
                    if layer.kind == .tutorial {
                        let scale = layer.size.width / 150.0
                        onOnboardingEvent?(0, scale)
                    }
                } else {
                    sceneStore.endDrag(layerID: id, center: layer.position, sceneBounds: sceneBounds)
                    AppLog.gestures.info("Pinch grab released layer=\(id.uuidString, privacy: .public)")
                    if layer.kind == .tutorial {
                        let dist = hypot(layer.position.x - 320, layer.position.y - 240)
                        onOnboardingEvent?(dist, 0)
                    }
                }
            }
            grabbedLayerID = nil
            isResizing = false
            activeResizeHandle = nil

        case .none:
            break
        }
    }

    /// Returns the topmost layer (by zIndex) whose bounding rect contains the given point.
    private func topLayer(at point: CGPoint) -> SceneLayer? {
        sceneStore.layers
            .filter { layerContains($0, point: point) }
            .sorted { $0.zIndex > $1.zIndex }
            .first
    }

    /// Hit-tests whether a layer's bounding rect contains the given point.
    private func layerContains(_ layer: SceneLayer, point: CGPoint) -> Bool {
        let halfW = layer.size.width / 2
        let halfH = layer.size.height / 2
        let rect = CGRect(
            x: layer.position.x - halfW,
            y: layer.position.y - halfH,
            width: layer.size.width,
            height: layer.size.height
        )
        return rect.contains(point)
    }

    /// The currently grabbed layer ID, if any. Exposed for debug overlay.
    public var currentGrabbedLayerID: UUID? {
        grabbedLayerID
    }

    public var currentActiveResizeHandle: ResizeHandle? {
        activeResizeHandle
    }
}
