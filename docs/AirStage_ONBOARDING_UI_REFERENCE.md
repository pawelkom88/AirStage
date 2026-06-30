# AirStage — Onboarding UI Reference

This document defines the first-run onboarding experience using the reference screenshots in `ui-reference/onboarding/`.

Working app name: **AirStage**. If the final app name changes, update user-facing copy consistently.

Important: red rectangles visible in some reference screenshots are privacy masks only. They are not UI and must not be implemented.

## Core principle

AirStage onboarding happens inside the live camera preview. It teaches by doing, not by sending the user through a detached setup wizard.

The user should learn this mental model immediately:

> “The camera preview is a stage. I can put things into it, touch them, resize them, and make them disappear.”

## Reference files

Location: `ui-reference/onboarding/`

| File | Purpose | Notes |
|---|---|---|
| `01_onboarding_welcome_live_preview.png` | First-run welcome card over live camera preview | Centered frosted card. CTA begins tutorial. |
| `02_onboarding_grab_start.png` | Tutorial object appears and asks user to grab it | Object is selected and highlighted. Instruction toast appears. |
| `03_onboarding_grab_success.png` | Successful grab/move confirmation | Compact success toast confirms threshold was met. |
| `04_onboarding_zoom_instruction.png` | Two-hand zoom instruction | Teaches two pinch points / resize handles. |
| `05_onboarding_zoom_success.png` | Successful zoom confirmation | Object is larger and success toast confirms. |
| `06_onboarding_shrink_instruction.png` | Shrink gesture instruction | Teaches squeeze-to-vanish. |
| `07_onboarding_shrink_hold.png` | Very small object during hold/progress | Shows hold/progress before deletion. |
| `08_onboarding_vanish_success.png` | Object removed / vanish confirmation | Layer count returns to zero in debug mode; production only shows success. |
| `09_onboarding_virtual_camera_prompt.png` | Final prompt to enable virtual camera | Appears only after tutorial completion or skip. |

## Final onboarding flow

```text
Welcome card
→ Show me
→ Tutorial scene item appears
→ Grab/move instruction
→ Move threshold met
→ Nice success toast
→ Zoom instruction
→ Scale threshold met
→ Well done success toast
→ Shrink instruction
→ Shrink below threshold and hold
→ Tutorial item vanishes
→ Amazing success toast
→ Virtual camera prompt
```

## Required product copy

Use original AirStage copy, not copied reference-app copy.

### Welcome card

Title:

```text
Welcome to AirStage
```

Body:

```text
Screen sharing you can touch. Let’s teach your hands a few tricks.
```

CTA:

```text
Show me
```

### Grab instruction pill

Title:

```text
Grab it
```

Body:

```text
Pinch over the card and move it around.
```

Mouse fallback body:

```text
Drag the card and move it around.
```

### Zoom instruction pill

Title:

```text
Zoom it
```

Body:

```text
Pinch with both hands, then spread them apart.
```

Mouse fallback body:

```text
Drag a corner handle to make it bigger.
```

### Shrink instruction pill

Title:

```text
Make it vanish
```

Body:

```text
Squeeze it very small with both hands and hold.
```

Mouse fallback body:

```text
Shrink it very small and hold, or drag it outside the preview.
```

### Success labels

Use short, friendly labels:

```text
Nice!
Well done!
Amazing!
```

### Virtual camera prompt

Title:

```text
You’ve got the moves
```

Body:

```text
Turn on AirStage’s virtual camera to use it in video calls, screen recordings, and live streams.
```

Actions:

```text
Maybe later
Turn it on
```

## Native implementation rule

Do not use static image assets for onboarding UI.

Build these natively:

- Welcome card.
- Tutorial pink card.
- Instruction pill.
- Success toast.
- Dashed selection outline.
- Resize handles.
- Gesture/finger dots.
- Virtual camera prompt.

Use SwiftUI/AppKit primitives, SF Symbols, system materials, gradients, shadows, and animations.

## Real scene item rule

The tutorial card is not a fake overlay. It is a real scene item.

It must use the same systems as normal layers:

- Scene model.
- Renderer.
- Z-index.
- Selection bounds.
- Hit testing.
- Move command.
- Scale command.
- Removal command.
- Mouse fallback.
- Gesture events.
- Debug logging.

This ensures onboarding tests the actual product interaction.

## Suggested state machine

```swift
enum OnboardingStep: String, CaseIterable, Equatable {
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
```

Suggested events:

```swift
enum OnboardingEvent: Equatable {
    case showMeTapped
    case tutorialItemMoved(distance: CGFloat)
    case tutorialItemScaled(scale: CGFloat)
    case vanishHoldCompleted
    case skipTapped
    case virtualCameraPromptDismissed
    case virtualCameraTurnOnTapped
    case resetRequested
}
```

Suggested commands:

```swift
enum OnboardingCommand: Equatable {
    case none
    case spawnTutorialSceneItem
    case removeTutorialSceneItem
    case requestVirtualCameraActivation
    case persistCompleted
}
```

## Behavior thresholds

Use named constants, not magic numbers:

```swift
struct OnboardingThresholds {
    static let moveCompletionDistance: CGFloat = 64
    static let zoomCompletionScale: CGFloat = 1.5
    static let vanishScale: CGFloat = 0.3
    static let vanishHoldDuration: TimeInterval = 0.6
}
```

These can be tuned later. Tests should verify behavior using the constants rather than private implementation details.

## Production vs debug UI

Reference screenshots show developer indicators such as layer count and confidence values. Those are acceptable for debug mode only.

Production defaults:

- Do show: simple hand readiness indicator, onboarding cards, success toasts, clean selection bounds.
- Do not show: raw confidence numbers, `layers: 1` debug labels, developer measurement badges.

Debug overlay may show those values when explicitly enabled in settings.

## Visual style

- Camera preview remains full bleed.
- Cards use soft frosted material, blur, and rounded corners.
- Tutorial card uses a high-contrast accent fill so it is visible over camera video.
- Selection outline is helpful but not noisy.
- Toasts are compact and centered near the lower preview area.
- Avoid covering the user’s entire face when possible.
- Do not place critical UI under window controls.

## Acceptance criteria

- First-run users see welcome onboarding inside live preview.
- Returning users do not see onboarding unless reset.
- Clicking `Show me` creates exactly one tutorial scene item.
- Moving the tutorial item advances grab step.
- Scaling above threshold advances zoom step.
- Shrinking below threshold and holding removes tutorial item.
- Virtual camera prompt appears after tutorial completion or skip.
- Tutorial card can be manipulated through the same scene commands as real layers.
- Mouse/trackpad fallback allows onboarding to be completed without hand tracking.
- No onboarding UI is implemented as bitmap assets.
- Red privacy masks never appear in the app.
- Debug labels are hidden unless debug overlay is enabled.
