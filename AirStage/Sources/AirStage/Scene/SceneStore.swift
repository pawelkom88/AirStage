import Foundation
import CoreGraphics
import OSLog

public enum AddResult: Equatable {
    case success(UUID)
    case failure(FailureReason)

    public enum FailureReason: Equatable {
        case sceneFull(totalCount: Int)
        case kindLimitExceeded(kind: SceneLayer.Kind)
    }

    public var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }

    public var layerID: UUID? {
        switch self {
        case .success(let id): return id
        case .failure: return nil
        }
    }
}

public final class SceneStore: ObservableObject {
    @Published public private(set) var layers: [SceneLayer] = []

    public init() {}

    public func layer(withID id: UUID) -> SceneLayer? {
        return layers.first(where: { $0.id == id })
    }

    public func addNote(
        title: String,
        position: CGPoint = .zero,
        size: CGSize = .zero,
        replaceOldestIfFull: Bool = false
    ) -> AddResult {
        return addLayer(kind: .note, title: title, position: position, size: size, replaceOldestIfFull: replaceOldestIfFull)
    }

    public func addImage(
        title: String,
        imageURL: URL? = nil,
        position: CGPoint = .zero,
        size: CGSize = .zero,
        replaceOldestIfFull: Bool = false
    ) -> AddResult {
        return addLayer(kind: .image, title: title, imageURL: imageURL, position: position, size: size, replaceOldestIfFull: replaceOldestIfFull)
    }

    public func addWindowCapture(
        title: String,
        position: CGPoint = .zero,
        size: CGSize = .zero,
        replaceOldestIfFull: Bool = false
    ) -> AddResult {
        return addLayer(kind: .windowCapture, title: title, position: position, size: size, replaceOldestIfFull: replaceOldestIfFull)
    }

    public func addTutorialCard(
        title: String,
        position: CGPoint = .zero,
        size: CGSize = .zero,
        replaceOldestIfFull: Bool = false
    ) -> AddResult {
        return addLayer(kind: .tutorial, title: title, position: position, size: size, replaceOldestIfFull: replaceOldestIfFull)
    }

    public func addLayer(
        kind: SceneLayer.Kind,
        title: String,
        imageURL: URL? = nil,
        position: CGPoint = .zero,
        size: CGSize = .zero,
        replaceOldestIfFull: Bool = false
    ) -> AddResult {
        let currentTotalCount = layers.count
        let currentKindCount = layers.filter { $0.kind == kind }.count

        var maxKindCount = 0
        switch kind {
        case .note:
            maxKindCount = SceneLimits.maxNoteLayers
        case .image:
            maxKindCount = SceneLimits.maxImageLayers
        case .windowCapture:
            maxKindCount = SceneLimits.maxWindowLayers
        case .tutorial:
            // Tutorial cards are subject to total limits, but let's give them a high limit or just use total limit
            maxKindCount = SceneLimits.maxTotalLayers
        }

        let isTotalFull = currentTotalCount >= SceneLimits.maxTotalLayers
        let isKindFull = currentKindCount >= maxKindCount

        if isTotalFull || isKindFull {
            if replaceOldestIfFull {
                // Find oldest (lowest zIndex) to remove
                let targetLayers = isKindFull ? layers.filter { $0.kind == kind } : layers
                if let oldest = targetLayers.min(by: { $0.zIndex < $1.zIndex }) {
                    removeLayer(withID: oldest.id, reason: "replacedOldest")
                } else {
                    AppLog.scene.notice("Scene full kind=\(kind.rawValue, privacy: .public) total=\(currentTotalCount)")
                    return .failure(isTotalFull ? .sceneFull(totalCount: currentTotalCount) : .kindLimitExceeded(kind: kind))
                }
            } else {
                AppLog.scene.notice("Scene full kind=\(kind.rawValue, privacy: .public) total=\(currentTotalCount)")
                return .failure(isTotalFull ? .sceneFull(totalCount: currentTotalCount) : .kindLimitExceeded(kind: kind))
            }
        }

        let nextZIndex = (layers.map { $0.zIndex }.max() ?? 0) + 1
        let newLayer = SceneLayer(
            kind: kind,
            title: title,
            position: position,
            size: size,
            zIndex: nextZIndex,
            imageURL: imageURL
        )

        layers.append(newLayer)
        AppLog.scene.info("Layer added id=\(newLayer.id.uuidString, privacy: .public) kind=\(newLayer.kind.rawValue, privacy: .public) title=\(newLayer.title, privacy: .public)")
        return .success(newLayer.id)
    }

