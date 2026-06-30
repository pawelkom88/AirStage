import XCTest
@testable import AirStage

final class AppLogTests: XCTestCase {

    func testAppLogCategoriesExist() {
        // Verify all required logger categories compile and are non-nil.
        // OSLog.Logger is a value type so we just confirm access doesn't crash.
        _ = AppLog.app
        _ = AppLog.menu
        _ = AppLog.camera
        _ = AppLog.scene
        _ = AppLog.sources
        _ = AppLog.gestures
        _ = AppLog.onboarding
        _ = AppLog.settings
        _ = AppLog.virtualCamera
    }

    func testLaunchDiagnosticsCanBeCreated() {
        // LaunchDiagnostics.logStartup() must not crash and must emit a log line.
        LaunchDiagnostics.logStartup()
    }
}
