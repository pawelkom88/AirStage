import Foundation

/// Intents emitted by the menu model to the app shell.
public enum MenuIntent: Equatable {
    case presenterShelf
    case showPreview
    case settings
    case addNote
    case shareImage
    case shareWindowOrScreen
    case removeLayer(id: UUID)
    case quit
}
