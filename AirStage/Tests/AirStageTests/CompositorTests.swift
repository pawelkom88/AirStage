import XCTest
import CoreGraphics
@testable import AirStage

final class CompositorTests: XCTestCase {

    // MARK: - Frame snapshot

    func testCompositorReceivesCameraFrameAndLayerSnapshot() {
        let store = SceneStore()
        _ = store.addNote(title: "Note 1", position: CGPoint(x: 100, y: 100), size: CGSize(width: 120, height: 80))
        _ = store.addImage(title: "Photo", position: CGPoint(x: 300, y: 200), size: CGSize(width: 200, height: 150))

        let compositor = Compositor(sceneStore: store, outputSize: CGSize(width: 1280, height: 720))

        let frame = compositor.snapshot(cameraFrameID: "cam-001")

        XCTAssertEqual(frame.cameraFrameID, "cam-001")
        XCTAssertEqual(frame.outputSize, CGSize(width: 1280, height: 720))
        XCTAssertEqual(frame.layerEntries.count, 2)
    }

    func testCompositorOrdersLayersByZIndex() {
        let store = SceneStore()
        let id1 = store.addNote(title: "Bottom", position: .zero, size: CGSize(width: 100, height: 100)).layerID!
        let id2 = store.addNote(title: "Middle", position: .zero, size: CGSize(width: 100, height: 100)).layerID!
        let id3 = store.addNote(title: "Top", position: .zero, size: CGSize(width: 100, height: 100)).layerID!

        // Promote id1 to highest zIndex
        store.selectLayer(id1)

        let compositor = Compositor(sceneStore: store, outputSize: CGSize(width: 640, height: 480))
        let frame = compositor.snapshot(cameraFrameID: "cam-002")

        XCTAssertEqual(frame.layerEntries.count, 3)

        // After selecting id1, zIndex order is: id2 (lowest), id3 (middle), id1 (highest)
        XCTAssertEqual(frame.layerEntries[0].layerID, id2)
        XCTAssertEqual(frame.layerEntries[1].layerID, id3)
        XCTAssertEqual(frame.layerEntries[2].layerID, id1)
    }

    func testCompositorProducesOutputFrameMetadata() {
        let store = SceneStore()
        _ = store.addNote(title: "Note", position: CGPoint(x: 320, y: 240), size: CGSize(width: 150, height: 100))

        let compositor = Compositor(sceneStore: store, outputSize: CGSize(width: 1920, height: 1080))
        let frame = compositor.snapshot(cameraFrameID: "cam-003")

        XCTAssertEqual(frame.outputSize, CGSize(width: 1920, height: 1080))
        XCTAssertFalse(frame.timestamp.isEmpty)

        let entry = frame.layerEntries.first!
        XCTAssertEqual(entry.kind, .note)
        XCTAssertEqual(entry.position, CGPoint(x: 320, y: 240))
        XCTAssertEqual(entry.size, CGSize(width: 150, height: 100))
    }

    func testCompositorExcludesRemovedLayers() {
        let store = SceneStore()
        let id1 = store.addNote(title: "Visible", position: .zero, size: CGSize(width: 100, height: 100)).layerID!
        let id2 = store.addNote(title: "Being removed", position: .zero, size: CGSize(width: 100, height: 100)).layerID!

        // Arm id2 for removal by dragging far outside
        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
        store.dragLayer(withID: id2, to: CGPoint(x: -200, y: -200), sceneBounds: bounds)

        let compositor = Compositor(sceneStore: store, outputSize: CGSize(width: 640, height: 480))
        let frame = compositor.snapshot(cameraFrameID: "cam-004")

        // Only the non-removal-armed layer should appear
        XCTAssertEqual(frame.layerEntries.count, 1)
        XCTAssertEqual(frame.layerEntries[0].layerID, id1)
    }

    func testCompositorSnapshotWithEmptyScene() {
        let store = SceneStore()
        let compositor = Compositor(sceneStore: store, outputSize: CGSize(width: 640, height: 480))
        let frame = compositor.snapshot(cameraFrameID: "cam-empty")

        XCTAssertEqual(frame.cameraFrameID, "cam-empty")
        XCTAssertTrue(frame.layerEntries.isEmpty)
        XCTAssertEqual(frame.outputSize, CGSize(width: 640, height: 480))
    }
}
