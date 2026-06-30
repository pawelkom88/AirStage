# AirStage — Asset Policy

This document defines what should be shipped as image assets and what must be drawn natively.

## Golden rule

Reference screenshots are visual guidance only. They must not be shipped as product UI assets.

## Use real assets for

- App icon.
- DMG background image.
- DMG volume icon.
- Optional custom vector symbols only when SF Symbols are not enough.
- Marketing screenshots and App Store / website artwork.

## Build natively in SwiftUI/AppKit

Do not create bitmap assets for these UI pieces:

- Pink tutorial card / rectangle.
- Welcome modal/card.
- Virtual camera prompt card.
- Instruction pill.
- Success toast.
- Dashed yellow selection box.
- Resize handles.
- Gesture/finger tracking dots.
- Confidence labels.
- Debug labels.
- Hover quick-add toolbar.
- Layer selection/hover affordances.
- Drag-outside removal hint.

Reasons:

- They must move, scale, rotate, animate, react to gestures, and localize.
- They must remain sharp at every Retina scale.
- They must use the real scene model and renderer.
- Static PNGs would make onboarding fake and brittle.

## Privacy masks

Some onboarding reference screenshots contain red rectangles covering a face. These red rectangles are privacy masks only. They are not product UI, not a design element, not an overlay component, and must never be implemented.

## Onboarding implementation requirement

The tutorial card is a real scene item, not a screenshot or fake overlay.

It must use the same systems as normal user content:

- `SceneLayer` / scene item model.
- Renderer.
- Selection bounds.
- Hit testing.
- Move/drag logic.
- Scale/resize logic.
- Z-index handling.
- Removal logic.
- Hand gesture and mouse fallback input.

## Suggested native components

```text
OnboardingWelcomeCard
TutorialSceneCardView
OnboardingInstructionPill
OnboardingSuccessToast
VirtualCameraPromptCard
SceneSelectionBoundsView
SceneResizeHandleView
GestureStatusPill
FingerTrackingDotView
DragOutsideRemovalHint
```

## Visual target

Use native macOS materials and simple SwiftUI shapes:

- `.regularMaterial` / `.ultraThinMaterial`
- rounded rectangles with `.continuous` corners
- subtle shadows
- SF Symbols
- gradients only when they support hierarchy
- high-contrast text because UI appears over camera video

## Review checklist

Before shipping:

- [ ] No Shacam artwork or copied copy is bundled.
- [ ] No reference screenshots are included in app resources except as developer-only docs.
- [ ] No red privacy masks appear in the app UI.
- [ ] Pink tutorial UI is drawn natively.
- [ ] Tutorial object goes through the real scene pipeline.
- [ ] Debug confidence values are hidden in production by default.
