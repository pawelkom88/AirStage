import AppKit
import AVFoundation
import SwiftUI
import AirStage

/// Owns the preview NSWindow. Shows permission placeholder or live camera feed.
final class PreviewWindowController: NSWindowController {

    private let viewModel: PreviewViewModel
    private let cameraSession: AVCameraSession
    private let sceneStore: SceneStore
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private weak var containerView: NSView?
    private var resizeObserver: NSObjectProtocol?

    var onAddImage: (() -> Void)?

    init(permissionService: RequestableCameraPermissionService, sceneStore: SceneStore, settingsStore: SettingsStore, virtualCameraManager: VirtualCameraManager) {
        self.sceneStore = sceneStore
        let session = AVCameraSession()
        self.cameraSession = session
        self.viewModel = PreviewViewModel(permissionService: permissionService, cameraSession: session, sceneStore: sceneStore, settingsStore: settingsStore, virtualCameraManager: virtualCameraManager)

        let window = PreviewWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "AirStage Preview"
        window.center()
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.level = .floating

        super.init(window: window)

        self.viewModel.onQuickAddImage = { [weak self] in
            self?.onAddImage?()
        }
        self.viewModel.onQuickAddPaste = { [weak self] in
            self?.triggerPaste()
        }
        self.viewModel.onQuickAddWindow = {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Window Share Unavailable"
                alert.informativeText = "Window capture is available in a later release."
                alert.alertStyle = .informational
                alert.runModal()
            }
        }

        window.onPaste = { [weak self] in
            self?.triggerPaste()
        }

        window.onDelete = { [weak self] in
            self?.sceneStore.deleteSelectedLayer()
        }

        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.black.cgColor
        container.layer?.cornerRadius = 16
        container.layer?.masksToBounds = true
        window.contentView = container
        self.containerView = container

        viewModel.onStateChange = { [weak self] _ in
            self?.refresh()
        }

        refresh()
        AppLog.camera.info("Preview window created cameraState=\(String(describing: self.viewModel.cameraState), privacy: .public)")
    }

    required init?(coder: NSCoder) { nil }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        AppLog.menu.info("Preview requested")

        switch viewModel.cameraState {
        case .permissionRequired:
            requestPermission()
        case .ready:
            viewModel.startCameraSessionIfReady()
            refresh()
        case .running, .failed:
            break
        }
    }

    // MARK: - Private

    private func requestPermission() {
        viewModel.requestCameraPermission { [weak self] granted in
            guard let self else { return }
            if granted {
                self.viewModel.startCameraSessionIfReady()
            }
            self.refresh()
        }
    }

    private func refresh() {
        guard let container = containerView else { return }
        container.subviews.forEach { $0.removeFromSuperview() }
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
        if let observer = resizeObserver {
            NotificationCenter.default.removeObserver(observer)
            resizeObserver = nil
        }

        switch viewModel.cameraState {
        case .permissionRequired:
            let msg = viewModel.permissionDeniedMessage
                ?? "Camera access needed\n\nAirStage needs permission to show your camera preview."
            container.addSubview(makeCenteredLabel(msg))

        case .ready:
            container.addSubview(makeCenteredLabel("Camera ready — starting…"))

        case .running:
            attachPreviewLayer(to: container)

        case .failed(let err):
            container.addSubview(makeCenteredLabel("Camera unavailable: \(err)"))
        }

        let hostingView = NSHostingView(rootView: PreviewView(sceneStore: sceneStore, viewModel: viewModel))
        hostingView.frame = container.bounds
        hostingView.autoresizingMask = [.width, .height]
        container.addSubview(hostingView)
    }

    private func attachPreviewLayer(to container: NSView) {
        let layer = AVCaptureVideoPreviewLayer(session: cameraSession.session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = container.bounds
        if let connection = layer.connection {
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
            }
        }
        container.layer?.addSublayer(layer)
        previewLayer = layer

        container.postsFrameChangedNotifications = true
        resizeObserver = NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: container,
            queue: .main
        ) { [weak layer, weak container] _ in
            layer?.frame = container?.bounds ?? .zero
        }
    }

    private func makeCenteredLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.alignment = .center
        label.textColor = .secondaryLabelColor
        label.font = .systemFont(ofSize: 14)
        label.frame = containerView?.bounds ?? .zero
        label.autoresizingMask = [.width, .height]
        return label
    }

    private func triggerPaste() {
        let importer = ImageImporter(store: self.sceneStore)
        let handler = DropPasteHandler(importer: importer)
        _ = handler.handlePaste { result in
            if case .failure(let error) = result {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Cannot Paste Image"
                    alert.informativeText = error.errorDescription ?? "An unknown error occurred."
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            }
        }
    }
}

final class PreviewWindow: NSWindow {
    var onPaste: (() -> Void)?
    var onDelete: (() -> Void)?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "v" {
            onPaste?()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 51 || event.keyCode == 117 {
            onDelete?()
            return
        }
        super.keyDown(with: event)
    }
}
