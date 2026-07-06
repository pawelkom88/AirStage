import XCTest
import CoreGraphics
@testable import AirStage

final class SceneStoreTests: XCTestCase {

    func testCanAddLayerWhenUnderLimit() {
        let store = SceneStore()
        let result = store.addNote(title: "Under Limit Note")
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(result.layerID)
        XCTAssertEqual(store.layers.count, 1)
        XCTAssertEqual(store.layers.first?.title, "Under Limit Note")
    }

    func testCannotExceedSixTotalLayers() {
        let store = SceneStore()
        for i in 0..<4 {
            XCTAssertTrue(store.addNote(title: "Note \(i)").isSuccess)
        }
        for i in 0..<2 {
            XCTAssertTrue(store.addImage(title: "Image \(i)").isSuccess)
        }
        
        let result = store.addNote(title: "Overflow Note")
        XCTAssertFalse(result.isSuccess)
        XCTAssertEqual(result, .failure(.sceneFull(totalCount: 6)))
        XCTAssertEqual(store.layers.count, 6)
    }

    func testCannotAddMoreThanOneWindowCaptureLayer() {
        let store = SceneStore()
        let result1 = store.addWindowCapture(title: "Window 1")
        XCTAssertTrue(result1.isSuccess)
        
        let result2 = store.addWindowCapture(title: "Window 2")
        XCTAssertFalse(result2.isSuccess)
        XCTAssertEqual(result2, .failure(.kindLimitExceeded(kind: .windowCapture)))
        XCTAssertEqual(store.layers.count, 1)
    }

    func testCannotAddMoreThanThreeImageLayers() {
        let store = SceneStore()
        for i in 0..<3 {
            let result = store.addImage(title: "Image \(i)")
            XCTAssertTrue(result.isSuccess)
        }
        
        let result = store.addImage(title: "Image 4")
        XCTAssertFalse(result.isSuccess)
        XCTAssertEqual(result, .failure(.kindLimitExceeded(kind: .image)))
        XCTAssertEqual(store.layers.count, 3)
    }

    func testCannotAddMoreThanFourNoteLayers() {
        let store = SceneStore()
        for i in 0..<4 {
            let result = store.addNote(title: "Note \(i)")
            XCTAssertTrue(result.isSuccess)
        }
        
        let result = store.addNote(title: "Note 5")
        XCTAssertFalse(result.isSuccess)
        XCTAssertEqual(result, .failure(.kindLimitExceeded(kind: .note)))
        XCTAssertEqual(store.layers.count, 4)
    }

    func testSceneFullOffersReplaceOldestOrCancel() {
        let store = SceneStore()
        // Fill scene with 6 layers to get to 6 layers total:
        // We can add 4 notes and 2 images.
        for i in 0..<4 {
            XCTAssertTrue(store.addNote(title: "Note \(i)").isSuccess)
        }
        for i in 0..<2 {
            XCTAssertTrue(store.addImage(title: "Image \(i)").isSuccess)
        }
        XCTAssertEqual(store.layers.count, 6)
        
        // Try to add another image without replaceOldestIfFull -> should fail
        let overflowResult = store.addImage(title: "Overflow Image")
        XCTAssertFalse(overflowResult.isSuccess)
        XCTAssertEqual(overflowResult, .failure(.sceneFull(totalCount: 6)))
        
        // Try to add another image WITH replaceOldestIfFull -> should succeed and remove the oldest layer (Note 0)
        let replaceResult = store.addImage(title: "Replacement Image", replaceOldestIfFull: true)
        XCTAssertTrue(replaceResult.isSuccess)
        XCTAssertEqual(store.layers.count, 6)
        XCTAssertNil(store.layer(withID: store.layers.first(where: { $0.title == "Note 0" })?.id ?? UUID()))
    }

    func testSelectingLayerRaisesZIndex() {
        let store = SceneStore()
        guard let firstID = store.addNote(title: "First").layerID,
              let secondID = store.addNote(title: "Second").layerID else {
            XCTFail("Failed to add layers")
            return
        }
        
        store.selectLayer(firstID)
        
        guard let firstLayer = store.layer(withID: firstID),
              let secondLayer = store.layer(withID: secondID) else {
            XCTFail("Failed to get layers")
            return
        }
        XCTAssertGreaterThan(firstLayer.zIndex, secondLayer.zIndex)
    }

