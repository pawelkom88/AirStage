import AppKit
import AirStage

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private let sceneStore = SceneStore()
    private lazy var menuModel = MenuModel(
        sceneStore: sceneStore,
        isOnboardingCompleted: {
            UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        }
    )
    private var previewWindowController: PreviewWindowController?
    private let settingsStore = SettingsStore()
    private var settingsWindowController: SettingsWindowController?
    private let virtualCameraManager = VirtualCameraManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        LaunchDiagnostics.logStartup()
        AppLog.app.info("AppDelegate did finish launching")

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "camera.on.rectangle", accessibilityDescription: "AirStage")
        statusItem?.menu = buildNSMenu()

        menuModel.onIntent = { [weak self] intent in
            self?.handle(intent)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onboardingStatusChanged),
            name: .onboardingCompleted,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onboardingStatusChanged),
            name: .resetOnboardingRequested,
            object: nil
        )

        // Auto-open the preview window at launch so the camera scene is
        // immediately visible. The menu is locked during onboarding, so
        // this call is made directly rather than via the menu model.
        showPreview()
        AppLog.app.info("Preview window opened automatically at launch")
    }

    @objc private func onboardingStatusChanged() {
        if let menu = statusItem?.menu {
            rebuildMenu(menu)
        }
    }

    private func handle(_ intent: MenuIntent) {
        switch intent {
        case .showPreview:
            showPreview()
        case .addNote:
            _ = sceneStore.addNote(
                title: "Sticky Note",
                position: CGPoint(x: 320, y: 240),
                size: CGSize(width: 150, height: 150)
            )
            showPreview()
        case .shareImage:
            presentImagePicker()
        case .shareWindowOrScreen:
            presentWindowCapturePicker()
        case .settings:
            AppLog.menu.info("Settings requested")
            showSettings()
        case .quit:
            AppLog.app.info("Quit requested")
            NSApplication.shared.terminate(nil)
        default:
            break
        }
    }

    private func presentImagePicker() {
        let picker = NSOpenPanelImageSourcePicker()
        picker.pickImage { [weak self] url in
            guard let self = self, let url = url else { return }
            let importer = ImageImporter(store: self.sceneStore)
            let result = importer.importImage(from: url)
            switch result {
            case .success:
                self.showPreview()
            case .failure(let error):
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Cannot Add Image"
                    alert.informativeText = error.errorDescription ?? "An unknown error occurred."
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            }
        }
    }

    private func showPreview() {
        if previewWindowController == nil {
            previewWindowController = PreviewWindowController(
                permissionService: AVCameraPermissionService(),
                sceneStore: sceneStore,
                settingsStore: settingsStore,
                virtualCameraManager: virtualCameraManager
            )
            previewWindowController?.onAddImage = { [weak self] in
                self?.presentImagePicker()
            }
        }
        previewWindowController?.showWindow(nil)
        previewWindowController?.window?.makeKeyAndOrderFront(nil)
    }

    private func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(
                settingsStore: settingsStore,
                cameraManager: virtualCameraManager
            )
        }
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
    }

    private func presentWindowCapturePicker() {
        AppLog.sources.info("Window capture picker requested")
        let importer = WindowCaptureImporter(store: sceneStore)
        let result = importer.importCapture(
            title: "Screen Capture",
            captureID: "placeholder"
        )
        switch result {
        case .success:
            showPreview()
        case .failure(let error):
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Cannot Add Window Capture"
                alert.informativeText = error.errorDescription ?? "An unknown error occurred."
                alert.alertStyle = .warning
                alert.runModal()
            }
        }
    }

    // MARK: - Menu construction

    private func buildNSMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        
        rebuildMenu(menu)
        
        return menu
    }

    private func rebuildMenu(_ menu: NSMenu) {
        menu.removeAllItems()

        // Title row
        let titleItem = NSMenuItem(title: "AirStage", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(.separator())

        for action in menuModel.actions {
            switch action.id {
            case .removeLayer:
                let item = makeItem(action)
                let sub = NSMenu()
                sub.autoenablesItems = false
                
                let layers = menuModel.removableLayers
                if layers.isEmpty {
                    let emptyItem = NSMenuItem(title: "No layers in scene.", action: nil, keyEquivalent: "")
                    emptyItem.isEnabled = false
                    sub.addItem(emptyItem)
                } else {
                    for layer in layers {
                        let subItem = NSMenuItem(
                            title: layer.displayTitle,
                            action: #selector(handleRemoveLayerAction(_:)),
                            keyEquivalent: ""
                        )
                        subItem.representedObject = layer.id
                        sub.addItem(subItem)
                    }
                }
                
                item.submenu = sub
                menu.addItem(item)

            case .camera:
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
    }

    private func makeItem(_ action: MenuAction) -> NSMenuItem {
        let keyEquivalent = (action.id == .quit) ? "q" : ""
        let item = NSMenuItem(
            title: action.title,
            action: action.isEnabled ? #selector(handleMenuAction(_:)) : nil,
            keyEquivalent: keyEquivalent
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

    @objc private func handleRemoveLayerAction(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID else { return }
        menuModel.removeLayer(withID: id)
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        rebuildMenu(menu)
    }
}
