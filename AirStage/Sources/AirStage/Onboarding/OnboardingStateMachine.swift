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
    case tutorialItemMoved(distance: CGFloat)
    case tutorialItemScaled(scale: CGFloat)
    case continueTapped
    case vanishHoldCompleted
    case skipTapped
    case virtualCameraPromptDismissed
    case virtualCameraTurnOnTapped
    case resetRequested
}

public enum OnboardingCommand: Equatable {
    case none
    case spawnTutorialSceneItem
    case removeTutorialSceneItem
    case requestVirtualCameraActivation
    case persistCompleted
}

public struct OnboardingThresholds {
    public static let moveCompletionDistance: CGFloat = 64
    public static let zoomCompletionScale: CGFloat = 1.5
    public static let vanishScale: CGFloat = 0.3
    public static let vanishHoldDuration: TimeInterval = 0.6
}

public struct OnboardingStateMachine: Equatable {
    public private(set) var currentStep: OnboardingStep

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
            case .tutorialItemMoved(let distance):
                if distance >= OnboardingThresholds.moveCompletionDistance {
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
            case .skipTapped:
                currentStep = .virtualCameraPrompt
                command = .removeTutorialSceneItem
            default:
                break
            }

        case .zoomTutorial:
            switch event {
            case .tutorialItemScaled(let scale):
                if scale >= OnboardingThresholds.zoomCompletionScale {
                    currentStep = .zoomSuccess
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
            case .skipTapped:
                currentStep = .virtualCameraPrompt
                command = .removeTutorialSceneItem
            default:
                break
            }

        case .shrinkTutorial:
            switch event {
            case .tutorialItemScaled(let scale):
                if scale <= OnboardingThresholds.vanishScale {
                    currentStep = .shrinkHold
                }
            case .vanishHoldCompleted:
                currentStep = .virtualCameraPrompt
                command = .removeTutorialSceneItem
            case .skipTapped:
                currentStep = .virtualCameraPrompt
                command = .removeTutorialSceneItem
            default:
                break
            }

        case .shrinkHold:
            switch event {
            case .tutorialItemScaled(let scale):
                if scale > OnboardingThresholds.vanishScale {
                    currentStep = .shrinkTutorial
                }
            case .vanishHoldCompleted:
                currentStep = .virtualCameraPrompt
                command = .removeTutorialSceneItem
            case .skipTapped:
                currentStep = .virtualCameraPrompt
                command = .removeTutorialSceneItem
            default:
                break
            }

        case .vanishSuccess:
            break

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