    public func selectLayer(_ id: UUID) {
        for index in 0..<layers.count {
            layers[index].isSelected = (layers[index].id == id)
        }

        if let index = layers.firstIndex(where: { $0.id == id }) {
            let nextZIndex = (layers.map { $0.zIndex }.max() ?? 0) + 1
            layers[index].zIndex = nextZIndex
            AppLog.scene.info("Layer selected id=\(id.uuidString, privacy: .public)")
        }
    }

    public func removeLayer(withID id: UUID, reason: String = "manual") {
        if layers.contains(where: { $0.id == id }) {
            layers.removeAll(where: { $0.id == id })
            AppLog.scene.info("Layer removed id=\(id.uuidString, privacy: .public) reason=\(reason, privacy: .public)")
        }
    }

    public func updateNoteText(layerID id: UUID, text: String) {
        if let index = layers.firstIndex(where: { $0.id == id }) {
            layers[index].title = text
            let truncatedText = text.count > 20 ? String(text.prefix(20)) + "..." : text
            AppLog.scene.info("Layer text updated id=\(id.uuidString, privacy: .public) title=\(truncatedText, privacy: .public)")
        }
    }

    public func endDrag(layerID id: UUID, center: CGPoint, sceneBounds: CGRect) {
        if shouldRemoveLayer(center: center, sceneBounds: sceneBounds) {
            removeLayer(withID: id, reason: "draggedOutside")
        } else {
            if let index = layers.firstIndex(where: { $0.id == id }) {
                let clamped = SceneGeometry.clampPosition(center, size: layers[index].size, in: sceneBounds)
                layers[index].position = clamped
                layers[index].isBeingRemoved = false
                AppLog.scene.debug("Layer moved id=\(id.uuidString, privacy: .public) x=\(clamped.x) y=\(clamped.y)")
            }
        }
    }

    public func deleteSelectedLayer() {
        if let selected = layers.first(where: { $0.isSelected }) {
            removeLayer(withID: selected.id, reason: "deleteKey")
        }
    }

    public func dragLayer(withID id: UUID, to position: CGPoint, sceneBounds: CGRect) {
        if let index = layers.firstIndex(where: { $0.id == id }) {
            let wasArmed = layers[index].isBeingRemoved
            let isArmed = shouldRemoveLayer(center: position, sceneBounds: sceneBounds)
            
            layers[index].isBeingRemoved = isArmed
            layers[index].position = position
            
            if isArmed && !wasArmed {
                AppLog.scene.info("Layer removal armed id=\(id.uuidString, privacy: .public) reason=draggedOutside")
            } else if !isArmed && wasArmed {
                AppLog.scene.info("Layer removal cancelled id=\(id.uuidString, privacy: .public)")
            }
            
            AppLog.scene.debug("Layer dragging id=\(id.uuidString, privacy: .public) x=\(position.x) y=\(position.y)")
        }
    }

    public func beginResize(withID id: UUID) {
        AppLog.scene.info("Layer resize began id=\(id.uuidString, privacy: .public)")
    }

    public func endResize(withID id: UUID, finalSize: CGSize) {
        let w = Int(finalSize.width)
        let h = Int(finalSize.height)
        AppLog.scene.info("Layer resize ended id=\(id.uuidString, privacy: .public) size=\(w)x\(h)")
    }

    public func resizeLayer(withID id: UUID, size: CGSize, position: CGPoint, sceneBounds: CGRect) {
        if let index = layers.firstIndex(where: { $0.id == id }) {
            var minSize = SceneLimits.minNoteSize
            switch layers[index].kind {
            case .note:
                minSize = SceneLimits.minNoteSize
            case .image:
                minSize = SceneLimits.minImageSize
            case .windowCapture:
                minSize = SceneLimits.minWindowSize
            case .tutorial:
                minSize = SceneLimits.minTutorialSize
            }

            let clampedW = max(minSize.width, size.width)
            let clampedH = max(minSize.height, size.height)
            let clampedSize = CGSize(width: clampedW, height: clampedH)

            let clampedPos = SceneGeometry.clampPosition(position, size: clampedSize, in: sceneBounds)

            layers[index].size = clampedSize
            layers[index].position = clampedPos

            let w = Int(clampedSize.width)
            let h = Int(clampedSize.height)
            AppLog.scene.debug("Layer resized id=\(id.uuidString, privacy: .public) width=\(w) height=\(h)")
        }
    }

    public func clearAllLayers() {
        layers.removeAll()
        AppLog.scene.info("All layers cleared reason=quickAddClear")
    }
}
