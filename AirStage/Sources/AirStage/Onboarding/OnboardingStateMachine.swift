import Foundation
import CoreGraphics
import OSLog

public enum OnboardingStep: String, CaseIterable, Equatable {
    case welcome
    case grabTutorial
    case grabSuccess
    case zoomTutorial
    case zoomSuccess
    case shrinkTutorial
    case shrinkHold
    case vanishSuccess
    case virtualCameraPrompt
    case completed
}

public enum OnboardingEvent: Equatable {
    case showMeTapped
    case observe(grabbing: Bool, scale: CGFloat)
    case continueTapped
    case vanishHoldCompleted
    case completionDelayElapsed
    case skipTapped
    case virtualCameraPromptDismissed
    case virtualCameraTurnOnTapped
    case resetRequested
}

public enum OnboardingCommand: Equatable {
    case none
    case spawnTutorialSceneItem
    case replaceTutorialSceneItem
    case removeTutorialSceneItem
    case requestVirtualCameraActivation
    case persistCompleted
}

public struct OnboardingThresholds {
    public static let moveCompletionDistance: CGFloat = 64
    public static let zoomCompletionScale: CGFloat = 1.5
    public static let vanishScale: CGFloat = 0.4
    public static let vanishHoldDuration: TimeInterval = 3.0
}

public struct OnboardingStateMachine: Equatable {
    public private(set) var currentStep: OnboardingStep
    
    public private(set) var zoomBaselineScale: CGFloat?
    public private(set) var shrinkBaselineScale: CGFloat?
    public private(set) var successFrameCount: Int = 0

    public init(hasCompleted: Bool) {
        if hasCompleted {
            self.currentStep = .completed
        } else {
            self.currentStep = .welcome
        }
    }

    public mutating func handle(_ event: OnboardingEvent) -> OnboardingCommand {
        let oldStep = currentStep
        var command: OnboardingCommand = .none

        if event == .resetRequested {
            currentStep = .welcome
            zoomBaselineScale = nil
            shrinkBaselineScale = nil
            successFrameCount = 0
            AppLog.onboarding.info("Onboarding reset")
            return .removeTutorialSceneItem
        }

        switch currentStep {
        case .welcome:
            switch event {
            case .showMeTapped:
                currentStep = .grabTutorial
                command = .spawnTutorialSceneItem
            case .skipTapped:
                currentStep = .virtualCameraPrompt
            default:
                break
            }

        case .grabTutorial:
            switch event {
            case .observe(let grabbing, _):
                if grabbing {
                    currentStep = .grabSuccess
                }
            case .skipTapped:
                currentStep = .virtualCameraPrompt
                command = .removeTutorialSceneItem
            default:
                break
            }

        case .grabSuccess:
            switch event {
            case .continueTapped:
                currentStep = .zoomTutorial
                zoomBaselineScale = nil
                shrinkBaselineScale = nil
                successFrameCount = 0
                command = .replaceTutorialSceneItem
            case .skipTapped:
                currentStep = .virtualCameraPrompt
                command = .removeTutorialSceneItem
            default:
                break
            }

        case .zoomTutorial:
            switch event {
            case .observe(_, let scale):
                let baseline = zoomBaselineScale ?? scale
                zoomBaselineScale = baseline
                
                let target = baseline * 1.15
                if scale >= target {
                    successFrameCount += 1
                } else {
                    successFrameCount = 0
                }
                
                if successFrameCount >= 6 {
                    currentStep = .zoomSuccess
                    successFrameCount = 0
                }
            case .skipTapped:
                currentStep = .virtualCameraPrompt
                command = .removeTutorialSceneItem
            default:
                break
            }

        case .zoomSuccess:
            switch event {
            case .continueTapped:
                currentStep = .shrinkTutorial
                shrinkBaselineScale = nil
                successFrameCount = 0
                command = .replaceTutorialSceneItem
            case .skipTapped:
                currentStep = .virtualCameraPrompt
                command = .removeTutorialSceneItem
            default:
                break
            }

        case .shrinkTutorial:
            switch event {
            case .observe(_, let scale):
                let baseline = shrinkBaselineScale ?? scale
                shrinkBaselineScale = baseline
                
                let target = baseline * 0.85
                if scale <= target {
                    successFrameCount += 1
                } else {
                    successFrameCount = 0
                }
                
                if successFrameCount >= 6 {
                    currentStep = .shrinkHold
                    successFrameCount = 0
                }
            case .vanishHoldCompleted:
                currentStep = .vanishSuccess
                command = .removeTutorialSceneItem
            case .skipTapped:
                currentStep = .virtualCameraPrompt
                command = .removeTutorialSceneItem
            default:
                break
            }

        case .shrinkHold:
            switch event {
            case .observe(_, let scale):
                let baseline = shrinkBaselineScale ?? scale
                let target = baseline * 0.85
                if scale > target {
                    currentStep = .shrinkTutorial
                }
            case .vanishHoldCompleted:
                currentStep = .vanishSuccess
                command = .removeTutorialSceneItem
            case .skipTapped:
                currentStep = .virtualCameraPrompt
                command = .removeTutorialSceneItem
            default:
                break
            }

        case .vanishSuccess:
            switch event {
            case .completionDelayElapsed:
                currentStep = .virtualCameraPrompt
            case .skipTapped:
                currentStep = .virtualCameraPrompt
            default:
                break
            }

        case .virtualCameraPrompt:
            switch event {
            case .virtualCameraTurnOnTapped:
                currentStep = .completed
                command = .requestVirtualCameraActivation
            case .virtualCameraPromptDismissed:
                currentStep = .completed
                command = .persistCompleted
            default:
                break
            }

        case .completed:
            break
        }

        let newStep = currentStep
        if newStep != oldStep {
            let newStepRaw = newStep.rawValue
            AppLog.onboarding.info("Onboarding step changed step=\(newStepRaw, privacy: .public)")
        }

        return command
    }
}

public enum OnboardingCopy {
    public static let finalPromptTitle = "You’re ready"
    public static let finalPromptBody = "AirStage can now appear as a camera source in calls, recordings, and live streams. Turn it on when you’re ready."
    public static let finalPromptPrimary = "Turn on AirStage"
    public static let finalPromptSecondary = "Not now"
}
