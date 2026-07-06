import XCTest
import CoreGraphics
@testable import AirStage

final class WindowCaptureTests: XCTestCase {

    // MARK: - WindowCaptureImporter tests

    func testShareWindowAddsWindowCaptureLayer() {
        let store = SceneStore()
        let importer = WindowCaptureImporter(store: store)

        let result = importer.importCapture(
            title: "Safari — google.com",
            captureID: "window-42"
        )

        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(store.layers.count, 1)

        let layer = store.layers.first
        XCTAssertEqual(layer?.kind, .windowCapture)
        XCTAssertEqual(layer?.title, "Safari — google.com")
    }

    func testCannotAddSecondWindowCaptureLayer() {
        let store = SceneStore()
        let importer = WindowCaptureImporter(store: store)

        let first = importer.importCapture(title: "Window 1", captureID: "w-1")
        XCTAssertTrue(first.isSuccess)

        let second = importer.importCapture(title: "Window 2", captureID: "w-2")
        XCTAssertFalse(second.isSuccess)

        if case .failure(let error) = second {
            XCTAssertEqual(error, .limitExceeded)
        } else {
            XCTFail("Expected failure")
        }

        XCTAssertEqual(store.layers.count, 1)
        XCTAssertEqual(store.layers.first?.title, "Window 1")
    }

    func testWindowCaptureFailureShowsFriendlyError() {
        let store = SceneStore()
        let importer = WindowCaptureImporter(store: store)

        // Fill with 6 layers (4 notes + 2 images) so scene is full
        for i in 0..<4 { _ = store.addNote(title: "N\(i)") }
        for i in 0..<2 { _ = store.addImage(title: "I\(i)") }
        XCTAssertEqual(store.layers.count, 6)

        let result = importer.importCapture(title: "Too Many", captureID: "w-full")
        XCTAssertFalse(result.isSuccess)

        if case .failure(let error) = result {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertTrue(error.errorDescription!.contains("limit") || error.errorDescription!.contains("Cannot"))
        } else {
            XCTFail("Expected failure")
        }
    }

    // MARK: - WindowCaptureSource protocol tests (fake)

    func testFakeWindowCaptureSourceReturnsConfiguredWindows() {
        let source = FakeWindowCaptureSource()
        source.availableWindows = [
            CaptureTarget(id: "w-1", title: "Safari", appName: "Safari", isOnScreen: true),
            CaptureTarget(id: "w-2", title: "Terminal", appName: "Terminal", isOnScreen: true),
        ]

        var returned: [CaptureTarget] = []
        source.availableTargets { targets in
            returned = targets
        }

        XCTAssertEqual(returned.count, 2)
        XCTAssertEqual(returned[0].title, "Safari")
        XCTAssertEqual(returned[1].title, "Terminal")
    }

    func testFakeWindowCaptureSourceCanSimulateFailure() {
        let source = FakeWindowCaptureSource()
        source.shouldFailWithError = "Screen recording permission denied"

        var capturedError: String?
        source.availableTargets { _ in }
        source.startCapture(targetID: "w-1") { error in
            capturedError = error
        }

        XCTAssertEqual(capturedError, "Screen recording permission denied")
    }

    // MARK: - Menu enablement

    func testShareWindowMenuIsEnabled() {
        let model = MenuModel()
        let action = model.actions.first(where: { $0.id == .shareWindowOrScreen })
        XCTAssertTrue(action?.isEnabled ?? false,
            "Share Window or Screen should be enabled now that Slice 22 is complete")
    }
}
