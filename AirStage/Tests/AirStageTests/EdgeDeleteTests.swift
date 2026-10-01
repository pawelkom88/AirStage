import XCTest
@testable import AirStage

@MainActor
final class EdgeDeleteTests: XCTestCase {

    func testEdgeDeleteBeginsArmingWhenLayerEntersLeftZone() {
        let controller = EdgeDeleteController(configuration: .init())

        controller.updateDraggedLayer(
            id: UUID(),
            frame: CGRect(x: 40, y: 200, width: 120, height: 120),
            sceneBounds: CGRect(x: 0, y: 0, width: 800, height: 600),
            isAllowed: true,
            onDeleteReady: { _, _ in XCTFail("Should not delete immediately") }
        )

        guard case .arming(let side, _, _) = controller.state else {
            return XCTFail("Expected arming state")
        }

        XCTAssertEqual(side, .left)
    }

    func testEdgeDeleteDoesNotStartDuringOnboarding() {
        let controller = EdgeDeleteController()

        controller.updateDraggedLayer(
            id: UUID(),
            frame: CGRect(x: 20, y: 200, width: 120, height: 120),
            sceneBounds: CGRect(x: 0, y: 0, width: 800, height: 600),
            isAllowed: false,
            onDeleteReady: { _, _ in XCTFail("Should not delete during onboarding") }
        )

        XCTAssertEqual(controller.state, .idle)
    }

    func testEdgeDeleteDoesNotStartForTutorialLayer() {
        let controller = EdgeDeleteController()

        controller.updateDraggedLayer(
            id: UUID(),
            frame: CGRect(x: 20, y: 200, width: 120, height: 120),
            sceneBounds: CGRect(x: 0, y: 0, width: 800, height: 600),
            isAllowed: false,
            onDeleteReady: { _, _ in XCTFail("Should not delete tutorial layer") }
        )

        XCTAssertEqual(controller.state, .idle)
    }

    func testEdgeDeleteJitterTolerance() async throws {
        var config = EdgeDeleteController.Configuration()
        config.jitterTolerance = 0.05
        let controller = EdgeDeleteController(configuration: config)
        let id = UUID()
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)

        controller.updateDraggedLayer(
            id: id,
            frame: CGRect(x: 20, y: 200, width: 120, height: 120),
            sceneBounds: bounds,
            isAllowed: true,
            onDeleteReady: { _, _ in XCTFail("Should not delete") }
        )

        XCTAssertTrue(controller.state.isArmed)

        // Move out of bounds briefly
        controller.updateDraggedLayer(
            id: id,
            frame: CGRect(x: 300, y: 200, width: 120, height: 120),
            sceneBounds: bounds,
            isAllowed: true,
            onDeleteReady: { _, _ in XCTFail("Should not delete") }
        )

        XCTAssertTrue(controller.state.isArmed, "State should not drop immediately because of jitter tolerance")

        try await Task.sleep(nanoseconds: 100_000_000) // wait longer than 0.05s tolerance

