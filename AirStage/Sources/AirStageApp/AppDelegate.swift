import AppKit
import AirStage

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private let menuModel = MenuModel()
    private var previewWindowController: PreviewWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        LaunchDiagnostics.logStartup()
        AppLog.app.info("AppDelegate did finish launching")

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "camera.on.rectangle", accessibilityDescription: "AirStage")
        statusItem?.menu = buildNSMenu()

        menuModel.onIntent = { [weak self] intent in
            self?.handle(intent)
        }
    }

    private func handle(_ intent: MenuIntent) {
        switch intent {
        case .showPreview:
            showPreview()
        case .settings:
            AppLog.menu.info("Settings requested")
            // Settings window added in Slice 16.
        default:
            break
        }
    }

    private func showPreview() {
        if previewWindowController == nil {
            previewWindowController = PreviewWindowController(
                permissionService: AVCameraPermissionService()
            )
        }
        previewWindowController?.showWindow(nil)
        previewWindowController?.window?.makeKeyAndOrderFront(nil)
    }

    // MARK: - Menu construction

    private func buildNSMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        // Title row
        let titleItem = NSMenuItem(title: "AirStage", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(.separator())

        for action in menuModel.actions {
            switch action.id {
            case .removeLayer, .camera:
                let item = makeItem(action)
                let sub = NSMenu()
                item.submenu = sub
                menu.addItem(item)
            case .settings:
                menu.addItem(.separator())
                menu.addItem(makeItem(action))
            case .quit:
                menu.addItem(.separator())
                menu.addItem(makeItem(action))
            default:
                menu.addItem(makeItem(action))
            }
        }

        return menu
    }

    private func makeItem(_ action: MenuAction) -> NSMenuItem {
        let item = NSMenuItem(
            title: action.title,
            action: action.isEnabled ? #selector(handleMenuAction(_:)) : nil,
            keyEquivalent: ""
        )
        item.isEnabled = action.isEnabled
        item.representedObject = action.id.rawValue
        item.toolTip = action.disabledReason
        return item
    }

    @objc private func handleMenuAction(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let id = MenuActionID(rawValue: raw) else { return }

        AppLog.menu.info("Menu action selected action=\(raw, privacy: .public)")

        menuModel.select(id)
    }
}
