import XCTest
@testable import AirStage

final class CameraSessionTests: XCTestCase {

    // MARK: Permission request transitions

    func testRequestingCameraPermissionTransitionsToGrantedState() {
        let fake = FakeRequestableCameraPermissionService(initial: .notDetermined, grantOnRequest: true)
        let vm = PreviewViewModel(permissionService: fake)
        XCTAssertEqual(vm.cameraState, .permissionRequired)

        let exp = expectation(description: "state becomes ready")
        vm.requestCameraPermission { granted in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        XCTAssertEqual(vm.cameraState, .ready)
    }

    func testDeniedPermissionShowsRecoveryMessage() {
        let fake = FakeRequestableCameraPermissionService(initial: .notDetermined, grantOnRequest: false)
        let vm = PreviewViewModel(permissionService: fake)

        let exp = expectation(description: "state stays permissionRequired")
        vm.requestCameraPermission { _ in exp.fulfill() }
        wait(for: [exp], timeout: 1)

        XCTAssertEqual(vm.cameraState, .permissionRequired)
        XCTAssertNotNil(vm.permissionDeniedMessage)
    }

    func testGrantedPermissionStartsCameraSession() {
        let fake = FakeRequestableCameraPermissionService(initial: .authorized, grantOnRequest: true)
        let fakeSession = FakeCameraSession()
        let vm = PreviewViewModel(permissionService: fake, cameraSession: fakeSession)

        vm.startCameraSessionIfReady()

        XCTAssertTrue(fakeSession.didStart)
    }

    func testDeniedPermissionDoesNotStartCameraSession() {
        let fake = FakeRequestableCameraPermissionService(initial: .denied, grantOnRequest: false)
        let fakeSession = FakeCameraSession()
        let vm = PreviewViewModel(permissionService: fake, cameraSession: fakeSession)

        vm.startCameraSessionIfReady()

        XCTAssertFalse(fakeSession.didStart)
    }

    func testCameraSessionFailureTransitionsToFailedState() {
        let fake = FakeRequestableCameraPermissionService(initial: .authorized, grantOnRequest: true)
        let fakeSession = FakeCameraSession()
        fakeSession.failOnStart = true
        let vm = PreviewViewModel(permissionService: fake, cameraSession: fakeSession)

        vm.startCameraSessionIfReady()

        if case .failed = vm.cameraState { } else {
            XCTFail("Expected .failed state, got \(vm.cameraState)")
        }
    }
}
