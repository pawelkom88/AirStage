import Foundation

/// Read-only snapshot of the current debug state for the overlay.
/// Kept in the library target so unit tests can verify it without importing SwiftUI.
public struct EdgeDeleteDebugInfo: Equatable {
    public let stateDescription: String
    public let side: String?
    public let layerID: UUID?
    public let deleteZoneWidth: CGFloat
    public let sceneBounds: CGRect

    public init(
        stateDescription: String,
        side: String?,
        layerID: UUID?,
        deleteZoneWidth: CGFloat,
        sceneBounds: CGRect
    ) {
        self.stateDescription = stateDescription
        self.side = side
        self.layerID = layerID
        self.deleteZoneWidth = deleteZoneWidth
        self.sceneBounds = sceneBounds
    }
}

public struct DebugOverlayState: Equatable {
    public let cameraStatus: String
    public let layerCount: Int
    public let selectedLayerTitle: String?
    public let handControlEnabled: Bool
    public let gestureState: String
    public let edgeDeleteInfo: EdgeDeleteDebugInfo?

    public init(
        cameraStatus: String,
        layerCount: Int,
        selectedLayerTitle: String?,
        handControlEnabled: Bool,
        gestureState: String,
        edgeDeleteInfo: EdgeDeleteDebugInfo?
    ) {
        self.cameraStatus = cameraStatus
        self.layerCount = layerCount
        self.selectedLayerTitle = selectedLayerTitle
        self.handControlEnabled = handControlEnabled
        self.gestureState = gestureState
        self.edgeDeleteInfo = edgeDeleteInfo
    }
}
