import Foundation
import Combine

/// Observable state for the preview window.
/// Kept free of AppKit/SwiftUI so it can be unit-tested directly.
public final class PreviewViewModel: ObservableObject {

    @Published public private(set) var cameraState: CameraState {
        didSet {
            onStateChange?(cameraState)
        }
    }
    /// Non-nil when permission was denied; contains a user-friendly recovery message.
    @Published public private(set) var permissionDeniedMessage: String?

    @Published public var isToolbarVisible: Bool = false {
        didSet {
            onToolbarVisibilityChange?(isToolbarVisible)
        }
    }

    @Published public var toolbarErrorMessage: String?

    /// Called whenever cameraState changes.
    public var onStateChange: ((CameraState) -> Void)?

    /// Called when toolbar visibility changes.
    public var onToolbarVisibilityChange: ((Bool) -> Void)?

    // Delegates for picker/drop operations
    public var onQuickAddImage: (() -> Void)?
    public var onQuickAddWindow: (() -> Void)?
    public var onQuickAddPaste: (() -> Void)?

    private let permissionService: CameraPermissionService
    private let cameraSession: CameraSession?
    public private(set) var sceneStore: SceneStore?

    private static let onboardingCompletedKey = "hasCompletedOnboarding"
    @Published public private(set) var onboardingStep: OnboardingStep
    private var onboardingMachine: OnboardingStateMachine

    public init(
        permissionService: CameraPermissionService,
        cameraSession: CameraSession? = nil,
        sceneStore: SceneStore? = nil
    ) {
        self.permissionService = permissionService
        self.cameraSession = cameraSession
        self.sceneStore = sceneStore
        let resolved = Self.resolve(permissionService.currentStatus)
        self.cameraState = resolved

        let hasCompleted = UserDefaults.standard.bool(forKey: Self.onboardingCompletedKey)
        let machine = OnboardingStateMachine(hasCompleted: hasCompleted)
        self.onboardingMachine = machine
        self.onboardingStep = machine.currentStep

        setupLayersSubscription()

        AppLog.camera.info("Camera permission status=\(String(describing: permissionService.currentStatus), privacy: .public)")
        AppLog.camera.info("Preview camera state=\(String(describing: resolved), privacy: .public)")
    }

    private var cancellables = Set<AnyCancellable>()

    private func setupLayersSubscription() {
        sceneStore?.$layers
            .sink { [weak self] layers in
                guard let self = self else { return }
                let hasTutorial = layers.contains(where: { $0.kind == .tutorial })
                if !hasTutorial {
                    if self.onboardingStep == .shrinkTutorial || self.onboardingStep == .shrinkHold {
                        self.handleOnboardingEvent(.vanishHoldCompleted)
                    }
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .resetOnboardingRequested)
            .sink { [weak self] _ in
                self?.resetOnboarding()
            }
            .store(in: &cancellables)
    }

    // MARK: - Permission

    /// Requests camera permission if not already determined.
    public func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        guard let requestable = permissionService as? RequestableCameraPermissionService else {
            completion(permissionService.currentStatus == .authorized)
            return
        }
        requestable.requestPermission { [weak self] granted in
            guard let self else { return }
            if granted {
                self.cameraState = .ready
                self.permissionDeniedMessage = nil
                AppLog.camera.info("Camera permission granted")
            } else {
                self.cameraState = .permissionRequired
                self.permissionDeniedMessage = "Camera access was denied. Open System Settings → Privacy & Security → Camera to allow AirStage."
                AppLog.camera.info("Camera permission denied — recovery message set")
            }
            completion(granted)
        }
    }

    // MARK: - Session

    /// Starts the camera session if permission is granted.
    public func startCameraSessionIfReady() {
        guard cameraState == .ready, let session = cameraSession else { return }
        AppLog.camera.info("Camera session starting")
        session.start { [weak self] error in
            guard let self else { return }
            if let error {
                self.cameraState = .failed(error)
                AppLog.camera.error("Camera session failed error=\(error, privacy: .public)")
            } else {
                self.cameraState = .running
                AppLog.camera.info("Camera session running")
            }
        }
    }

