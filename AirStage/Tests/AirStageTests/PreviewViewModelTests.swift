import XCTest
@testable import AirStage

@MainActor
final class PreviewViewModelTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        super.tearDown()
    }

    func testPreviewShowsCameraPermissionRequiredWhenPermissionMissing() {
        let fake = FakeCameraPermissionService(status: .notDetermined)
        let vm = PreviewViewModel(permissionService: fake)

        XCTAssertEqual(vm.cameraState, .permissionRequired)
    }

    func testPreviewShowsCameraPermissionRequiredWhenPermissionDenied() {
        let fake = FakeCameraPermissionService(status: .denied)
        let vm = PreviewViewModel(permissionService: fake)

        XCTAssertEqual(vm.cameraState, .permissionRequired)
    }

    func testShowPreviewActionCreatesVisiblePreviewState() {
        let fake = FakeCameraPermissionService(status: .authorized)
        let vm = PreviewViewModel(permissionService: fake)

        XCTAssertEqual(vm.cameraState, .ready)
    }

    func testCameraPermissionStateIsLogged() {
        let cases: [(CameraPermissionStatus, CameraState)] = [
            (.notDetermined, .permissionRequired),
            (.denied,        .permissionRequired),
            (.restricted,    .permissionRequired),
            (.authorized,    .ready),
        ]
        for (status, expected) in cases {
            let vm = PreviewViewModel(permissionService: FakeCameraPermissionService(status: status))
            XCTAssertEqual(vm.cameraState, expected, "Expected \(expected) for status \(status)")
        }
    }

    func testOnStateChangeFiresWhenSessionStarts() {
        let fakeSession = FakeCameraSession()
        let vm = PreviewViewModel(
            permissionService: FakeCameraPermissionService(status: .authorized),
            cameraSession: fakeSession
        )

        var observed: CameraState?
        vm.onStateChange = { observed = $0 }

        vm.startCameraSessionIfReady()

        XCTAssertEqual(observed, .running)
    }

    func testOnStateChangeFiresWhenSessionFails() {
        let fakeSession = FakeCameraSession()
        fakeSession.failOnStart = true
        let vm = PreviewViewModel(
            permissionService: FakeCameraPermissionService(status: .authorized),
            cameraSession: fakeSession
        )

        var observed: CameraState?
        vm.onStateChange = { observed = $0 }

        vm.startCameraSessionIfReady()

        guard case .failed = observed else {
            XCTFail("Expected .failed, got \(String(describing: observed))")
            return
        }
    }

    func testOnStateChangeFiresWhenPermissionGranted() {
        let fake = FakeRequestableCameraPermissionService(initial: .notDetermined, grantOnRequest: true)
        let vm = PreviewViewModel(permissionService: fake)

        var observed: CameraState?
        vm.onStateChange = { observed = $0 }

        let exp = expectation(description: "permission granted")
        vm.requestCameraPermission { _ in exp.fulfill() }
        wait(for: [exp], timeout: 1)

        XCTAssertEqual(observed, .ready)
    }

    func testQuickAddToolbarVisibleWhenPreviewHovered() {
        let vm = PreviewViewModel(permissionService: FakeRequestableCameraPermissionService(initial: .notDetermined, grantOnRequest: true))
        XCTAssertFalse(vm.shouldShowQuickAddToolbar)
        vm.setHovered(true)
        XCTAssertFalse(vm.shouldShowQuickAddToolbar) // Onboarding not completed
        
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        let vmCompleted = PreviewViewModel(permissionService: FakeRequestableCameraPermissionService(initial: .notDetermined, grantOnRequest: true))
        
        XCTAssertFalse(vmCompleted.shouldShowQuickAddToolbar)
        vmCompleted.setHovered(true)
        XCTAssertTrue(vmCompleted.shouldShowQuickAddToolbar)
        vmCompleted.setHovered(false)
        XCTAssertFalse(vmCompleted.shouldShowQuickAddToolbar)
    }

    func testQuickAddNoteAddsNoteLayer() {
        let store = SceneStore()
        let vm = PreviewViewModel(permissionService: FakeRequestableCameraPermissionService(initial: .notDetermined, grantOnRequest: true), sceneStore: store)
        
        vm.quickAddNote()
        XCTAssertEqual(store.layers.count, 1)
        XCTAssertEqual(store.layers.first?.kind, .note)
    }

    func testQuickAddClearRemovesAllLayersAfterConfirmationOrSimpleAction() {
        let store = SceneStore()
        let vm = PreviewViewModel(permissionService: FakeRequestableCameraPermissionService(initial: .notDetermined, grantOnRequest: true), sceneStore: store)
        
        _ = store.addNote(title: "Sticky")
        XCTAssertEqual(store.layers.count, 1)
        
        vm.quickAddClear()
        XCTAssertEqual(store.layers.count, 0)
    }

    func testQuickAddShowsSceneFullMessageWhenLimitReached() {
        let store = SceneStore()
        let vm = PreviewViewModel(permissionService: FakeRequestableCameraPermissionService(initial: .notDetermined, grantOnRequest: true), sceneStore: store)
        
        // Fill store to total limit (6)
        for i in 0..<4 { _ = store.addNote(title: "Note \(i)") }
        for i in 0..<2 { _ = store.addImage(title: "Image \(i)") }
        
        XCTAssertNil(vm.toolbarErrorMessage)
        vm.quickAddNote()
        XCTAssertEqual(vm.toolbarErrorMessage, "Scene is full")
    }

    func testViewModelOnboardingSpawnsAndRemovesTutorialCard() {
        let store = SceneStore()
        let vm = PreviewViewModel(permissionService: FakeCameraPermissionService(status: .authorized), sceneStore: store)

        // Clean user defaults before testing
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")

        XCTAssertEqual(vm.onboardingStep, .welcome)
        XCTAssertEqual(store.layers.count, 0)

        vm.handleOnboardingEvent(.showMeTapped)
        XCTAssertEqual(vm.onboardingStep, .grabTutorial)
        XCTAssertEqual(store.layers.count, 1)
        XCTAssertEqual(store.layers.first?.kind, .tutorial)

        // Transition forward
        vm.handleOnboardingEvent(.observe(grabbing: true, scale: 1.0))
        XCTAssertEqual(vm.onboardingStep, .grabSuccess)

        vm.handleOnboardingEvent(.continueTapped)
        XCTAssertEqual(vm.onboardingStep, .zoomTutorial)

        vm.handleOnboardingEvent(.observe(grabbing: false, scale: 1.0))
        for _ in 1...6 { vm.handleOnboardingEvent(.observe(grabbing: false, scale: 1.2)) }
        XCTAssertEqual(vm.onboardingStep, .zoomSuccess)

        vm.handleOnboardingEvent(.continueTapped)
        XCTAssertEqual(vm.onboardingStep, .shrinkTutorial)

        vm.handleOnboardingEvent(.observe(grabbing: false, scale: 1.2))
        for _ in 1...6 { vm.handleOnboardingEvent(.observe(grabbing: false, scale: 1.0)) }
        XCTAssertEqual(vm.onboardingStep, .shrinkHold)

        vm.handleOnboardingEvent(.vanishHoldCompleted)
        XCTAssertEqual(vm.onboardingStep, .vanishSuccess)
        
        let exp = expectation(description: "tutorial card removed and prompt shown")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            XCTAssertEqual(store.layers.count, 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            XCTAssertEqual(vm.onboardingStep, .virtualCameraPrompt)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 4.5)
    }

    func testViewModelOnboardingUpdatesTutorialCardTitle() {
        let store = SceneStore()
        let vm = PreviewViewModel(permissionService: FakeCameraPermissionService(status: .authorized), sceneStore: store)
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")

        vm.handleOnboardingEvent(.showMeTapped)
        XCTAssertEqual(store.layers.first?.title, "Grab me")

        vm.handleOnboardingEvent(.observe(grabbing: true, scale: 1.0))
        XCTAssertEqual(store.layers.first?.title, "Grab me")

        vm.handleOnboardingEvent(.continueTapped)
        XCTAssertEqual(store.layers.first?.title, "Zoom me")

        vm.handleOnboardingEvent(.observe(grabbing: false, scale: 1.0))
        for _ in 1...6 { vm.handleOnboardingEvent(.observe(grabbing: false, scale: 1.2)) }
        XCTAssertEqual(store.layers.first?.title, "Zoom me")

        vm.handleOnboardingEvent(.continueTapped)
        XCTAssertEqual(store.layers.first?.title, "Shrink me")
    }

    func testViewModelOnboardingReset() {
        let store = SceneStore()
        let vm = PreviewViewModel(permissionService: FakeCameraPermissionService(status: .authorized), sceneStore: store)

        // Completed starts as completed
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        let vmCompleted = PreviewViewModel(permissionService: FakeCameraPermissionService(status: .authorized), sceneStore: store)
        XCTAssertEqual(vmCompleted.onboardingStep, .completed)

        vmCompleted.resetOnboarding()
        XCTAssertEqual(vmCompleted.onboardingStep, .welcome)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"))
    }

    func testViewModelOnboardingAutoVanishAfterHold() {
        let store = SceneStore()
        let vm = PreviewViewModel(permissionService: FakeCameraPermissionService(status: .authorized), sceneStore: store)
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")

        vm.handleOnboardingEvent(.showMeTapped)
        vm.handleOnboardingEvent(.observe(grabbing: true, scale: 1.0))
        vm.handleOnboardingEvent(.continueTapped)
        vm.handleOnboardingEvent(.observe(grabbing: false, scale: 1.0))
        for _ in 1...6 { vm.handleOnboardingEvent(.observe(grabbing: false, scale: 1.2)) }
        vm.handleOnboardingEvent(.continueTapped)

        let exp = expectation(description: "vanish hold completes")
        vm.handleOnboardingEvent(.observe(grabbing: false, scale: 1.2))
        for _ in 1...6 { vm.handleOnboardingEvent(.observe(grabbing: false, scale: 1.0)) }
        XCTAssertEqual(vm.onboardingStep, .shrinkHold)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            XCTAssertEqual(vm.onboardingStep, .vanishSuccess)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 6.3) {
            XCTAssertEqual(vm.onboardingStep, .virtualCameraPrompt)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 8.0)
    }

    func testViewModelOnboardingVanishViaDeleteKeyOrOutsideDrag() {
        let store = SceneStore()
        let vm = PreviewViewModel(permissionService: FakeCameraPermissionService(status: .authorized), sceneStore: store)
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")

        vm.handleOnboardingEvent(.showMeTapped)
        vm.handleOnboardingEvent(.observe(grabbing: true, scale: 1.0))
        vm.handleOnboardingEvent(.continueTapped)
        vm.handleOnboardingEvent(.observe(grabbing: false, scale: 1.0))
        for _ in 1...6 { vm.handleOnboardingEvent(.observe(grabbing: false, scale: 1.2)) }
        vm.handleOnboardingEvent(.continueTapped)

        XCTAssertEqual(vm.onboardingStep, .shrinkTutorial)
        XCTAssertEqual(store.layers.count, 1)

        // Remove tutorial card directly from store (simulates drag-outside or delete)
        if let tutorial = store.layers.first(where: { $0.kind == .tutorial }) {
            store.removeLayer(withID: tutorial.id, reason: "manual")
        }

        XCTAssertEqual(vm.onboardingStep, .vanishSuccess)

        let exp = expectation(description: "vanish transition completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            XCTAssertEqual(vm.onboardingStep, .virtualCameraPrompt)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
    }

    func testShowMeAutoEnablesHandControl() {
        let store = SceneStore()
        let settings = SettingsStore(defaults: UserDefaults())
        settings.handControl = false
        let vm = PreviewViewModel(
            permissionService: FakeCameraPermissionService(status: .authorized),
            sceneStore: store,
            settingsStore: settings
        )
        XCTAssertFalse(settings.handControl)
        vm.handleOnboardingEvent(.showMeTapped)
        XCTAssertTrue(settings.handControl)
    }

    func testOnFrameCapturedDrivesGestureEngine() {
        let store = SceneStore()
        let settings = SettingsStore(defaults: UserDefaults())
        settings.handControl = true
        let fakeSession = FakeCameraSession()
        
        let handFrame = HandPoseFrame(
            indexTip: CGPoint(x: 0.5, y: 0.5),
            thumbTip: CGPoint(x: 0.52, y: 0.52),
            confidence: 0.9
        )
        let fakeTracker = FakeHandPoseTracker(frames: [handFrame])
        
        let vm = PreviewViewModel(
            permissionService: FakeCameraPermissionService(status: .authorized),
            cameraSession: fakeSession,
            sceneStore: store,
            settingsStore: settings,
            handPoseTracker: fakeTracker
        )
        
        // Spawn tutorial card
        vm.handleOnboardingEvent(.showMeTapped)
        XCTAssertEqual(store.layers.count, 1)
        let tutorialID = store.layers.first!.id
        
        // Let's create a fake CVPixelBuffer and feed it.
        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!
        ] as CFDictionary
        CVPixelBufferCreate(kCFAllocatorDefault, 640, 480, kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
        
        guard let buffer = pixelBuffer else {
            XCTFail("Could not create pixel buffer")
            return
        }
        
        let expectation = self.expectation(description: "Wait for background task processing frame")
        
        // Subscribe to gesture state changes in debugOverlay / gestureLayerController
        // Wait, gestureLayerController will transition to grabbing.
        // We can check if grabbedLayerID updates.
        
        fakeSession.onFrameCaptured?(buffer)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(vm.gestureLayerController?.currentGrabbedLayerID, tutorialID)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    func testVanishHoldIsTriggeredForNormalLayerBelowThreshold() {
        let store = SceneStore()
        let vm = PreviewViewModel(
            permissionService: FakeCameraPermissionService(status: .authorized),
            sceneStore: store
        )
        
        guard let id = store.addNote(title: "Note", position: CGPoint(x: 100, y: 100), size: CGSize(width: 150, height: 150)).layerID else {
            XCTFail("Failed to add note")
            return
        }
        
        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
        store.beginResize(withID: id)
        store.resizeLayer(withID: id, size: CGSize(width: 50, height: 50), position: CGPoint(x: 50, y: 50), sceneBounds: bounds)
        
        XCTAssertTrue(vm.vanishHoldingLayerIDs.contains(id))
    }

    func testVanishHoldCancelsWhenScaledBackUp() {
        let store = SceneStore()
        let vm = PreviewViewModel(
            permissionService: FakeCameraPermissionService(status: .authorized),
            sceneStore: store
        )
        
        guard let id = store.addNote(title: "Note", position: CGPoint(x: 100, y: 100), size: CGSize(width: 150, height: 150)).layerID else {
            XCTFail("Failed to add note")
            return
        }
        
        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
        store.beginResize(withID: id)
        store.resizeLayer(withID: id, size: CGSize(width: 50, height: 50), position: CGPoint(x: 50, y: 50), sceneBounds: bounds)
        
        XCTAssertTrue(vm.vanishHoldingLayerIDs.contains(id))
        
        // Scale it back up above 0.4
        store.resizeLayer(withID: id, size: CGSize(width: 100, height: 100), position: CGPoint(x: 50, y: 50), sceneBounds: bounds)
        XCTAssertFalse(vm.vanishHoldingLayerIDs.contains(id))
    }

    func testVanishHoldCompletesAndRemovesNormalLayer() {
        let store = SceneStore()
        let vm = PreviewViewModel(
            permissionService: FakeCameraPermissionService(status: .authorized),
            sceneStore: store
        )
        
        guard let id = store.addNote(title: "Note", position: CGPoint(x: 100, y: 100), size: CGSize(width: 150, height: 150)).layerID else {
            XCTFail("Failed to add note")
            return
        }
        
        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
        store.beginResize(withID: id)
        store.resizeLayer(withID: id, size: CGSize(width: 50, height: 50), position: CGPoint(x: 50, y: 50), sceneBounds: bounds)
        
        XCTAssertTrue(vm.vanishHoldingLayerIDs.contains(id))
        
        // Directly complete vanish hold to avoid 3s timer delay
        vm.completeVanishHold(for: id)
        
        XCTAssertFalse(vm.vanishHoldingLayerIDs.contains(id))
        XCTAssertTrue(vm.disintegratedLayerIDs.contains(id))
        
        // Expect layer to be removed after 1.5 seconds
        let expectation = self.expectation(description: "Wait for disintegration animation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            XCTAssertNil(store.layer(withID: id))
            XCTAssertFalse(vm.disintegratedLayerIDs.contains(id))
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}
