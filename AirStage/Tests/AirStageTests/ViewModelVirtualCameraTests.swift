import XCTest
import Foundation
@testable import AirStage

@MainActor
final class ViewModelVirtualCameraTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        super.tearDown()
    }

    func testViewModelCallsManagerOnVirtualCameraActivationRequest() {
        let manager = VirtualCameraManager()
        let store = SceneStore()
        let permission = FakeCameraPermissionService(status: .authorized)
        let viewModel = PreviewViewModel(
            permissionService: permission,
            sceneStore: store,
            virtualCameraManager: manager
        )

        XCTAssertEqual(manager.status, .notInstalled)
        
        // Progress onboarding to virtualCameraPrompt step
        viewModel.handleOnboardingEvent(.showMeTapped)
        viewModel.handleOnboardingEvent(.observe(grabbing: true, scale: 1.0))
        viewModel.handleOnboardingEvent(.continueTapped)
        viewModel.handleOnboardingEvent(.observe(grabbing: false, scale: 1.0))
        for _ in 1...6 { viewModel.handleOnboardingEvent(.observe(grabbing: false, scale: 1.2)) }
        viewModel.handleOnboardingEvent(.continueTapped)
        viewModel.handleOnboardingEvent(.observe(grabbing: false, scale: 1.2))
        for _ in 1...6 { viewModel.handleOnboardingEvent(.observe(grabbing: false, scale: 1.0)) }
        viewModel.handleOnboardingEvent(.vanishHoldCompleted)
        viewModel.handleOnboardingEvent(.completionDelayElapsed)
        
        XCTAssertEqual(viewModel.onboardingStep, .virtualCameraPrompt)
        
        // Now tap turn on
        viewModel.handleOnboardingEvent(.virtualCameraTurnOnTapped)

        XCTAssertEqual(manager.status, .pendingApproval)
    }
}