        XCTAssertEqual(controller.state, .idle, "Should be idle after jitter tolerance expires")
    }

    func testEdgeDeleteBeginsArmingWhenLayerEntersRightZone() {
        let controller = EdgeDeleteController()
        let id = UUID()

        controller.updateDraggedLayer(
            id: id,
            frame: CGRect(x: 720, y: 200, width: 120, height: 120),
            sceneBounds: CGRect(x: 0, y: 0, width: 800, height: 600),
            isAllowed: true,
            onDeleteReady: { _, _ in XCTFail("Should not delete immediately") }
        )

        guard case .arming(let side, _, _) = controller.state else {
            return XCTFail("Expected arming state")
        }

        XCTAssertEqual(side, .right)
    }

    func testEdgeDeleteUsesCurrentSceneBoundsAfterResize() {
        let controller = EdgeDeleteController()
        let id = UUID()

        controller.updateDraggedLayer(
            id: id,
            frame: CGRect(x: 1120, y: 200, width: 120, height: 120),
            sceneBounds: CGRect(x: 0, y: 0, width: 1200, height: 800),
            isAllowed: true,
            onDeleteReady: { _, _ in XCTFail("Should not delete immediately") }
        )

        guard case .arming(let side, _, _) = controller.state else {
            return XCTFail("Expected arming on resized right edge")
        }

        XCTAssertEqual(side, .right)
    }

    func testEdgeDeleteDeletesAsync() async throws {
        var config = EdgeDeleteController.Configuration()
        config.deleteDelay = 0.01
        
        let controller = EdgeDeleteController(configuration: config)
        let id = UUID()
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
        
        let expectation = XCTestExpectation(description: "Delete callback fired")
        
        controller.updateDraggedLayer(
            id: id,
            frame: CGRect(x: 20, y: 200, width: 120, height: 120),
            sceneBounds: bounds,
            isAllowed: true,
            onDeleteReady: { deletedId, side in
                XCTAssertEqual(deletedId, id)
                XCTAssertEqual(side, .left)
                expectation.fulfill()
            }
        )
        
        let state = controller.state
        guard case .arming = state else {
            return XCTFail("Expected arming state, got \(state)")
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testEdgeDeleteForceArmAndForceDeleteHelpers() {
        let controller = EdgeDeleteController()
        let id = UUID()
        
        controller.forceArmForTesting(id: id, side: .left)
        XCTAssertEqual(controller.state, .arming(side: .left, layerID: id, startedAt: controller.state.enteredAt ?? Date()))
        
        var callbackFired = false
        controller.forceDeleteReadyForTesting(id: id, side: .right) { deletedId, side in
            XCTAssertEqual(deletedId, id)
            XCTAssertEqual(side, .right)
            callbackFired = true
        }
        XCTAssertTrue(callbackFired)
        XCTAssertEqual(controller.state, .arming(side: .right, layerID: id, startedAt: controller.state.enteredAt ?? Date()))
    }

    func testVMIntegratesWithEdgeDeleteController() {
        let store = SceneStore()
        _ = PreviewViewModel(
            permissionService: FakeCameraPermissionService(status: .authorized),
            sceneStore: store
        )
        
        // Complete onboarding to enable edge delete
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        let vmCompleted = PreviewViewModel(
            permissionService: FakeCameraPermissionService(status: .authorized),
            sceneStore: store
        )
        
        let result = store.addNote(
            title: "Draggable Note",
            position: CGPoint(x: 40, y: 200),
            size: CGSize(width: 120, height: 120)
        )
        guard case .success(let id) = result, let layer = store.layer(withID: id) else {
            return XCTFail("Failed to add note")
        }
        
        XCTAssertEqual(vmCompleted.edgeDeleteState, .idle)
        
        vmCompleted.updateEdgeDeleteForDraggedLayer(layer)
        
        guard case .arming(let side, let layerID, _) = vmCompleted.edgeDeleteState else {
            return XCTFail("Expected arming state, got \(vmCompleted.edgeDeleteState)")
        }
        XCTAssertEqual(side, .left)
        XCTAssertEqual(layerID, id)
        
        vmCompleted.cancelEdgeDeleteIfNeeded()
        XCTAssertEqual(vmCompleted.edgeDeleteState, .idle)
    }

    func testVMOnboardingGatingForEdgeDelete() {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        let store = SceneStore()
        let vm = PreviewViewModel(
            permissionService: FakeCameraPermissionService(status: .authorized),
            sceneStore: store
        )
        
        let result = store.addNote(
            title: "Draggable Note",
            position: CGPoint(x: 40, y: 200),
            size: CGSize(width: 120, height: 120)
        )
        guard case .success(let id) = result, let layer = store.layer(withID: id) else {
            return XCTFail("Failed to add note")
        }
        
        vm.updateEdgeDeleteForDraggedLayer(layer)
        XCTAssertEqual(vm.edgeDeleteState, .idle, "Should gate edge delete during onboarding")
    }

    func testVMTutorialCardGatingForEdgeDelete() {
        let store = SceneStore()
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        let vm = PreviewViewModel(
            permissionService: FakeCameraPermissionService(status: .authorized),
            sceneStore: store
        )
        
        let result = store.addTutorialCard(
            title: "Tutorial card",
            position: CGPoint(x: 40, y: 200),
            size: CGSize(width: 120, height: 120)
        )
        guard case .success(let id) = result, let layer = store.layer(withID: id) else {
            return XCTFail("Failed to add tutorial card")
        }
        
        vm.updateEdgeDeleteForDraggedLayer(layer)
        XCTAssertEqual(vm.edgeDeleteState, .idle, "Should gate edge delete for tutorial cards")
    }

    func testBadgePositioningUsesDraggedCardFrameMidYClamped() {
        let sceneBounds = CGRect(x: 0, y: 0, width: 800, height: 600)
        
        let cardFrameUnclamped = CGRect(x: 40, y: 200, width: 120, height: 120)
        let posUnclampedLeft = EdgeDeleteState.badgePosition(side: .left, cardFrame: cardFrameUnclamped, sceneBounds: sceneBounds)
        XCTAssertEqual(posUnclampedLeft.y, 260)
        XCTAssertEqual(posUnclampedLeft.x, sceneBounds.minX + 56)
        
        let posUnclampedRight = EdgeDeleteState.badgePosition(side: .right, cardFrame: cardFrameUnclamped, sceneBounds: sceneBounds)
        XCTAssertEqual(posUnclampedRight.x, sceneBounds.maxX - 56)
        
        let cardFrameTop = CGRect(x: 40, y: -50, width: 120, height: 120)
        let posTop = EdgeDeleteState.badgePosition(side: .left, cardFrame: cardFrameTop, sceneBounds: sceneBounds)
        XCTAssertEqual(posTop.y, 60)
        
        let cardFrameBottom = CGRect(x: 40, y: 600, width: 120, height: 120)
        let posBottom = EdgeDeleteState.badgePosition(side: .left, cardFrame: cardFrameBottom, sceneBounds: sceneBounds)
        XCTAssertEqual(posBottom.y, 540)
    }

    func testCommitProgressClampsToOne() {
        let startedAt = Date().addingTimeInterval(-5.0)
        let state = EdgeDeleteState.arming(side: .left, layerID: UUID(), startedAt: startedAt)
        let progress = commitProgress(for: state, now: Date(), deleteDelay: 1.0)
        XCTAssertEqual(progress, 1.0)
    }
}

private extension EdgeDeleteState {
    var enteredAt: Date? {
        switch self {
        case .arming(_, _, let date): return date
        default: return nil
        }
    }
}
