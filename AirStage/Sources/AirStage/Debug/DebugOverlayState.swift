import Foundation

/// Read-only snapshot of the current debug state for the overlay.
/// Kept in the library target so unit tests can verify it without importing SwiftUI.
public struct EdgeDeleteDebugInfo: Equatable {
    public let stateDescription: String
    public let dwellProgress: Double
    public let commitProgress: Double

    public init(
        stateDescription: String,
        dwellProgress: Double,
        commitProgress: Double
    ) {
        self.stateDescription = stateDescription
        self.dwellProgress = dwellProgress
        self.commitProgress = commitProgress
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
