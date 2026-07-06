import XCTest
import Foundation
@testable import AirStage

@MainActor
final class IntegrationRegressionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        super.tearDown()
    }

    func testIntegrationAddNoteEditDragRemoveOutside() {
        let store = SceneStore()
        let permission = FakeCameraPermissionService(status: .authorized)
        let vm = PreviewViewModel(permissionService: permission, sceneStore: store)
        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)

        // 1. Add note
        let noteResult = store.addNote(title: "Initial", position: CGPoint(x: 320, y: 240), size: CGSize(width: 150, height: 150))
        XCTAssertTrue(noteResult.isSuccess)
        let id = noteResult.layerID!

        // 2. Edit note text
        store.updateNoteText(layerID: id, text: "Edited Text")
        XCTAssertEqual(store.layer(withID: id)?.title, "Edited Text")

        // 3. Drag note
        store.dragLayer(withID: id, to: CGPoint(x: 100, y: 100), sceneBounds: bounds)
        XCTAssertEqual(store.layer(withID: id)?.position, CGPoint(x: 100, y: 100))

        // 4. Drag outside to remove
        store.endDrag(layerID: id, center: CGPoint(x: 1000, y: 1000), sceneBounds: bounds)
        XCTAssertNil(store.layer(withID: id))
    }

    func testIntegrationAddImageResizeDelete() {
        let store = SceneStore()
        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)

        // 1. Add image
        let imgResult = store.addImage(title: "photo.png", position: CGPoint(x: 320, y: 240), size: CGSize(width: 200, height: 150))
        XCTAssertTrue(imgResult.isSuccess)
        let id = imgResult.layerID!

        // 2. Select image
        store.selectLayer(id)
        XCTAssertTrue(store.layer(withID: id)?.isSelected ?? false)

        // 3. Resize image
        store.beginResize(withID: id)
        store.resizeLayer(withID: id, size: CGSize(width: 300, height: 250), position: CGPoint(x: 320, y: 240), sceneBounds: bounds)
        store.endResize(withID: id, finalSize: CGSize(width: 300, height: 250))
        
        let layer = store.layer(withID: id)
        XCTAssertEqual(layer?.size, CGSize(width: 300, height: 250))

        // 4. Delete selected layer
        store.deleteSelectedLayer()
        XCTAssertNil(store.layer(withID: id))
    }

    func testIntegrationWindowLimitBlocked() {
        let store = SceneStore()
        let importer = WindowCaptureImporter(store: store)

        let result1 = importer.importCapture(title: "Window 1", captureID: "w1")
        XCTAssertTrue(result1.isSuccess)

        let result2 = importer.importCapture(title: "Window 2", captureID: "w2")
        XCTAssertFalse(result2.isSuccess)
        XCTAssertEqual(result2, .failure(.limitExceeded))
    }

    func testIntegrationSettingsResetOnboarding() {
        let store = SettingsStore(defaults: UserDefaults.standard)
        let permission = FakeCameraPermissionService(status: .authorized)
        let sceneStore = SceneStore()
        let vm = PreviewViewModel(permissionService: permission, sceneStore: sceneStore, settingsStore: store)

        // Progress onboarding to completed
        vm.handleOnboardingEvent(.showMeTapped)
        vm.handleOnboardingEvent(.observe(grabbing: true, scale: 1.0))
        vm.handleOnboardingEvent(.continueTapped)
        vm.handleOnboardingEvent(.observe(grabbing: false, scale: 1.0)) // baseline
        for _ in 1...6 { vm.handleOnboardingEvent(.observe(grabbing: false, scale: 1.2)) }
        vm.handleOnboardingEvent(.continueTapped)
        vm.handleOnboardingEvent(.observe(grabbing: false, scale: 1.2)) // baseline
        for _ in 1...6 { vm.handleOnboardingEvent(.observe(grabbing: false, scale: 1.0)) }
        vm.handleOnboardingEvent(.vanishHoldCompleted)
        vm.handleOnboardingEvent(.completionDelayElapsed)
        vm.handleOnboardingEvent(.virtualCameraPromptDismissed)
        XCTAssertEqual(vm.onboardingStep, .completed)

        // Trigger settings reset
        let expectation = self.expectation(description: "Onboarding reset notified")
        let cancel = NotificationCenter.default.publisher(for: .resetOnboardingRequested)
            .sink { _ in
                expectation.fulfill()
            }

        store.resetOnboarding()
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(vm.onboardingStep, .welcome)
        cancel.cancel()
    }

    func testIntegrationDebugOverlayToggle() {
        let store = SettingsStore(defaults: UserDefaults.standard)
        let permission = FakeCameraPermissionService(status: .authorized)
        let sceneStore = SceneStore()
        let vm = PreviewViewModel(permissionService: permission, sceneStore: sceneStore, settingsStore: store)

        // Toggle on
        store.debugOverlay = true
        XCTAssertTrue(vm.isDebugOverlayVisible)

        // Toggle off
        store.debugOverlay = false
        XCTAssertFalse(vm.isDebugOverlayVisible)
    }
}
