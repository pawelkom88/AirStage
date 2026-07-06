import XCTest
import CoreGraphics
@testable import AirStage

final class SnapToGridTests: XCTestCase {

    // MARK: - Pure geometry

    func testSnapToGridRoundsLayerPositionWhenEnabled() {
        // Grid size is 20pt. Position (53, 67) should snap to (60, 60).
        let pos = CGPoint(x: 53, y: 67)
        let snapped = SceneGeometry.snapToGrid(pos)
        XCTAssertEqual(snapped.x, 60, accuracy: 0.01)
        XCTAssertEqual(snapped.y, 60, accuracy: 0.01)

        // Position exactly on grid stays put
        let pos2 = CGPoint(x: 100, y: 200)
        let snapped2 = SceneGeometry.snapToGrid(pos2)
        XCTAssertEqual(snapped2.x, 100, accuracy: 0.01)
        XCTAssertEqual(snapped2.y, 200, accuracy: 0.01)

        // Position (39, 11) rounds to (40, 20) since 39 rounds to 40, 11 rounds to 20
        let pos3 = CGPoint(x: 39, y: 11)
        let snapped3 = SceneGeometry.snapToGrid(pos3)
        XCTAssertEqual(snapped3.x, 40, accuracy: 0.01)
        XCTAssertEqual(snapped3.y, 20, accuracy: 0.01)
    }

    func testSnapToGridDoesNotChangePositionWhenDisabled() {
        let store = SceneStore()
        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
        _ = store.addNote(title: "A", position: CGPoint(x: 320, y: 240), size: CGSize(width: 150, height: 150))
        let id = store.layers[0].id

        // endDrag with snapToGrid=false -> position should be clamped but NOT snapped
        store.endDrag(layerID: id, center: CGPoint(x: 53, y: 67), sceneBounds: bounds, snapToGrid: false)
        XCTAssertEqual(store.layers[0].position.x, 53, accuracy: 0.01)
        XCTAssertEqual(store.layers[0].position.y, 67, accuracy: 0.01)
    }

    func testSnapToGridAppliesOnlyAfterDragEnd() {
        let store = SceneStore()
        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
        _ = store.addNote(title: "B", position: CGPoint(x: 320, y: 240), size: CGSize(width: 150, height: 150))
        let id = store.layers[0].id

        // During drag (dragLayer) — position should NOT snap even with snap conceptually enabled
        store.dragLayer(withID: id, to: CGPoint(x: 53, y: 67), sceneBounds: bounds)
        XCTAssertEqual(store.layers[0].position.x, 53, accuracy: 0.01)
        XCTAssertEqual(store.layers[0].position.y, 67, accuracy: 0.01)

        // On endDrag with snapToGrid=true — position should snap
        store.endDrag(layerID: id, center: CGPoint(x: 53, y: 67), sceneBounds: bounds, snapToGrid: true)
        XCTAssertEqual(store.layers[0].position.x, 60, accuracy: 0.01)
        XCTAssertEqual(store.layers[0].position.y, 60, accuracy: 0.01)
    }
}