    func testReleasingOutsideRemovesLayer() {
        let store = SceneStore()
        guard let id = store.addNote(title: "Throw Away").layerID else {
            XCTFail("Failed to add layer")
            return
        }
        
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
        // Center is way outside the bounds
        store.endDrag(layerID: id, center: CGPoint(x: 1000, y: 300), sceneBounds: bounds)
        
        XCTAssertNil(store.layer(withID: id))
    }

    func testSelectingLayerMarksOnlyThatLayerSelected() {
        let store = SceneStore()
        guard let id1 = store.addNote(title: "Note 1").layerID,
              let id2 = store.addNote(title: "Note 2").layerID else {
            XCTFail("Failed to add layers")
            return
        }

        store.selectLayer(id1)
        XCTAssertTrue(store.layer(withID: id1)?.isSelected ?? false)
        XCTAssertFalse(store.layer(withID: id2)?.isSelected ?? true)

        store.selectLayer(id2)
        XCTAssertFalse(store.layer(withID: id1)?.isSelected ?? true)
        XCTAssertTrue(store.layer(withID: id2)?.isSelected ?? false)
    }

    func testDeleteRemovesSelectedLayer() {
        let store = SceneStore()
        guard let id = store.addNote(title: "Delete Me").layerID else {
            XCTFail("Failed to add layer")
            return
        }

        store.selectLayer(id)
        store.deleteSelectedLayer()

        XCTAssertNil(store.layer(withID: id))
    }

    func testDeleteWithNoSelectionDoesNothing() {
        let store = SceneStore()
        guard let id = store.addNote(title: "Keep Me").layerID else {
            XCTFail("Failed to add layer")
            return
        }

        store.deleteSelectedLayer()

        XCTAssertNotNil(store.layer(withID: id))
    }

    func testDraggingLayerUpdatesPosition() {
        let store = SceneStore()
        guard let id = store.addNote(title: "Note").layerID else {
            XCTFail("Failed to add layer")
            return
        }

        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
        store.dragLayer(withID: id, to: CGPoint(x: 100, y: 150), sceneBounds: bounds)

        let layer = store.layer(withID: id)
        XCTAssertEqual(layer?.position, CGPoint(x: 100, y: 150))
    }

    func testDraggingLayerKeepsLayerVisibleForNormalDrag() {
        let store = SceneStore()
        let result = store.addNote(title: "Clamped Note", position: CGPoint(x: 320, y: 240), size: CGSize(width: 100, height: 100))
        guard let id = result.layerID else {
            XCTFail("Failed to add layer")
            return
        }

        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
        store.dragLayer(withID: id, to: CGPoint(x: -40, y: -40), sceneBounds: bounds)

        let layerDuring = store.layer(withID: id)
        XCTAssertEqual(layerDuring?.position, CGPoint(x: -40, y: -40))
        XCTAssertEqual(layerDuring?.isBeingRemoved, false)

        store.endDrag(layerID: id, center: CGPoint(x: -40, y: -40), sceneBounds: bounds)

        let layerAfter = store.layer(withID: id)
        XCTAssertEqual(layerAfter?.position.x, -30)
        XCTAssertEqual(layerAfter?.position.y, -30)
    }

    func testDraggingOutsideArmsRemovalState() {
        let store = SceneStore()
        let id = store.addNote(title: "Note", position: CGPoint(x: 320, y: 240), size: CGSize(width: 100, height: 100)).layerID!
        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
        
        store.dragLayer(withID: id, to: CGPoint(x: -80, y: -80), sceneBounds: bounds)
        
        let layer = store.layer(withID: id)
        XCTAssertEqual(layer?.isBeingRemoved, true)
    }

    func testDraggingBackInsideCancelsRemovalState() {
        let store = SceneStore()
        let id = store.addNote(title: "Note", position: CGPoint(x: 320, y: 240), size: CGSize(width: 100, height: 100)).layerID!
        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
        
        store.dragLayer(withID: id, to: CGPoint(x: -80, y: -80), sceneBounds: bounds)
        XCTAssertEqual(store.layer(withID: id)?.isBeingRemoved, true)
        
        store.dragLayer(withID: id, to: CGPoint(x: 100, y: 100), sceneBounds: bounds)
        XCTAssertEqual(store.layer(withID: id)?.isBeingRemoved, false)
    }

