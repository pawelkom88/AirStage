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
        machine.handle(.tutorialItemMoved(distance: 88))
        machine.handle(.continueTapped)

        machine.handle(.tutorialItemScaled(scale: 1.65))

        XCTAssertEqual(machine.currentStep, .zoomSuccess)
    }

    func testShrinkBelowThresholdStartsVanishHold() {
        var machine = OnboardingStateMachine(hasCompleted: false)
        _ = machine.handle(.showMeTapped)
        machine.handle(.tutorialItemMoved(distance: 88))
        machine.handle(.continueTapped)
        machine.handle(.tutorialItemScaled(scale: 1.65))
        machine.handle(.continueTapped)

        machine.handle(.tutorialItemScaled(scale: 0.25))

        XCTAssertEqual(machine.currentStep, .shrinkHold)
    }

    func testVanishHoldRemovesTutorialItemAndShowsVirtualCameraPrompt() {
        var machine = OnboardingStateMachine(hasCompleted: false)
        _ = machine.handle(.showMeTapped)
        machine.handle(.tutorialItemMoved(distance: 88))
        machine.handle(.continueTapped)
        machine.handle(.tutorialItemScaled(scale: 1.65))
        machine.handle(.continueTapped)
        machine.handle(.tutorialItemScaled(scale: 0.25))

        let command = machine.handle(.vanishHoldCompleted)

        XCTAssertEqual(command, .removeTutorialSceneItem)
        XCTAssertEqual(machine.currentStep, .virtualCameraPrompt)
    }
}
