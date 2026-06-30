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

        // shareWindowOrScreen is disabled until ScreenCaptureKit is wired in later slices.
        let windowAction = model.actions.first(where: { $0.id == .shareWindowOrScreen })
        XCTAssertNotNil(windowAction)
        if let action = windowAction, !action.isEnabled {
            XCTAssertNotNil(action.disabledReason, "Disabled actions must expose a reason")
        }
    }

    func testSelectingShowPreviewEmitsIntent() {
        let model = MenuModel()
        var emittedIntent: MenuIntent?
        model.onIntent = { emittedIntent = $0 }

        model.select(.showPreview)

        XCTAssertEqual(emittedIntent, .showPreview)
    }

    func testSelectingSettingsEmitsIntent() {
        let model = MenuModel()
        var emittedIntent: MenuIntent?
        model.onIntent = { emittedIntent = $0 }

        model.select(.settings)

        XCTAssertEqual(emittedIntent, .settings)
    }
}
