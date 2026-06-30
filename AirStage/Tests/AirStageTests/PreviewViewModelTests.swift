import XCTest
@testable import AirStage

final class PreviewViewModelTests: XCTestCase {

    func testPreviewShowsCameraPermissionRequiredWhenPermissionMissing() {
        let fake = FakeCameraPermissionService(status: .notDetermined)
        let vm = PreviewViewModel(permissionService: fake)

        XCTAssertEqual(vm.cameraState, .permissionRequired)
    }

    func testPreviewShowsCameraPermissionRequiredWhenPermissionDenied() {
        let fake = FakeCameraPermissionService(status: .denied)
        let vm = PreviewViewModel(permissionService: fake)

        XCTAssertEqual(vm.cameraState, .permissionRequired)
    }

    func testShowPreviewActionCreatesVisiblePreviewState() {
        let fake = FakeCameraPermissionService(status: .authorized)
        let vm = PreviewViewModel(permissionService: fake)

        XCTAssertEqual(vm.cameraState, .ready)
    }

    func testCameraPermissionStateIsLogged() {
        // Verifies that constructing the view model with each permission state
        // does not crash and resolves to the expected camera state.
        let cases: [(CameraPermissionStatus, CameraState)] = [
            (.notDetermined, .permissionRequired),
            (.denied,        .permissionRequired),
            (.restricted,    .permissionRequired),
            (.authorized,    .ready),
        ]
        for (status, expected) in cases {
            let vm = PreviewViewModel(permissionService: FakeCameraPermissionService(status: status))
            XCTAssertEqual(vm.cameraState, expected, "Expected \(expected) for status \(status)")
        }
    }
}
