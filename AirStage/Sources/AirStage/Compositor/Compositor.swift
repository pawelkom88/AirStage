import Foundation
import CoreGraphics
import OSLog

/// A single layer entry in a composed frame, containing the metadata
/// needed to render or describe it in the output pipeline.
public struct CompositorLayerEntry: Equatable {
    public let layerID: UUID
    public let kind: SceneLayer.Kind
    public let title: String
    public let position: CGPoint
    public let size: CGSize
    public let scale: CGFloat
    public let rotationDegrees: CGFloat
    public let zIndex: Int
    public let imageURL: URL?

    public init(from layer: SceneLayer) {
        self.layerID = layer.id
        self.kind = layer.kind
        self.title = layer.title
        self.position = layer.position
        self.size = layer.size
        self.scale = layer.scale
        self.rotationDegrees = layer.rotationDegrees
        self.zIndex = layer.zIndex
        self.imageURL = layer.imageURL
    }
}

/// A composed frame snapshot — the full description of what the virtual
/// camera output should contain for one frame.
public struct CompositorFrame: Equatable {
    /// Identifier of the camera frame used as background.
    public let cameraFrameID: String
    /// Target output resolution.
    public let outputSize: CGSize
    /// Overlay layer entries sorted by zIndex (lowest first = drawn first).
    public let layerEntries: [CompositorLayerEntry]
    /// ISO-8601 timestamp of when the snapshot was taken.
    public let timestamp: String
}

/// Produces composed frame metadata from the current scene state.
/// This is a metadata/test compositor — real CoreImage/Metal rendering
/// will be added when the virtual camera extension needs pixel output.
public final class Compositor {
    private let sceneStore: SceneStore
    public let outputSize: CGSize

    public init(sceneStore: SceneStore, outputSize: CGSize) {
        self.sceneStore = sceneStore
        self.outputSize = outputSize
    }

    /// Takes a snapshot of the current scene, producing a CompositorFrame
    /// that describes the camera background plus all overlay layers
    /// sorted by zIndex.
    public func snapshot(cameraFrameID: String) -> CompositorFrame {
        let visibleLayers = sceneStore.layers
            .filter { !$0.isBeingRemoved }
            .sorted { $0.zIndex < $1.zIndex }

        let entries = visibleLayers.map { CompositorLayerEntry(from: $0) }

        let timestamp = ISO8601DateFormatter().string(from: Date())

        AppLog.app.debug("Compositor snapshot camera=\(cameraFrameID, privacy: .public) layers=\(entries.count) output=\(Int(self.outputSize.width))x\(Int(self.outputSize.height))")

        return CompositorFrame(
            cameraFrameID: cameraFrameID,
            outputSize: outputSize,
            layerEntries: entries,
            timestamp: timestamp
        )
    }
}
