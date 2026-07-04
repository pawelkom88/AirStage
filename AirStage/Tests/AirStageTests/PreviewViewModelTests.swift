import XCTest
@testable import AirStage

final class PreviewViewModelTests: XCTestCase {

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
        XCTAssertFalse(vm.isToolbarVisible)
        vm.setHovered(true)
        XCTAssertTrue(vm.isToolbarVisible)
        vm.setHovered(false)
        XCTAssertFalse(vm.isToolbarVisible)
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
        vm.handleOnboardingEvent(.tutorialItemMoved(distance: 88))
        XCTAssertEqual(vm.onboardingStep, .grabSuccess)

        vm.handleOnboardingEvent(.continueTapped)
        XCTAssertEqual(vm.onboardingStep, .zoomTutorial)

        vm.handleOnboardingEvent(.tutorialItemScaled(scale: 1.65))
        XCTAssertEqual(vm.onboardingStep, .zoomSuccess)

        vm.handleOnboardingEvent(.continueTapped)
        XCTAssertEqual(vm.onboardingStep, .shrinkTutorial)

        vm.handleOnboardingEvent(.tutorialItemScaled(scale: 0.25))
        XCTAssertEqual(vm.onboardingStep, .shrinkHold)

        vm.handleOnboardingEvent(.vanishHoldCompleted)
        XCTAssertEqual(vm.onboardingStep, .virtualCameraPrompt)
        XCTAssertEqual(store.layers.count, 0) // Tutorial card should be removed
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
        vm.handleOnboardingEvent(.tutorialItemMoved(distance: 88))
        vm.handleOnboardingEvent(.continueTapped)
        vm.handleOnboardingEvent(.tutorialItemScaled(scale: 1.65))
        vm.handleOnboardingEvent(.continueTapped)

        let exp = expectation(description: "vanish hold completes")
        vm.handleOnboardingEvent(.tutorialItemScaled(scale: 0.25))
        XCTAssertEqual(vm.onboardingStep, .shrinkHold)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            XCTAssertEqual(vm.onboardingStep, .virtualCameraPrompt)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.5)
    }

    func testViewModelOnboardingVanishViaDeleteKeyOrOutsideDrag() {
        let store = SceneStore()
        let vm = PreviewViewModel(permissionService: FakeCameraPermissionService(status: .authorized), sceneStore: store)
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")

        vm.handleOnboardingEvent(.showMeTapped)
        vm.handleOnboardingEvent(.tutorialItemMoved(distance: 88))
        vm.handleOnboardingEvent(.continueTapped)
        vm.handleOnboardingEvent(.tutorialItemScaled(scale: 1.65))
        vm.handleOnboardingEvent(.continueTapped)

        XCTAssertEqual(vm.onboardingStep, .shrinkTutorial)
        XCTAssertEqual(store.layers.count, 1)

        // Remove tutorial card directly from store (simulates drag-outside or delete)
        if let tutorial = store.layers.first(where: { $0.kind == .tutorial }) {
            store.removeLayer(withID: tutorial.id, reason: "manual")
        }

        XCTAssertEqual(vm.onboardingStep, .virtualCameraPrompt)
    }
}
