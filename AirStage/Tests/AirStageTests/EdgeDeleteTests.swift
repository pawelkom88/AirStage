import XCTest
@testable import AirStage

@MainActor
final class EdgeDeleteTests: XCTestCase {

    func testEdgeDeleteBeginsHoveringWhenLayerEntersLeftZone() {
        let controller = EdgeDeleteController(configuration: .init())

        controller.updateDraggedLayer(
            id: UUID(),
            frame: CGRect(x: 40, y: 200, width: 120, height: 120),
            sceneBounds: CGRect(x: 0, y: 0, width: 800, height: 600),
            isOnboardingCompleted: true,
            isTutorialLayer: false,
            onDeleteReady: { _, _ in XCTFail("Should not delete immediately") }
        )

        guard case .hovering(let side, _, _) = controller.state else {
            return XCTFail("Expected hovering state")
        }

        XCTAssertEqual(side, .left)
    }

    func testEdgeDeleteDoesNotStartDuringOnboarding() {
        let controller = EdgeDeleteController()

        controller.updateDraggedLayer(
            id: UUID(),
            frame: CGRect(x: 20, y: 200, width: 120, height: 120),
            sceneBounds: CGRect(x: 0, y: 0, width: 800, height: 600),
            isOnboardingCompleted: false,
            isTutorialLayer: false,
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
            isOnboardingCompleted: true,
            isTutorialLayer: true,
            onDeleteReady: { _, _ in XCTFail("Should not delete tutorial layer") }
        )

        XCTAssertEqual(controller.state, .idle)
    }

    func testEdgeDeleteCancelsWhenLayerLeavesZone() {
        let controller = EdgeDeleteController()
        let id = UUID()
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)

        controller.updateDraggedLayer(
            id: id,
            frame: CGRect(x: 20, y: 200, width: 120, height: 120),
            sceneBounds: bounds,
            isOnboardingCompleted: true,
            isTutorialLayer: false,
            onDeleteReady: { _, _ in XCTFail("Should not delete") }
        )

        controller.updateDraggedLayer(
            id: id,
            frame: CGRect(x: 300, y: 200, width: 120, height: 120),
            sceneBounds: bounds,
            isOnboardingCompleted: true,
            isTutorialLayer: false,
            onDeleteReady: { _, _ in XCTFail("Should not delete") }
        )

