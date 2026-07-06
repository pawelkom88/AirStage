import XCTest
import Foundation
@testable import AirStage

final class VirtualCameraTests: XCTestCase {

    func testVirtualCameraDisabledBeforeSetup() {
        let manager = VirtualCameraManager()
        XCTAssertEqual(manager.status, .notInstalled)
    }

    func testInstallRequestTransitionsToPendingApproval() {
        let manager = VirtualCameraManager()
        manager.requestInstall()
        XCTAssertEqual(manager.status, .pendingApproval)
    }

    func testExtensionStatusMessagesAreUserFriendly() {
        XCTAssertEqual(VirtualCameraStatus.notInstalled.userFriendlyMessage, "Virtual camera is not installed.")
        XCTAssertEqual(VirtualCameraStatus.pendingApproval.userFriendlyMessage, "Virtual camera installation pending system approval. Please check System Settings -> Privacy & Security -> Camera/Extensions.")
        XCTAssertEqual(VirtualCameraStatus.installed.userFriendlyMessage, "Virtual camera is ready.")
        XCTAssertEqual(VirtualCameraStatus.error("Access denied").userFriendlyMessage, "Virtual camera error: Access denied")
    }
}
