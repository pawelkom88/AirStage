import XCTest
@testable import AirStage

final class MenuModelTests: XCTestCase {

    func testMenuContainsPrimaryActions() {
        let model = MenuModel()
        let ids = model.actions.map(\.id)

        XCTAssertTrue(ids.contains(.addNote))
        XCTAssertTrue(ids.contains(.shareImage))
        XCTAssertTrue(ids.contains(.shareWindowOrScreen))
        XCTAssertTrue(ids.contains(.removeLayer))
        XCTAssertTrue(ids.contains(.showPreview))
        XCTAssertTrue(ids.contains(.settings))
        XCTAssertTrue(ids.contains(.quit))
    }

    func testDisabledActionsExposeReasonWhenUnavailable() {
        let model = MenuModel()

        let windowAction = model.actions.first(where: { $0.id == .shareWindowOrScreen })
        XCTAssertNotNil(windowAction)
        if let action = windowAction, !action.isEnabled {
            XCTAssertNotNil(action.disabledReason, "Disabled actions must expose a reason")
        }
    }

    func testAddNoteIsEnabled() {
        let model = MenuModel()
        let action = model.actions.first(where: { $0.id == .addNote })
        XCTAssertNotNil(action)
        XCTAssertTrue(action!.isEnabled)
        XCTAssertNil(action!.disabledReason)
    }

    func testShareImageIsEnabled() {
        let model = MenuModel()
        let action = model.actions.first(where: { $0.id == .shareImage })
        XCTAssertNotNil(action)
        XCTAssertTrue(action!.isEnabled)
        XCTAssertNil(action!.disabledReason)
    }

    func testSettingsIsDisabledWithReason() {
        let model = MenuModel()
        let action = model.actions.first(where: { $0.id == .settings })
        XCTAssertNotNil(action)
        XCTAssertFalse(action!.isEnabled)
        XCTAssertNotNil(action!.disabledReason)
    }

    func testShowPreviewIsEnabled() {
        let model = MenuModel()
        let action = model.actions.first(where: { $0.id == .showPreview })
        XCTAssertNotNil(action)
        XCTAssertTrue(action!.isEnabled)
        XCTAssertNil(action!.disabledReason)
    }

    func testQuitIsEnabled() {
        let model = MenuModel()
        let action = model.actions.first(where: { $0.id == .quit })
        XCTAssertNotNil(action)
        XCTAssertTrue(action!.isEnabled)
        XCTAssertNil(action!.disabledReason)
    }

    func testSelectingShowPreviewEmitsIntent() {
        let model = MenuModel()
        var emittedIntent: MenuIntent?
        model.onIntent = { emittedIntent = $0 }

        model.select(.showPreview)

        XCTAssertEqual(emittedIntent, .showPreview)
    }

    func testSelectingQuitEmitsIntent() {
        let model = MenuModel()
        var emittedIntent: MenuIntent?
        model.onIntent = { emittedIntent = $0 }

        model.select(.quit)

        XCTAssertEqual(emittedIntent, .quit)
    }

    func testSelectingShareImageEmitsIntent() {
        let model = MenuModel()
        var emittedIntent: MenuIntent?
        model.onIntent = { emittedIntent = $0 }

        model.select(.shareImage)

        XCTAssertEqual(emittedIntent, .shareImage)
    }

    func testDisabledActionsDoNotEmitIntents() {
        let model = MenuModel()
        let disabledIDs: [MenuActionID] = [
            .removeLayer, .camera, .settings
        ]

        for id in disabledIDs {
            var emittedIntent: MenuIntent?
            model.onIntent = { emittedIntent = $0 }
            model.select(id)
            XCTAssertNil(emittedIntent, "\(id) must not emit intent when disabled")
        }
    }

    func testRemoveLayerMenuDisabledWhenNoLayersExist() {
        let store = SceneStore()
        let model = MenuModel(sceneStore: store)
        
        let action = model.actions.first(where: { $0.id == .removeLayer })
        XCTAssertNotNil(action)
        XCTAssertFalse(action!.isEnabled)
        XCTAssertEqual(action!.disabledReason, "No layers in scene.")
    }

    func testRemoveLayerMenuListsCurrentLayers() {
        let store = SceneStore()
        let model = MenuModel(sceneStore: store)
        
        _ = store.addNote(title: "Sticky Note 1")
        _ = store.addNote(title: "Sticky Note 2")
        
        let action = model.actions.first(where: { $0.id == .removeLayer })
        XCTAssertNotNil(action)
        XCTAssertTrue(action!.isEnabled)
        XCTAssertNil(action!.disabledReason)
        
        let removable = model.removableLayers
        XCTAssertEqual(removable.count, 2)
        XCTAssertEqual(removable[0].title, "Sticky Note 1")
        XCTAssertEqual(removable[1].title, "Sticky Note 2")
    }

    func testSelectingRemoveLayerMenuItemRemovesThatLayer() {
        let store = SceneStore()
        let model = MenuModel(sceneStore: store)
        
        let result = store.addNote(title: "Sticky Note")
        guard let id = result.layerID else {
            XCTFail("Failed to add layer")
            return
        }
        
        XCTAssertEqual(store.layers.count, 1)
        
        model.removeLayer(withID: id)
        
        XCTAssertEqual(store.layers.count, 0)
    }

    func testMenuOnlyShowsQuitBeforeOnboardingCompletes() {
        let model = MenuModel(
            sceneStore: SceneStore(),
            isOnboardingCompleted: { false }
        )

        let actions = model.actions

        XCTAssertEqual(actions.map(\.id), [.quit])
        XCTAssertTrue(actions.first?.isEnabled == true)
    }

    func testMenuShowsNormalActionsAfterOnboardingCompletes() {
        let model = MenuModel(
            sceneStore: SceneStore(),
            isOnboardingCompleted: { true }
        )

        let ids = model.actions.map(\.id)

        XCTAssertTrue(ids.contains(.addNote))
        XCTAssertTrue(ids.contains(.shareImage))
        XCTAssertTrue(ids.contains(.shareWindowOrScreen))
        XCTAssertTrue(ids.contains(.showPreview))
        XCTAssertTrue(ids.contains(.quit))
    }

    func testQuitIsAlwaysEnabled() {
        let locked = MenuModel(sceneStore: SceneStore(), isOnboardingCompleted: { false })
        let unlocked = MenuModel(sceneStore: SceneStore(), isOnboardingCompleted: { true })

        XCTAssertTrue(locked.actions.first(where: { $0.id == .quit })?.isEnabled == true)
        XCTAssertTrue(unlocked.actions.first(where: { $0.id == .quit })?.isEnabled == true)
    }
}
