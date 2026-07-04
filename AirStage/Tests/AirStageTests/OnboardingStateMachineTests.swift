import XCTest
@testable import AirStage

final class OnboardingStateMachineTests: XCTestCase {
    func testFirstRunStartsAtWelcome() {
        let machine = OnboardingStateMachine(hasCompleted: false)
        XCTAssertEqual(machine.currentStep, .welcome)
    }

    func testReturningUserStartsCompleted() {
        let machine = OnboardingStateMachine(hasCompleted: true)
        XCTAssertEqual(machine.currentStep, .completed)
    }

    func testShowMeSpawnsTutorialItemAndAdvancesToGrab() {
        var machine = OnboardingStateMachine(hasCompleted: false)
        let command = machine.handle(.showMeTapped)

        XCTAssertEqual(machine.currentStep, .grabTutorial)
        XCTAssertEqual(command, .spawnTutorialSceneItem)
    }

    func testMoveBeyondThresholdCompletesGrabStep() {
        var machine = OnboardingStateMachine(hasCompleted: false)
        _ = machine.handle(.showMeTapped)

        machine.handle(.tutorialItemMoved(distance: 88))

        XCTAssertEqual(machine.currentStep, .grabSuccess)
    }

    func testScaleAboveThresholdCompletesZoomStep() {
        var machine = OnboardingStateMachine(hasCompleted: false)
        _ = machine.handle(.showMeTapped)
        _ = machine.handle(.tutorialItemMoved(distance: 88))
        _ = machine.handle(.continueTapped)

        machine.handle(.tutorialItemScaled(scale: 1.65))

        XCTAssertEqual(machine.currentStep, .zoomSuccess)
    }

    func testShrinkBelowThresholdStartsVanishHold() {
        var machine = OnboardingStateMachine(hasCompleted: false)
        _ = machine.handle(.showMeTapped)
        _ = machine.handle(.tutorialItemMoved(distance: 88))
        _ = machine.handle(.continueTapped)
        _ = machine.handle(.tutorialItemScaled(scale: 1.65))
        _ = machine.handle(.continueTapped)

        machine.handle(.tutorialItemScaled(scale: 0.25))

        XCTAssertEqual(machine.currentStep, .shrinkHold)
    }

    func testVanishHoldRemovesTutorialItemAndShowsVirtualCameraPrompt() {
        var machine = OnboardingStateMachine(hasCompleted: false)
        _ = machine.handle(.showMeTapped)
        _ = machine.handle(.tutorialItemMoved(distance: 88))
        _ = machine.handle(.continueTapped)
        _ = machine.handle(.tutorialItemScaled(scale: 1.65))
        _ = machine.handle(.continueTapped)
        _ = machine.handle(.tutorialItemScaled(scale: 0.25))

        let command = machine.handle(.vanishHoldCompleted)

        XCTAssertEqual(command, .removeTutorialSceneItem)
        XCTAssertEqual(machine.currentStep, .virtualCameraPrompt)
    }

    func testVirtualCameraTurnOnTappedTransitionsToCompleted() {
        var machine = OnboardingStateMachine(hasCompleted: false)
        machine.handle(.skipTapped)
        
        XCTAssertEqual(machine.currentStep, .virtualCameraPrompt)
        
        let command = machine.handle(.virtualCameraTurnOnTapped)
        XCTAssertEqual(machine.currentStep, .completed)
        XCTAssertEqual(command, .requestVirtualCameraActivation)
    }

    func testVirtualCameraPromptDismissedTransitionsToCompleted() {
        var machine = OnboardingStateMachine(hasCompleted: false)
        machine.handle(.skipTapped)
        
        XCTAssertEqual(machine.currentStep, .virtualCameraPrompt)
        
        let command = machine.handle(.virtualCameraPromptDismissed)
        XCTAssertEqual(machine.currentStep, .completed)
        XCTAssertEqual(command, .persistCompleted)
    }

    func testResetOnboardingStartsAgain() {
        var machine = OnboardingStateMachine(hasCompleted: true)
        XCTAssertEqual(machine.currentStep, .completed)
        
        let command = machine.handle(.resetRequested)
        XCTAssertEqual(machine.currentStep, .welcome)
        XCTAssertEqual(command, .removeTutorialSceneItem)
    }
}
