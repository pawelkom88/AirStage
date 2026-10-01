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

    func testObserveGrabCompletesGrabStep() {
        var machine = OnboardingStateMachine(hasCompleted: false)
        _ = machine.handle(.showMeTapped)

        _ = machine.handle(.observe(grabbing: true, scale: 1.0))

        XCTAssertEqual(machine.currentStep, .grabSuccess)
    }

    func testScaleAboveThresholdForSixFramesCompletesZoomStep() {
        var machine = OnboardingStateMachine(hasCompleted: false)
        _ = machine.handle(.showMeTapped)
        _ = machine.handle(.observe(grabbing: true, scale: 1.0))
        _ = machine.handle(.continueTapped)

        // Baseline captured on first observe
        _ = machine.handle(.observe(grabbing: false, scale: 1.0))
        
        // 6 frames of scale >= 1.15
        for _ in 1...5 {
            _ = machine.handle(.observe(grabbing: false, scale: 1.2))
            XCTAssertEqual(machine.currentStep, .zoomTutorial)
        }
        _ = machine.handle(.observe(grabbing: false, scale: 1.2))

        XCTAssertEqual(machine.currentStep, .zoomSuccess)
    }

    func testEdgeDeleteVanishHoldRemovesTutorialItemAndShowsVanishSuccess() {
        var machine = OnboardingStateMachine(hasCompleted: false)
        _ = machine.handle(.showMeTapped)
        _ = machine.handle(.observe(grabbing: true, scale: 1.0))
        _ = machine.handle(.continueTapped)
        // pass zoom
        _ = machine.handle(.observe(grabbing: false, scale: 1.0))
        for _ in 1...6 { _ = machine.handle(.observe(grabbing: false, scale: 1.2)) }
        _ = machine.handle(.continueTapped)

        XCTAssertEqual(machine.currentStep, .deleteTutorial)
        
        let command = machine.handle(.vanishHoldCompleted)

        XCTAssertEqual(command, .removeTutorialSceneItem)
        XCTAssertEqual(machine.currentStep, .vanishSuccess)
    }



    func testCompletionDelayElapsedShowsFinalPrompt() {
        var machine = OnboardingStateMachine(hasCompleted: false)
        _ = machine.handle(.showMeTapped)
        _ = machine.handle(.observe(grabbing: true, scale: 1.0))
        _ = machine.handle(.continueTapped)
        _ = machine.handle(.observe(grabbing: false, scale: 1.0))
        for _ in 1...6 { _ = machine.handle(.observe(grabbing: false, scale: 1.2)) }
        _ = machine.handle(.continueTapped)
        _ = machine.handle(.vanishHoldCompleted)

        XCTAssertEqual(machine.currentStep, .vanishSuccess)

        let command = machine.handle(.completionDelayElapsed)

        XCTAssertEqual(machine.currentStep, .completed)
        XCTAssertEqual(command, .persistCompleted)
    }

    func testSkipTransitionsToCompleted() {
        var machine = OnboardingStateMachine(hasCompleted: false)
        machine.handle(.skipTapped)
        
        XCTAssertEqual(machine.currentStep, .completed)
    }

    func testResetOnboardingStartsAgain() {
        var machine = OnboardingStateMachine(hasCompleted: true)
        XCTAssertEqual(machine.currentStep, .completed)
        
        let command = machine.handle(.resetRequested)
        XCTAssertEqual(machine.currentStep, .welcome)
        XCTAssertEqual(command, .removeTutorialSceneItem)
    }
}
