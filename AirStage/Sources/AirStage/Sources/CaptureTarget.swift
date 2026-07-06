import Foundation

/// Represents a capturable window or screen target.
public struct CaptureTarget: Equatable, Identifiable {
    public let id: String
    public let title: String
    public let appName: String
    public let isOnScreen: Bool

    public init(id: String, title: String, appName: String, isOnScreen: Bool) {
        self.id = id
        self.title = title
        self.appName = appName
        self.isOnScreen = isOnScreen
    }

    /// Display label for picker UI: "AppName — WindowTitle".
    public var displayLabel: String {
        if appName.isEmpty { return title }
        return "\(appName) — \(title)"
    }
}
