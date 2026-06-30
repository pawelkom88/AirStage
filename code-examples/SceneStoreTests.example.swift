import XCTest
@testable import AirStage

final class SceneStoreTests: XCTestCase {
    func testCannotExceedSixTotalLayers() {
        let store = SceneStore()

        for index in 0..<SceneLimits.maxTotalLayers {
            XCTAssertTrue(store.addNote(title: "Note \(index)").isSuccess)
        }

        let result = store.addNote(title: "Overflow")
        XCTAssertFalse(result.isSuccess)
        XCTAssertEqual(store.layers.count, SceneLimits.maxTotalLayers)
    }

    func testSelectingLayerRaisesZIndex() {
        let store = SceneStore()
        let first = store.addNote(title: "First").layerID!
        let second = store.addNote(title: "Second").layerID!

        store.selectLayer(first)

        let firstLayer = store.layer(withID: first)!
        let secondLayer = store.layer(withID: second)!
        XCTAssertGreaterThan(firstLayer.zIndex, secondLayer.zIndex)
    }

    func testReleasingOutsideRemovesLayer() {
        let store = SceneStore()
        let id = store.addNote(title: "Throw me away").layerID!
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)

        store.endDrag(layerID: id, center: CGPoint(x: 1000, y: 300), sceneBounds: bounds)

        XCTAssertNil(store.layer(withID: id))
    }
}

extension SceneStoreTests {
    func testStartingOnboardingAddsOneTutorialLayer() {
        let store = SceneStore()

        let result = store.addTutorialCard(title: "Grab me")

        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(store.layers.count, 1)
        XCTAssertEqual(store.layers.first?.kind, .tutorial)
    }

    func testTutorialLayerUsesNormalSelectionAndRemovalRules() {
        let store = SceneStore()
        let id = store.addTutorialCard(title: "Grab me").layerID!
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)

        store.selectLayer(id)
        XCTAssertEqual(store.layer(withID: id)?.isSelected, true)

        store.endDrag(layerID: id, center: CGPoint(x: 1000, y: 300), sceneBounds: bounds)
        XCTAssertNil(store.layer(withID: id))
    }
}
