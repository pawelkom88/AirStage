import Foundation
import Combine
import OSLog
import CoreVideo

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

    @Published public var debugPinchPoint: CGPoint?
    @Published public var isPinchHovering: Bool = false
    @Published public var pinchBaselineDistance: CGFloat?

    @Published public var debugHandPoints: [HandDebugPoint] = []
    @Published public var debugCards: [CardDebugInfo] = []
    @Published public var debugGesture: GestureDebugInfo?
    @Published public var debugOnboarding: OnboardingDebugInfo?
    @Published public private(set) var isDebugOverlayVisible: Bool = false

    @Published public private(set) var canvasGeometry = CanvasGeometry(
        viewSize: CGSize(width: 640, height: 480),
        sourceAspectRatio: 4.0 / 3.0,
        contentMode: .fill,
        isMirrored: false
    )

    public var sceneBounds: CGRect {
        canvasGeometry.sceneBounds
    }

    @Published public var vanishHoldingLayerIDs: Set<UUID> = []
    @Published public var disintegratedLayerIDs: Set<UUID> = []
    @Published public private(set) var edgeDeleteState: EdgeDeleteState = .idle
    @Published public var draggedCardFrame: CGRect?
    private let edgeDeleteController = EdgeDeleteController()
    private var vanishHoldTimers: [UUID: Timer] = [:]

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
    public let settingsStore: SettingsStore?
    public var gestureLayerController: GestureLayerController?
    public let virtualCameraManager: VirtualCameraManager?

    private static let onboardingCompletedKey = "hasCompletedOnboarding"
    @Published public private(set) var onboardingStep: OnboardingStep
    private var onboardingMachine: OnboardingStateMachine
    
    @Published public var presenterShelfStore: PresenterShelfStore

    @MainActor
    public init(
        permissionService: CameraPermissionService,
        cameraSession: CameraSession? = nil,
        sceneStore: SceneStore? = nil,
        settingsStore: SettingsStore? = nil,
        virtualCameraManager: VirtualCameraManager? = nil,
        handPoseTracker: HandPoseTracking = VisionHandPoseTracker()
    ) {
        self.permissionService = permissionService
        self.cameraSession = cameraSession
        self.sceneStore = sceneStore
        self.settingsStore = settingsStore
        self.virtualCameraManager = virtualCameraManager
        self.handPoseTracker = handPoseTracker
        
        self.isDebugOverlayVisible = settingsStore?.debugOverlay ?? false
        
        let resolved = Self.resolve(permissionService.currentStatus)
        self.cameraState = resolved

        let hasCompleted = UserDefaults.standard.bool(forKey: Self.onboardingCompletedKey)
        let machine = OnboardingStateMachine(hasCompleted: hasCompleted)
        self.onboardingMachine = machine
        self.onboardingStep = machine.currentStep
        self.presenterShelfStore = PresenterShelfStore()

        if let store = sceneStore {
            self.gestureLayerController = GestureLayerController(sceneStore: store, sceneBounds: canvasGeometry.sceneBounds)
        }

        setupLayersSubscription()
        setupSettingsSubscription()
        setupEdgeDeleteSubscription()

        cameraSession?.onFrameCaptured = { [weak self] pixelBuffer in
            self?.processVideoFrame(pixelBuffer)
        }

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

                // Shrink-to-delete logic for normal layers
                for layer in layers {
                    if layer.kind == .tutorial { continue }
                    
                    let baseWidth: CGFloat
                    switch layer.kind {
                    case .image: baseWidth = 200
                    case .windowCapture: baseWidth = 240
                    default: baseWidth = 150
                    }
                    
                    let scale = layer.size.width / baseWidth
                    if scale <= 0.4 {
                        self.startVanishHold(for: layer.id)
                    } else {
                        self.cancelVanishHold(for: layer.id)
                    }
                }
                
                // Clean up vanish states for any removed layers
                let activeIDs = Set(layers.map { $0.id })
                for id in self.vanishHoldingLayerIDs {
                    if !activeIDs.contains(id) {
                        self.cancelVanishHold(for: id)
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

    private func setupSettingsSubscription() {
        settingsStore?.$debugOverlay
            .removeDuplicates()
            .sink { [weak self] visible in
                self?.setDebugOverlayVisible(visible)
            }
            .store(in: &cancellables)
    }

    private func setupEdgeDeleteSubscription() {
        edgeDeleteController.$state
            .sink { [weak self] state in
                self?.edgeDeleteState = state
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

    public var isOnboardingCompleted: Bool {
        onboardingStep == .completed
    }

    public var shouldShowQuickAddToolbar: Bool {
        isToolbarVisible && isOnboardingCompleted
    }

    public func setHovered(_ hovered: Bool) {
        guard onboardingStep == .completed else {
            isToolbarVisible = false
            return
        }
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

        if onboardingStep == .vanishSuccess && oldStep != .vanishSuccess {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                guard let self = self else { return }
                if self.onboardingStep == .vanishSuccess {
                    self.handleOnboardingEvent(.completionDelayElapsed)
                }
            }
        }

        if onboardingStep != .completed {
            isToolbarVisible = false
        }

        switch command {
        case .none:
            break
        case .spawnTutorialSceneItem:
            replaceTutorialSceneItemForCurrentStep()
            settingsStore?.handControl = true
        case .replaceTutorialSceneItem:
            cancelActiveGesture()
            replaceTutorialSceneItemForCurrentStep()
        case .removeTutorialSceneItem:
            if event == .vanishHoldCompleted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                    self?.removeTutorialSceneItem()
                }
            } else {
                removeTutorialSceneItem()
            }
        case .requestVirtualCameraActivation:
            requestVirtualCameraActivation()
            persistCompleted()
        case .persistCompleted:
            persistCompleted()
        }

        updateTutorialCardTitle()
    }

    private struct TutorialCardTemplate {
        let title: String
        let position: CGPoint
        let size: CGSize
    }

    private func tutorialTemplate(for step: OnboardingStep) -> TutorialCardTemplate {
        switch step {
        case .grabTutorial, .grabSuccess:
            return TutorialCardTemplate(
                title: "Grab me",
                position: CGPoint(x: 320, y: 240),
                size: CGSize(width: 150, height: 150)
            )

        case .zoomTutorial, .zoomSuccess:
            return TutorialCardTemplate(
                title: "Zoom me",
                position: CGPoint(x: 320, y: 240),
                size: CGSize(width: 150, height: 150)
            )

        case .shrinkTutorial, .shrinkHold:
            return TutorialCardTemplate(
                title: "Shrink me",
                position: CGPoint(x: 320, y: 240),
                size: CGSize(width: 150, height: 150)
            )

        default:
            return TutorialCardTemplate(
                title: "Tutorial",
                position: CGPoint(x: 320, y: 240),
                size: CGSize(width: 150, height: 150)
            )
        }
    }

    private func replaceTutorialSceneItemForCurrentStep() {
        guard let store = sceneStore else { return }

        // Find existing tutorial layers to remove AFTER adding the new one
        let existingTutorialLayers = store.layers.filter { $0.kind == .tutorial }

        let template = tutorialTemplate(for: onboardingStep)

        let result = store.addTutorialCard(
            title: template.title,
            position: template.position,
            size: template.size
        )

        if case .success(let id) = result {
            store.selectLayer(id)
        }
        
        // Now remove the old ones
        for layer in existingTutorialLayers {
            store.removeLayer(withID: layer.id, reason: "onboarding")
        }

        updateTutorialCardTitle()
    }

    private func cancelActiveGesture() {
        guard var controller = gestureLayerController else { return }
        controller.cancelActiveGesture()
        gestureLayerController = controller

        debugGesture = GestureDebugInfo(
            isGrabActive: false,
            isPinchActive: false,
            pinchBaseline: nil,
            pinchCurrent: nil,
            pinchDelta: nil
        )

        pinchBaselineDistance = nil
        debugPinchPoint = nil
        isPinchHovering = false
    }

    private func updateTutorialCardTitle() {
        guard let store = sceneStore else { return }
        if let tutorialLayer = store.layers.first(where: { $0.kind == .tutorial }) {
            let newTitle: String
            switch onboardingStep {
            case .grabTutorial, .grabSuccess:
                newTitle = "Grab me"
            case .zoomTutorial, .zoomSuccess:
                newTitle = "Zoom me"
            case .shrinkTutorial, .shrinkHold:
                newTitle = "Shrink me"
            default:
                newTitle = "Tutorial"
            }
            if tutorialLayer.title != newTitle {
                store.updateNoteText(layerID: tutorialLayer.id, text: newTitle)
            }
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
        virtualCameraManager?.requestInstall()
    }

    private func persistCompleted() {
        UserDefaults.standard.set(true, forKey: Self.onboardingCompletedKey)
        AppLog.onboarding.info("Onboarding completed")
        NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
    }

    public func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: Self.onboardingCompletedKey)
        handleOnboardingEvent(.resetRequested)
    }

    // MARK: - Debug Overlay

    public func ensureDebugOverlayHasInitialState() {
        guard isDebugOverlayVisible else { return }

        if debugOnboarding == nil {
            let scale = sceneStore?.layers.first(where: { $0.kind == .tutorial })?.size.width ?? 150
            let normalizedScale = scale / 150

            debugOnboarding = OnboardingDebugInfo(
                step: onboardingMachine.currentStep.rawValue,
                baselineScale: nil,
                currentScale: normalizedScale,
                targetScale: nil,
                successFrames: onboardingMachine.successFrameCount,
                conditionMet: false
            )
        }

        if debugGesture == nil {
            debugGesture = GestureDebugInfo(
                isGrabActive: false,
                isPinchActive: false,
                pinchBaseline: nil,
                pinchCurrent: nil,
                pinchDelta: nil
            )
        }

        if debugCards.isEmpty, let store = sceneStore {
            debugCards = store.layers.map { layer in
                let rect = CGRect(
                    x: layer.position.x - layer.size.width / 2,
                    y: layer.position.y - layer.size.height / 2,
                    width: layer.size.width,
                    height: layer.size.height
                )

                let baseWidth: CGFloat
                switch layer.kind {
                case .image: baseWidth = 200
                case .windowCapture: baseWidth = 240
                default: baseWidth = 150
                }
                let currentScale = layer.size.width / baseWidth
                let dynamicRadius = InteractionHitPolicy.resizeHandleRadius(for: rect)
                let dragSafeRect = InteractionHitPolicy.dragSafeRect(for: rect)

                return CardDebugInfo(
                    id: layer.id,
                    rect: rect,
                    scale: currentScale,
                    isGrabbed: false,
                    activeHandle: nil,
                    nearestHandle: nil,
                    distanceToHandle: nil,
                    handleHitRadius: dynamicRadius,
                    dragSafeRect: dragSafeRect,
                    interactionModeDescription: "none"
                )
            }
        }
    }

    public func setDebugOverlayVisible(_ visible: Bool) {
        settingsStore?.debugOverlay = visible
        isDebugOverlayVisible = visible

        if visible {
            ensureDebugOverlayHasInitialState()
        } else {
            debugHandPoints = []
            debugCards = []
            debugGesture = nil
            debugOnboarding = nil
            debugPinchPoint = nil
            isPinchHovering = false
        }
    }

    public func toggleDebugOverlay() {
        setDebugOverlayVisible(!isDebugOverlayVisible)
    }

    /// Computes a read-only snapshot of the current debug state.
    public func debugOverlaySnapshot() -> DebugOverlayState {
        let cameraStatusString: String
        switch cameraState {
        case .permissionRequired: cameraStatusString = "permissionRequired"
        case .ready:              cameraStatusString = "ready"
        case .running:            cameraStatusString = "running"
        case .failed(let msg):    cameraStatusString = "failed: \(msg)"
        }

        let selectedTitle = sceneStore?.layers.first(where: { $0.isSelected })?.displayTitle
        let layerCount = sceneStore?.layers.count ?? 0
        let handControl = settingsStore?.handControl ?? false

        AppLog.app.debug("Debug overlay snapshot layers=\(layerCount) selected=\(selectedTitle ?? "none", privacy: .public) camera=\(cameraStatusString, privacy: .public) hand=\(handControl)")

        let gestureStateString: String
        if let grabbed = gestureLayerController?.currentGrabbedLayerID {
            gestureStateString = "grabbing \(grabbed.uuidString.prefix(8))"
        } else {
            gestureStateString = "idle"
        }

        let deleteStateDesc: String
        switch edgeDeleteState {
        case .idle:
            deleteStateDesc = "idle"
        case .hovering:
            deleteStateDesc = "hovering"
        case .armed:
            deleteStateDesc = "armed"
        case .disintegrating:
            deleteStateDesc = "disintegrating"
        }
        
        let sideDesc: String?
        if let side = edgeDeleteState.side {
            sideDesc = (side == .left ? "left" : "right")
        } else {
            sideDesc = nil
        }
        
        let edgeInfo = EdgeDeleteDebugInfo(
            stateDescription: deleteStateDesc,
            side: sideDesc,
            layerID: edgeDeleteState.layerID,
            deleteZoneWidth: 96,
            sceneBounds: sceneBounds
        )

        return DebugOverlayState(
            cameraStatus: cameraStatusString,
            layerCount: layerCount,
            selectedLayerTitle: selectedTitle,
            handControlEnabled: handControl,
            gestureState: gestureStateString,
            edgeDeleteInfo: edgeInfo
        )
    }

    // MARK: - Helpers

    private static func resolve(_ status: CameraPermissionStatus) -> CameraState {
        switch status {
        case .authorized:                       return .ready
        case .notDetermined, .denied, .restricted: return .permissionRequired
        }
    }

    private let handPoseTracker: HandPoseTracking
    private var gestureEngine = GestureEngine()

    private func processVideoFrame(_ pixelBuffer: CVPixelBuffer) {
        Task {
            do {
                let frame = try await handPoseTracker.processFrame(pixelBuffer)
                await MainActor.run {
                    self.handleHandPoseFrame(frame)
                }
            } catch {
                AppLog.gestures.error("Failed to process frame: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    private func handleHandPoseFrame(_ frame: HandPoseFrame) {
        let rawEvent = gestureEngine.process(frame)
        
        let mappedEvent: GestureEvent
        switch rawEvent {
        case .none:
            mappedEvent = .none
        case .pinchBegan(let center):
            mappedEvent = .pinchBegan(at: canvasGeometry.convertHandPointToCanvas(center))
            pinchBaselineDistance = frame.pinchDistance
        case .pinchMoved(let center):
            mappedEvent = .pinchMoved(to: canvasGeometry.convertHandPointToCanvas(center))
        case .pinchEnded:
            mappedEvent = .pinchEnded
            pinchBaselineDistance = nil
        }
        
        if let controller = gestureLayerController {
            let handControlEnabled = settingsStore?.handControl ?? false
            var mutableController = controller
            mutableController.handle(mappedEvent, handControlEnabled: handControlEnabled)
            self.gestureLayerController = mutableController
            
            if let grabbedID = mutableController.currentGrabbedLayerID,
               let movedLayer = sceneStore?.layers.first(where: { $0.id == grabbedID }),
               !mutableController.isResizing {
                updateEdgeDeleteForDraggedLayer(movedLayer)
            }
            
            if case .pinchEnded = mappedEvent {
                if !edgeDeleteState.isDisintegrating {
                    cancelEdgeDeleteIfNeeded()
                }
            }
            
            // Generate debug data
            if isDebugOverlayVisible {
                generateDebugData(frame: frame, gestureEvent: mappedEvent, controller: mutableController)
            }
            
            if let center = frame.pinchCandidateCenter {
                debugPinchPoint = canvasGeometry.convertHandPointToCanvas(center)
                isPinchHovering = (mutableController.currentGrabbedLayerID != nil)
            } else {
                debugPinchPoint = nil
                isPinchHovering = false
            }
            
            if handControlEnabled {
                // Onboarding observe
                if let tutorialLayer = sceneStore?.layers.first(where: { $0.kind == .tutorial }) {
                    let isGrabbing = (mutableController.currentGrabbedLayerID == tutorialLayer.id)
                    let scale = tutorialLayer.size.width / 150.0
                    handleOnboardingEvent(.observe(grabbing: isGrabbing, scale: scale))
                }
            }
        }
    }

    private func generateDebugData(frame: HandPoseFrame, gestureEvent: GestureEvent, controller: GestureLayerController) {
        // Hand Points
        var newPoints: [HandDebugPoint] = []
        if let indexTip = frame.indexTip {
            let canvas = canvasGeometry.convertHandPointToCanvas(indexTip)
            newPoints.append(HandDebugPoint(label: "index", rawNormalized: indexTip, canvasPoint: canvas, confidence: frame.confidence))
        }
        if let thumbTip = frame.thumbTip {
            let canvas = canvasGeometry.convertHandPointToCanvas(thumbTip)
            newPoints.append(HandDebugPoint(label: "thumb", rawNormalized: thumbTip, canvasPoint: canvas, confidence: frame.confidence))
        }
        if let center = frame.pinchCandidateCenter {
            let canvas = canvasGeometry.convertHandPointToCanvas(center)
            newPoints.append(HandDebugPoint(label: "pinchCenter", rawNormalized: center, canvasPoint: canvas, confidence: frame.confidence))
        }
        self.debugHandPoints = newPoints
        
        // Cards
        var newCards: [CardDebugInfo] = []
        if let store = sceneStore {
            for layer in store.layers {
                let rect = CGRect(origin: CGPoint(x: layer.position.x - layer.size.width/2, y: layer.position.y - layer.size.height/2), size: layer.size)
                
                let baseWidth: CGFloat
                switch layer.kind {
                case .image: baseWidth = 200
                case .windowCapture: baseWidth = 240
                default: baseWidth = 150
                }
                let currentScale = layer.size.width / baseWidth
                let dynamicRadius = InteractionHitPolicy.resizeHandleRadius(for: rect)
                let dragSafeRect = InteractionHitPolicy.dragSafeRect(for: rect)
                
                var nHandle: ResizeHandle?
                var dHandle: CGFloat?
                var interactionModeDesc = "none"
                if let center = frame.pinchCandidateCenter {
                    let canvas = canvasGeometry.convertHandPointToCanvas(center)
                    if let result = LayerInteractionResolver.nearestHandle(to: canvas, in: rect, radius: dynamicRadius) {
                        nHandle = result.handle
                        dHandle = result.distance
                    }
                    
                    let mode = LayerInteractionResolver.interactionMode(for: canvas, in: rect)
                    switch mode {
                    case .none: interactionModeDesc = "none"
                    case .drag: interactionModeDesc = "drag"
                    case .resize(let h): interactionModeDesc = "resize(\(h.rawValue))"
                    }
                }
                
                newCards.append(CardDebugInfo(
                    id: layer.id,
                    rect: rect,
                    scale: currentScale,
                    isGrabbed: (layer.id == controller.currentGrabbedLayerID),
                    activeHandle: controller.isResizing ? nHandle : nil,
                    nearestHandle: nHandle,
                    distanceToHandle: dHandle,
                    handleHitRadius: dynamicRadius,
                    dragSafeRect: dragSafeRect,
                    interactionModeDescription: interactionModeDesc
                ))
            }
        }
        self.debugCards = newCards
        
        // Gesture
        let currentPinchDistance = frame.pinchDistance
        let pinchDelta = (pinchBaselineDistance != nil && currentPinchDistance != nil) ? currentPinchDistance! - pinchBaselineDistance! : nil
        self.debugGesture = GestureDebugInfo(
            isGrabActive: controller.currentGrabbedLayerID != nil,
            isPinchActive: gestureEvent != .pinchEnded && frame.pinchCandidateCenter != nil,
            pinchBaseline: pinchBaselineDistance,
            pinchCurrent: currentPinchDistance,
            pinchDelta: pinchDelta
        )
        
        // Onboarding
        let currentScale = sceneStore?.layers.first(where: { $0.kind == .tutorial })?.size.width ?? 150.0
        let normalizedScale = currentScale / 150.0
        let targetScale: CGFloat?
        if onboardingStep == .zoomTutorial {
            targetScale = (onboardingMachine.zoomBaselineScale ?? normalizedScale) * 1.15
        } else if onboardingStep == .shrinkTutorial || onboardingStep == .shrinkHold {
            targetScale = (onboardingMachine.shrinkBaselineScale ?? normalizedScale) * 0.85
        } else {
            targetScale = nil
        }
        
        self.debugOnboarding = OnboardingDebugInfo(
            step: onboardingMachine.currentStep.rawValue,
            baselineScale: onboardingStep == .zoomTutorial ? onboardingMachine.zoomBaselineScale : (onboardingStep == .shrinkTutorial || onboardingStep == .shrinkHold ? onboardingMachine.shrinkBaselineScale : nil),
            currentScale: normalizedScale,
            targetScale: targetScale,
            successFrames: onboardingMachine.successFrameCount,
            conditionMet: onboardingMachine.successFrameCount >= 6
        )
    }

    public func startVanishHold(for id: UUID) {
        guard !vanishHoldingLayerIDs.contains(id) else { return }
        vanishHoldingLayerIDs.insert(id)
        
        let timer = Timer.scheduledTimer(withTimeInterval: OnboardingThresholds.vanishHoldDuration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.completeVanishHold(for: id)
        }
        vanishHoldTimers[id] = timer
    }

    public func cancelVanishHold(for id: UUID) {
        guard vanishHoldingLayerIDs.contains(id) else { return }
        vanishHoldingLayerIDs.remove(id)
        vanishHoldTimers[id]?.invalidate()
        vanishHoldTimers[id] = nil
    }

    func completeVanishHold(for id: UUID) {
        cancelVanishHold(for: id)
        disintegratedLayerIDs.insert(id)
        
        // Wait for disintegration animation (1.5 seconds) then remove the layer
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            self.sceneStore?.removeLayer(withID: id, reason: "shrinkVanish")
            self.disintegratedLayerIDs.remove(id)
        }
    }

    @MainActor
    public func updateEdgeDeleteForDraggedLayer(_ layer: SceneLayer) {
        let frame = CGRect(
            x: layer.position.x - layer.size.width / 2,
            y: layer.position.y - layer.size.height / 2,
            width: layer.size.width,
            height: layer.size.height
        )
        self.draggedCardFrame = frame

        edgeDeleteController.updateDraggedLayer(
            id: layer.id,
            frame: frame,
            sceneBounds: sceneBounds,
            isOnboardingCompleted: onboardingStep == .completed,
            isTutorialLayer: layer.kind == .tutorial
        ) { [weak self] id, side in
            self?.beginDisintegrationAndDelete(layerID: id, side: side)
        }
    }

    @MainActor
    public func cancelEdgeDeleteIfNeeded() {
        edgeDeleteController.cancel()
    }

    @MainActor
    private func beginDisintegrationAndDelete(layerID: UUID, side: EdgeDeleteSide) {
        edgeDeleteController.markDisintegrating(layerID: layerID, side: side)

        disintegratedLayerIDs.insert(layerID)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { [weak self] in
            guard let self = self else { return }

            self.sceneStore?.removeLayer(withID: layerID, reason: "edgeDelete")
            self.disintegratedLayerIDs.remove(layerID)
            self.edgeDeleteController.cancel()
        }
    }

    public func disintegrationTargetOffset(for layer: SceneLayer) -> CGSize? {
        guard case .disintegrating(let side, let layerID) = edgeDeleteState, layerID == layer.id else {
            return nil
        }
        guard let cardFrame = draggedCardFrame else { return nil }
        
        let badgePos = EdgeDeleteState.badgePosition(side: side, cardFrame: cardFrame, sceneBounds: sceneBounds)
        return CGSize(width: badgePos.x - layer.position.x, height: badgePos.y - layer.position.y)
    }

    @MainActor
    public func updateCanvasSize(_ size: CGSize) {
        guard size.width > 10, size.height > 10 else { return }

        let next = CanvasGeometry(
            viewSize: size,
            sourceAspectRatio: 4.0 / 3.0,
            contentMode: .fill,
            isMirrored: false
        )

        guard next != canvasGeometry else { return }

        canvasGeometry = next

        gestureLayerController?.updateSceneBounds(next.sceneBounds)

        regenerateDebugDataForCurrentScene()
    }

    private func regenerateDebugDataForCurrentScene() {
        guard isDebugOverlayVisible, let store = sceneStore else { return }
        
        debugCards = store.layers.map { layer in
            let rect = CGRect(
                x: layer.position.x - layer.size.width / 2,
                y: layer.position.y - layer.size.height / 2,
                width: layer.size.width,
                height: layer.size.height
            )

            let baseWidth: CGFloat
            switch layer.kind {
            case .image: baseWidth = 200
            case .windowCapture: baseWidth = 240
            default: baseWidth = 150
            }
            let currentScale = layer.size.width / baseWidth
            let dynamicRadius = InteractionHitPolicy.resizeHandleRadius(for: rect)
            let dragSafeRect = InteractionHitPolicy.dragSafeRect(for: rect)

            return CardDebugInfo(
                id: layer.id,
                rect: rect,
                scale: currentScale,
                isGrabbed: gestureLayerController?.currentGrabbedLayerID == layer.id,
                activeHandle: gestureLayerController?.currentActiveResizeHandle,
                nearestHandle: nil,
                distanceToHandle: nil,
                handleHitRadius: dynamicRadius,
                dragSafeRect: dragSafeRect,
                interactionModeDescription: "none"
            )
        }
    }
    
    // MARK: - Presenter Shelf
    
    @MainActor
    public func togglePresenterShelf() {
        guard onboardingStep == .completed else { return }
        presenterShelfStore.toggle()
    }

    @MainActor
    public func hidePresenterShelf() {
        presenterShelfStore.hide()
    }

    @MainActor
    public func presentSelectedShelfItem() {
        guard onboardingStep == .completed else { return }
        guard let item = presenterShelfStore.selectedItem else { return }

        presenterShelfStore.hide()
        createSceneLayer(from: item)
    }
    
    @MainActor
    private func createSceneLayer(from item: PresenterShelfItem) {
        guard let sceneStore else { return }

        let targetPosition = CGPoint(x: sceneBounds.midX, y: sceneBounds.midY)

        switch item.kind {
        case .screenshot:
            if let url = item.fileURL {
                _ = sceneStore.addImage(title: item.title, imageURL: url, position: targetPosition)
            } else {
                _ = sceneStore.addNote(
                    title: item.title,
                    position: targetPosition,
                    size: CGSize(width: 320, height: 200)
                )
            }

        default:
            _ = sceneStore.addNote(
                title: item.title,
                position: targetPosition,
                size: CGSize(width: 320, height: 200)
            )
        }
    }
}