    func testReleasingInsideKeepsLayer() {
        let store = SceneStore()
        let id = store.addNote(title: "Note", position: CGPoint(x: 320, y: 240), size: CGSize(width: 100, height: 100)).layerID!
        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
        
        store.endDrag(layerID: id, center: CGPoint(x: 100, y: 100), sceneBounds: bounds)
        XCTAssertNotNil(store.layer(withID: id))
        XCTAssertEqual(store.layer(withID: id)?.position, CGPoint(x: 100, y: 100))
    }

    func testDraggingUnknownLayerDoesNothing() {
        let store = SceneStore()
        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
        store.dragLayer(withID: UUID(), to: CGPoint(x: 100, y: 100), sceneBounds: bounds)
        XCTAssertEqual(store.layers.count, 0)
    }

    func testResizingLayerUpdatesSize() {
        let store = SceneStore()
        guard let id = store.addNote(title: "Note", position: CGPoint(x: 100, y: 100), size: CGSize(width: 150, height: 150)).layerID else {
            XCTFail("Failed to add note")
            return
        }
        
        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
        store.beginResize(withID: id)
        store.resizeLayer(withID: id, size: CGSize(width: 200, height: 180), position: CGPoint(x: 125, y: 115), sceneBounds: bounds)
        store.endResize(withID: id, finalSize: CGSize(width: 200, height: 180))
        
        let layer = store.layer(withID: id)
        XCTAssertEqual(layer?.size, CGSize(width: 200, height: 180))
        XCTAssertEqual(layer?.position, CGPoint(x: 125, y: 115))
    }

    func testResizeDoesNotGoBelowMinimumSize() {
        let store = SceneStore()
        guard let id = store.addNote(title: "Note", position: CGPoint(x: 100, y: 100), size: CGSize(width: 150, height: 150)).layerID else {
            XCTFail("Failed to add note")
            return
        }
        
        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
        // Trying to resize to 10x10 should clamp to minimum size 80x80
        store.resizeLayer(withID: id, size: CGSize(width: 10, height: 10), position: CGPoint(x: 30, y: 30), sceneBounds: bounds)
        
        let layer = store.layer(withID: id)
        XCTAssertEqual(layer?.size, CGSize(width: 80, height: 80))
    }

    func testResizeKeepsLayerInsidePreviewWhenPossible() {
        let store = SceneStore()
        guard let id = store.addNote(title: "Note", position: CGPoint(x: 100, y: 100), size: CGSize(width: 150, height: 150)).layerID else {
            XCTFail("Failed to add note")
            return
        }
        
        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
        // Resize position way offscreen -> clamped using clampPosition
        store.resizeLayer(withID: id, size: CGSize(width: 100, height: 100), position: CGPoint(x: -500, y: -500), sceneBounds: bounds)
        
        let layer = store.layer(withID: id)
        XCTAssertNotEqual(layer?.position.x, -500)
        XCTAssertNotEqual(layer?.position.y, -500)
        XCTAssertEqual(layer?.position.x, -30) // bounds.minX(0) - 100/2 + 20 = -30
        XCTAssertEqual(layer?.position.y, -30) // bounds.minY(0) - 100/2 + 20 = -30
    }

    func testResizeAllowsShrinkingDuringActiveResize() {
        let store = SceneStore()
        guard let id = store.addNote(title: "Note", position: CGPoint(x: 100, y: 100), size: CGSize(width: 150, height: 150)).layerID else {
            XCTFail("Failed to add note")
            return
        }
        
        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
        store.beginResize(withID: id)
        store.resizeLayer(withID: id, size: CGSize(width: 50, height: 50), position: CGPoint(x: 50, y: 50), sceneBounds: bounds)
        
        let layer = store.layer(withID: id)
        XCTAssertEqual(layer?.size, CGSize(width: 50, height: 50))
    }

    func testEndResizeSnapsSizeBackToStandardMinimum() {
        let store = SceneStore()
        guard let id = store.addNote(title: "Note", position: CGPoint(x: 100, y: 100), size: CGSize(width: 150, height: 150)).layerID else {
            XCTFail("Failed to add note")
            return
        }
        
        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
        store.beginResize(withID: id)
        store.resizeLayer(withID: id, size: CGSize(width: 50, height: 50), position: CGPoint(x: 50, y: 50), sceneBounds: bounds)
        store.endResize(withID: id, finalSize: CGSize(width: 50, height: 50))
        
        let layer = store.layer(withID: id)
        XCTAssertEqual(layer?.size, CGSize(width: 80, height: 80))
    }
}
