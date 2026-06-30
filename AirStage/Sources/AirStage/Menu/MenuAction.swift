import Foundation

/// A single entry in the AirStage menu bar menu.
public struct MenuAction: Equatable {
    public let id: MenuActionID
    public let title: String
    public let isEnabled: Bool
    /// Human-readable reason shown when the action is disabled. Nil when enabled.
    public let disabledReason: String?

    public init(id: MenuActionID, title: String, isEnabled: Bool = true, disabledReason: String? = nil) {
        self.id = id
        self.title = title
        self.isEnabled = isEnabled
        self.disabledReason = disabledReason
    }
}