    public func stopCameraSession() {
        cameraSession?.stop()
        AppLog.camera.info("Camera session stopped")
    }

    // MARK: - Toolbar Actions

    public func setHovered(_ hovered: Bool) {
        isToolbarVisible = hovered
    }

    public func quickAddNote() {
        AppLog.menu.info("Toolbar action selected action=addNote")
        guard let store = sceneStore else { return }
        let result = store.addNote(
            title: "Sticky Note",
            position: CGPoint(x: 320, y: 240),
            size: CGSize(width: 150, height: 150)
        )
        switch result {
        case .success:
            toolbarErrorMessage = nil
        case .failure(let reason):
            switch reason {
            case .sceneFull:
                toolbarErrorMessage = "Scene is full"
            case .kindLimitExceeded(let kind):
                toolbarErrorMessage = "Limit exceeded for \(kind.rawValue)"
            }
            AppLog.scene.warning("Toolbar action failed action=addNote reason=\(self.toolbarErrorMessage ?? "", privacy: .public)")
        }
    }

    public func quickAddClear() {
        AppLog.menu.info("Toolbar action selected action=clear")
        sceneStore?.clearAllLayers()
    }

    public func quickAddImage() {
        AppLog.menu.info("Toolbar action selected action=addImage")
        onQuickAddImage?()
    }

    public func quickAddWindow() {
        AppLog.menu.info("Toolbar action selected action=addWindow")
        onQuickAddWindow?()
    }

    public func quickAddPaste() {
        AppLog.menu.info("Toolbar action selected action=paste")
        onQuickAddPaste?()
    }

    // MARK: - Onboarding

    public func handleOnboardingEvent(_ event: OnboardingEvent) {
        let oldStep = onboardingStep
        let command = onboardingMachine.handle(event)
        onboardingStep = onboardingMachine.currentStep

        if onboardingStep == .shrinkHold && oldStep != .shrinkHold {
            DispatchQueue.main.asyncAfter(deadline: .now() + OnboardingThresholds.vanishHoldDuration) { [weak self] in
                guard let self = self else { return }
                if self.onboardingStep == .shrinkHold {
                    self.handleOnboardingEvent(.vanishHoldCompleted)
                }
            }
        }

        switch command {
        case .none:
            break
        case .spawnTutorialSceneItem:
            spawnTutorialSceneItem()
        case .removeTutorialSceneItem:
            removeTutorialSceneItem()
        case .requestVirtualCameraActivation:
            requestVirtualCameraActivation()
            persistCompleted()
        case .persistCompleted:
            persistCompleted()
        }
    }

    private func spawnTutorialSceneItem() {
        guard let store = sceneStore else { return }
        removeTutorialSceneItem()
        let result = store.addTutorialCard(
            title: "Grab me",
            position: CGPoint(x: 320, y: 240),
            size: CGSize(width: 150, height: 150)
        )
        if case .success(let id) = result {
            store.selectLayer(id)
        }
    }

    private func removeTutorialSceneItem() {
        guard let store = sceneStore else { return }
        let tutorialLayers = store.layers.filter { $0.kind == .tutorial }
        for layer in tutorialLayers {
            store.removeLayer(withID: layer.id, reason: "onboarding")
        }
    }

    private func requestVirtualCameraActivation() {
        AppLog.virtualCamera.info("Virtual camera install requested from onboarding")
    }

    private func persistCompleted() {
        UserDefaults.standard.set(true, forKey: Self.onboardingCompletedKey)
        AppLog.onboarding.info("Onboarding completed")
    }

    public func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: Self.onboardingCompletedKey)
        handleOnboardingEvent(.resetRequested)
    }

    // MARK: - Helpers

    private static func resolve(_ status: CameraPermissionStatus) -> CameraState {
        switch status {
        case .authorized:                       return .ready
        case .notDetermined, .denied, .restricted: return .permissionRequired
        }
    }
}
