import XCTest
import CoreGraphics
@testable import AirStage

final class GestureLayerControllerTests: XCTestCase {
    private let sceneBounds = CGRect(x: 0, y: 0, width: 640, height: 480)

    func testPinchBeginSelectsTopLayerAtGesturePoint() {
        let store = SceneStore()
        let bottom = store.addNote(title: "Bottom", position: CGPoint(x: 200, y: 200), size: CGSize(width: 160, height: 120)).layerID!
        let top = store.addImage(title: "Top", position: CGPoint(x: 200, y: 200), size: CGSize(width: 160, height: 120)).layerID!
        var controller = GestureLayerController(sceneStore: store, sceneBounds: sceneBounds)

        controller.handle(.pinchBegan(at: CGPoint(x: 200, y: 200)), handControlEnabled: true)

        XCTAssertFalse(store.layer(withID: bottom)?.isSelected ?? true)
        XCTAssertTrue(store.layer(withID: top)?.isSelected ?? false)
    }

    func testPinchMoveUpdatesGrabbedLayerPosition() {
        let store = SceneStore()
        let id = store.addNote(title: "Move me", position: CGPoint(x: 160, y: 160), size: CGSize(width: 120, height: 100)).layerID!
        var controller = GestureLayerController(sceneStore: store, sceneBounds: sceneBounds)

        controller.handle(.pinchBegan(at: CGPoint(x: 160, y: 160)), handControlEnabled: true)
        controller.handle(.pinchMoved(to: CGPoint(x: 260, y: 220)), handControlEnabled: true)

        XCTAssertEqual(store.layer(withID: id)?.position, CGPoint(x: 260, y: 220))
    }

    func testPinchEndReleasesLayer() {
        let store = SceneStore()
        let id = store.addNote(title: "Release me", position: CGPoint(x: 120, y: 120), size: CGSize(width: 120, height: 100)).layerID!
        var controller = GestureLayerController(sceneStore: store, sceneBounds: sceneBounds)

        controller.handle(.pinchBegan(at: CGPoint(x: 120, y: 120)), handControlEnabled: true)
        controller.handle(.pinchMoved(to: CGPoint(x: 240, y: 200)), handControlEnabled: true)
        controller.handle(.pinchEnded, handControlEnabled: true)
        controller.handle(.pinchMoved(to: CGPoint(x: 320, y: 260)), handControlEnabled: true)

        XCTAssertEqual(store.layer(withID: id)?.position, CGPoint(x: 240, y: 200))
    }

    func testHandControlDisabledIgnoresPinchEvents() {
        let store = SceneStore()
        let id = store.addNote(title: "Ignore me", position: CGPoint(x: 120, y: 120), size: CGSize(width: 120, height: 100)).layerID!
        var controller = GestureLayerController(sceneStore: store, sceneBounds: sceneBounds)

        controller.handle(.pinchBegan(at: CGPoint(x: 120, y: 120)), handControlEnabled: false)
        controller.handle(.pinchMoved(to: CGPoint(x: 300, y: 300)), handControlEnabled: false)

        XCTAssertFalse(store.layer(withID: id)?.isSelected ?? true)
        XCTAssertEqual(store.layer(withID: id)?.position, CGPoint(x: 120, y: 120))
    }

    func testHandFarFromCardAfterResizeDoesNotGrabCard() {
        let store = SceneStore()
        _ = store.addNote(
            title: "Sticky",
            position: CGPoint(x: 900, y: 500),
            size: CGSize(width: 150, height: 150)
        )

        var controller = GestureLayerController(
            sceneStore: store,
            sceneBounds: CGRect(x: 0, y: 0, width: 1200, height: 800)
        )

        controller.handle(
            .pinchBegan(at: CGPoint(x: 200, y: 100)),
            handControlEnabled: true
        )

        XCTAssertNil(controller.currentGrabbedLayerID)
    }

    func testHandOnVisibleCardAfterResizeCanGrabCard() {
        let store = SceneStore()
        let result = store.addNote(
            title: "Sticky",
            position: CGPoint(x: 900, y: 500),
            size: CGSize(width: 150, height: 150)
        )

        let id = try! XCTUnwrap(result.layerID)

        var controller = GestureLayerController(
            sceneStore: store,
            sceneBounds: CGRect(x: 0, y: 0, width: 1200, height: 800)
        )

        controller.handle(
            .pinchBegan(at: CGPoint(x: 900, y: 500)),
            handControlEnabled: true
        )

        XCTAssertEqual(controller.currentGrabbedLayerID, id)
    }
}
