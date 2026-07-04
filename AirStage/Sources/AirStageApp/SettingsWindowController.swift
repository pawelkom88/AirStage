import AppKit
import SwiftUI
import AirStage

/// Controls the Settings window. hosts SettingsView in NSHostingView.
final class SettingsWindowController: NSWindowController {
    private let settingsStore: SettingsStore

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 350),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "AirStage Settings"
        window.center()

        super.init(window: window)

        let hostingView = NSHostingView(rootView: SettingsView(store: settingsStore))
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 350)
        window.contentView = hostingView
    }

    required init?(coder: NSCoder) { nil }
}
