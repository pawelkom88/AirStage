import AppKit
import AVFoundation
import AirStage

/// Owns the preview NSWindow. Shows permission placeholder or live camera feed.
final class PreviewWindowController: NSWindowController {

    private let viewModel: PreviewViewModel
    private let cameraSession: AVCameraSession
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private weak var containerView: NSView?

    init(permissionService: RequestableCameraPermissionService) {
        let session = AVCameraSession()
        self.cameraSession = session
        self.viewModel = PreviewViewModel(permissionService: permissionService, cameraSession: session)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "AirStage Preview"
        window.center()

        super.init(window: window)

        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.black.cgColor
        window.contentView = container
        self.containerView = container

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

        switch viewModel.cameraState {
        case .permissionRequired:
            let msg = viewModel.permissionDeniedMessage
                ?? "Camera access needed\n\nAirStage needs permission to show your camera preview.\nClick to open System Settings."
            container.addSubview(makeCenteredLabel(msg))

        case .ready:
            container.addSubview(makeCenteredLabel("Camera ready — starting…"))

        case .running:
            attachPreviewLayer(to: container)

        case .failed(let err):
            container.addSubview(makeCenteredLabel("Camera unavailable: \(err)"))
        }
    }

    private func attachPreviewLayer(to container: NSView) {
        let layer = AVCaptureVideoPreviewLayer(session: cameraSession.session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = container.bounds
        container.layer?.addSublayer(layer)
        previewLayer = layer

        // Keep layer frame in sync with window resizes.
        NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: container,
            queue: .main
        ) { [weak layer, weak container] _ in
            layer?.frame = container?.bounds ?? .zero
        }
        container.postsFrameChangedNotifications = true
    }

    private func makeCenteredLabel(_ text: String) -> NSTextField {
        let field = NSTextField(wrappingLabelWithString: text)
        field.alignment = .center
        field.textColor = .white
        field.font = .systemFont(ofSize: 16, weight: .medium)
        field.frame = containerView?.bounds ?? .zero
        field.autoresizingMask = [.width, .height]
        return field
    }
}
