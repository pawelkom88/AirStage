import Foundation

/// Testable model for the AirStage menu bar menu.
/// Kept separate from AppKit so it can be unit-tested without a running NSApplication.
public final class MenuModel {

    /// All primary menu actions in display order.
    public let actions: [MenuAction]

    /// Called whenever the user selects an action.
    public var onIntent: ((MenuIntent) -> Void)?

    public init() {
        actions = [
            MenuAction(id: .addNote,            title: "Add Note"),
            MenuAction(id: .shareImage,         title: "Share Image…"),
            MenuAction(id: .shareWindowOrScreen,
                       title: "Share Window or Screen…",
                       isEnabled: false,
                       disabledReason: "Window capture is available in a later release."),
            MenuAction(id: .removeLayer,        title: "Remove Layer",  isEnabled: false,
                       disabledReason: "No layers in scene."),
            MenuAction(id: .showPreview,        title: "Show Preview"),
            MenuAction(id: .camera,             title: "Camera",        isEnabled: false,
                       disabledReason: "Camera selection available after preview is open."),
            MenuAction(id: .settings,           title: "Settings…"),
            MenuAction(id: .quit,               title: "Quit AirStage"),
        ]
    }

    /// Selects an action by ID and emits the corresponding intent.
    public func select(_ id: MenuActionID) {
        let intent: MenuIntent
        switch id {
        case .showPreview:          intent = .showPreview
        case .settings:             intent = .settings
        case .addNote:              intent = .addNote
        case .shareImage:           intent = .shareImage
        case .shareWindowOrScreen:  intent = .shareWindowOrScreen
        case .removeLayer:          return  // submenu; handled separately
        case .camera:               return  // submenu; handled separately
        case .quit:                 intent = .quit
        }
        AppLog.menu.info("Menu action selected action=\(id.rawValue, privacy: .public)")
        onIntent?(intent)
    }
}