        XCTAssertEqual(controller.state, .idle)
    }

    func testEdgeDeleteBeginsHoveringWhenLayerEntersRightZone() {
        let controller = EdgeDeleteController()
        let id = UUID()

        controller.updateDraggedLayer(
            id: id,
            frame: CGRect(x: 720, y: 200, width: 120, height: 120),
            sceneBounds: CGRect(x: 0, y: 0, width: 800, height: 600),
            isOnboardingCompleted: true,
            isTutorialLayer: false,
            onDeleteReady: { _, _ in XCTFail("Should not delete immediately") }
        )

        guard case .hovering(let side, _, _) = controller.state else {
            return XCTFail("Expected hovering state")
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
            isOnboardingCompleted: true,
            isTutorialLayer: false,
            onDeleteReady: { _, _ in XCTFail("Should not delete immediately") }
        )

        guard case .hovering(let side, _, _) = controller.state else {
            return XCTFail("Expected hovering on resized right edge")
        }

        XCTAssertEqual(side, .right)
    }

    func testEdgeDeleteTransitionsToArmedAndDeletesAsync() async throws {
        var config = EdgeDeleteController.Configuration()
        config.revealDelay = 0.005
        config.deleteDelayAfterReveal = 0.005
        
        let controller = EdgeDeleteController(configuration: config)
        let id = UUID()
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
        
        let expectation = XCTestExpectation(description: "Delete callback fired")
        
        await controller.updateDraggedLayer(
            id: id,
            frame: CGRect(x: 20, y: 200, width: 120, height: 120),
            sceneBounds: bounds,
            isOnboardingCompleted: true,
            isTutorialLayer: false,
            onDeleteReady: { deletedId, side in
                XCTAssertEqual(deletedId, id)
                XCTAssertEqual(side, .left)
                expectation.fulfill()
            }
        )
        
        let state = await controller.state
        guard case .hovering = state else {
            return XCTFail("Expected hovering state, got \(state)")
        }
        
        // Wait for timers to fire
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        let finalState = await controller.state
        guard case .armed = finalState else {
            return XCTFail("Expected armed state, got \(finalState)")
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testEdgeDeleteForceArmAndForceDeleteHelpers() {
        let controller = EdgeDeleteController()
        let id = UUID()
        
        controller.forceArmForTesting(id: id, side: .left)
        XCTAssertEqual(controller.state, .armed(side: .left, layerID: id, armedAt: controller.state.enteredAt ?? Date()))
        
        var callbackFired = false
        controller.forceDeleteReadyForTesting(id: id, side: .right) { deletedId, side in
            XCTAssertEqual(deletedId, id)
            XCTAssertEqual(side, .right)
            callbackFired = true
        }
        XCTAssertTrue(callbackFired)
        XCTAssertEqual(controller.state, .armed(side: .right, layerID: id, armedAt: controller.state.enteredAt ?? Date()))
    }

    func testVMIntegratesWithEdgeDeleteController() {
        let store = SceneStore()
        let vm = PreviewViewModel(
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
        
        // Update to trigger hovering
        vmCompleted.updateEdgeDeleteForDraggedLayer(layer)
        
        guard case .hovering(let side, let layerID, _) = vmCompleted.edgeDeleteState else {
            return XCTFail("Expected hovering state, got \(vmCompleted.edgeDeleteState)")
        }
        XCTAssertEqual(side, .left)
        XCTAssertEqual(layerID, id)
        
        // Cancel
        vmCompleted.cancelEdgeDeleteIfNeeded()
        XCTAssertEqual(vmCompleted.edgeDeleteState, .idle)
    }

    func testVMOnboardingGatingForEdgeDelete() {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        let store = SceneStore()
        // Onboarding is NOT completed by default
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
        
        // Unclamped scenario
        let cardFrameUnclamped = CGRect(x: 40, y: 200, width: 120, height: 120) // midY = 260
        let posUnclampedLeft = EdgeDeleteState.badgePosition(side: .left, cardFrame: cardFrameUnclamped, sceneBounds: sceneBounds)
        XCTAssertEqual(posUnclampedLeft.y, 260, "Should use draggedCardFrame.midY")
        XCTAssertEqual(posUnclampedLeft.x, sceneBounds.minX + 56)
        
        let posUnclampedRight = EdgeDeleteState.badgePosition(side: .right, cardFrame: cardFrameUnclamped, sceneBounds: sceneBounds)
        XCTAssertEqual(posUnclampedRight.x, sceneBounds.maxX - 56)
        
        // Clamped top scenario
        let cardFrameTop = CGRect(x: 40, y: -50, width: 120, height: 120) // midY = 10
        let posTop = EdgeDeleteState.badgePosition(side: .left, cardFrame: cardFrameTop, sceneBounds: sceneBounds)
        XCTAssertEqual(posTop.y, 60, "Should clamp to sceneBounds.minY + 60")
        
        // Clamped bottom scenario
        let cardFrameBottom = CGRect(x: 40, y: 600, width: 120, height: 120) // midY = 660
        let posBottom = EdgeDeleteState.badgePosition(side: .left, cardFrame: cardFrameBottom, sceneBounds: sceneBounds)
        XCTAssertEqual(posBottom.y, 540, "Should clamp to sceneBounds.maxY - 60")
    }
}

private extension EdgeDeleteState {
    var enteredAt: Date? {
        switch self {
        case .hovering(_, _, let date): return date
        case .armed(_, _, let date): return date
        default: return nil
        }
    }
}
