import Foundation

/// Testable model for the AirStage menu bar menu.
/// Kept separate from AppKit so it can be unit-tested without a running NSApplication.
public final class MenuModel {
    private let sceneStore: SceneStore?
    private let isOnboardingCompleted: () -> Bool

    /// All primary menu actions in display order.
    public var actions: [MenuAction] {
        let completed = isOnboardingCompleted()
        let hasLayers = !(sceneStore?.layers.isEmpty ?? true)

        if !completed {
            return [
                MenuAction(id: .quit, title: "Quit AirStage")
            ]
        }

        return [
            MenuAction(id: .presenterShelf,     title: "Presenter Shelf"),
            MenuAction(id: .addNote,            title: "Add Note"),
            MenuAction(id: .shareImage,         title: "Share Image…"),
            MenuAction(id: .shareWindowOrScreen,
                       title: "Share Window or Screen…"),
            MenuAction(id: .removeLayer,        title: "Remove Layer",
                       isEnabled: hasLayers,
                       disabledReason: hasLayers ? nil : "No layers in scene."),
            MenuAction(id: .showPreview,        title: "Show Preview"),
            MenuAction(id: .camera,             title: "Camera",        isEnabled: false,
                       disabledReason: "Camera selection available after preview is open."),
            MenuAction(id: .settings,           title: "Settings…",
                       isEnabled: false,
                       disabledReason: "Settings are available in a later release."),
            MenuAction(id: .quit,               title: "Quit AirStage"),
        ]
    }

    /// Called whenever the user selects an action.
    public var onIntent: ((MenuIntent) -> Void)?

    public init(
        sceneStore: SceneStore? = nil,
        isOnboardingCompleted: @escaping () -> Bool = { true }
    ) {
        self.sceneStore = sceneStore
        self.isOnboardingCompleted = isOnboardingCompleted
    }

    public var removableLayers: [SceneLayer] {
        return sceneStore?.layers ?? []
    }

    public func removeLayer(withID id: UUID) {
        AppLog.menu.info("Menu action selected action=removeLayer id=\(id.uuidString, privacy: .public)")
        sceneStore?.removeLayer(withID: id, reason: "menu")
    }

    /// Selects an action by ID and emits the corresponding intent.
    /// Does nothing if the action is disabled.
    public func select(_ id: MenuActionID) {
        guard let action = actions.first(where: { $0.id == id }), action.isEnabled else {
            AppLog.menu.info("Menu action ignored action=\(id.rawValue, privacy: .public) reason=disabled")
            return
        }

        let intent: MenuIntent
        switch id {
        case .presenterShelf:       intent = .presenterShelf
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
