import Foundation
import Combine
import OSLog

public extension Notification.Name {
    static let resetOnboardingRequested = Notification.Name("resetOnboardingRequested")
}

public final class SettingsStore: ObservableObject {
    private let defaults: UserDefaults

    @Published public var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: "launchAtLogin")
            AppLog.settings.info("Setting changed launchAtLogin=\(self.launchAtLogin, privacy: .public)")
        }
    }

    @Published public var debugOverlay: Bool {
        didSet {
            defaults.set(debugOverlay, forKey: "debugOverlay")
            AppLog.settings.info("Setting changed debugOverlay=\(self.debugOverlay, privacy: .public)")
        }
    }

    @Published public var handControl: Bool {
        didSet {
            defaults.set(handControl, forKey: "handControl")
            AppLog.settings.info("Setting changed handControl=\(self.handControl, privacy: .public)")
        }
    }

    @Published public var snapToGrid: Bool {
        didSet {
            defaults.set(snapToGrid, forKey: "snapToGrid")
            AppLog.settings.info("Setting changed snapToGrid=\(self.snapToGrid, privacy: .public)")
        }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        self.debugOverlay = defaults.bool(forKey: "debugOverlay")
        self.handControl = defaults.bool(forKey: "handControl")
        self.snapToGrid = defaults.bool(forKey: "snapToGrid")
    }

    public func resetOnboarding() {
        defaults.set(false, forKey: "hasCompletedOnboarding")
        AppLog.settings.info("Onboarding reset requested from settings")
        NotificationCenter.default.post(name: .resetOnboardingRequested, object: nil)
    }
}
