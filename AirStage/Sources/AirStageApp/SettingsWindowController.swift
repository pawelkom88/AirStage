import AppKit
import SwiftUI
import AirStage

/// Controls the Settings window. hosts SettingsView in NSHostingView.
final class SettingsWindowController: NSWindowController {
    private let settingsStore: SettingsStore
    private let cameraManager: VirtualCameraManager

    init(settingsStore: SettingsStore, cameraManager: VirtualCameraManager) {
        self.settingsStore = settingsStore
        self.cameraManager = cameraManager
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "AirStage Settings"
        window.center()

        super.init(window: window)

        let hostingView = NSHostingView(rootView: SettingsView(store: settingsStore, cameraManager: cameraManager))
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 380)
        window.contentView = hostingView
    }

    required init?(coder: NSCoder) { nil }
}
