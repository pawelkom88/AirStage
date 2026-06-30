# AirStage — PRD

> **One-liner:** AirStage lets presenters place images, sticky notes, and live windows over their webcam feed, then move or remove them naturally during live calls.  
> **Status:** Draft for implementation  
> **Date:** 2026-06-30

---

## Problem

Presenting during video calls is still clumsy. If a user wants to show a screenshot, note, visual prompt, or app window while staying on camera, they usually switch screens, share the whole desktop, or paste content into a separate app. That breaks flow and feels awkward in meetings.

AirStage turns the webcam into a small live stage. The user can place useful content directly over their camera feed, move it with the mouse first, then later with hand gestures, and output the composed scene to video-call apps through a virtual camera.

## Who It's For

The primary user is an indie maker, teacher, support person, or product demo presenter who spends time in Zoom, Google Meet, Loom, OBS, or QuickTime and wants to make live explanations more visual without switching context. They need something fast enough to use during a meeting, not a heavy broadcast studio.

## MVP Scope

### In v1

AirStage v1 includes:

1. Native macOS menu bar app with a small action-first menu.
2. Preview window showing a live camera scene.
3. Add and manage overlay layers: sticky notes, images, and one window/screen capture.
4. Mouse-based selection, dragging, resizing, bring-to-front, Delete-key removal, and drag-outside-to-remove.
5. In-preview onboarding tutorial that teaches grab/move, zoom/scale, and shrink-to-vanish removal using a real tutorial scene item.
6. Debug logs and debug overlay to make Xcode testing easy.
7. Vision hand tracking and pinch-to-grab after mouse layer behaviour is stable.
8. Virtual camera extension only after the local preview/compositor path works.

### Not in v1

AirStage v1 does **not** include:

1. iPhone/iPad sharing.
2. Licensing/paywall/purchase flow.
3. Sparkle auto-updates.
4. Multi-window capture beyond one live capture layer.
5. Advanced double-pinch gesture.
6. Push-pull depth zoom.
7. Cloud sync, accounts, templates, collaboration, or recording.
8. Exact cloning of Shacam assets, copy, icon, or branding.

### Done means

v1 is complete when a user can open AirStage, see their camera preview, add a note/image/window, move and remove layers safely, complete onboarding, see useful debug logs, and select AirStage as a virtual camera in a compatible app after extension installation.

## User Flow

1. User launches AirStage.
2. AirStage appears as a menu bar app, not a Dock-first app.
3. User opens the menu and sees: master on/off, Add Note, Share Image, Share Window or Screen, Remove Layer, Show Preview, Camera, Settings, Quit.
4. User opens preview.
5. If camera permission is missing, AirStage shows a friendly permission state with a clear action.
6. Once permission is granted, the preview shows the live camera feed.
7. First-run onboarding appears inside the preview as a soft material welcome card.
8. User clicks `Show me`.
9. AirStage spawns one real tutorial scene item.
10. User learns grab/move, zoom/scale, and shrink-to-vanish deletion with success feedback after each real behaviour threshold.
11. AirStage asks whether to enable the virtual camera only after onboarding is completed or skipped.
12. User adds a note from the menu, quick-add toolbar, or keyboard shortcut.
13. The note appears in a safe visible position above the camera feed.
14. User selects, drags, resizes, edits, and removes the note.
15. User adds an image by picker, drag/drop, or paste.
16. User adds one live window/screen layer through the native ScreenCaptureKit picker.
17. User removes a selected layer with Delete, the Remove Layer menu, or by dragging it outside the preview bounds and releasing.
18. User turns on hand control in settings.
19. Debug overlay can show hand landmarks and gesture state, but only when explicitly enabled.
20. User pinches to grab and move a selected/targeted layer.
21. After preview interactions are stable, user enables the virtual camera and selects AirStage in Zoom/Meet/OBS/QuickTime.

## First-run Onboarding

### Goal

Teach the user that AirStage turns the camera preview into an interactive presentation canvas.

### User story

As a first-time user, I want to learn how to grab, resize, and remove a floating object in my camera scene so that I feel confident using AirStage in a real meeting.

### Flow

1. The app opens to the live camera preview.
2. A centered frosted card says:
   - Title: `Welcome to AirStage`
   - Body: `Screen sharing you can touch. Let’s teach your hands a few tricks.`
   - CTA: `Show me`
3. Tapping `Show me` spawns a tutorial card in the scene.
4. The app teaches:
   - Grab/move with one-hand pinch or mouse fallback.
   - Zoom/scale with two-hand pinch/spread or resize-handle fallback.
   - Shrink-to-vanish by squeezing small and holding, with delete/drag-out fallback.
5. Each successful step shows a compact success toast.
6. After the tutorial object vanishes, the app asks whether to enable the virtual camera.
7. The user can choose `Maybe later` or `Turn it on`.

### Acceptance criteria

- Onboarding appears only for first-run users unless manually restarted from settings/help.
- The tutorial runs on top of the real camera preview.
- The tutorial card is represented as a real scene item.
- The tutorial uses real scene events and real gesture recognition events where available.
- Mouse/trackpad fallback controls are available when hand tracking is unavailable.
- Success feedback appears only after behavior thresholds are met.
- Virtual camera activation is requested only after the tutorial is completed or skipped.
- Debug labels such as `layers: 1` or gesture confidence values are not visible in production builds by default.
- Red privacy masks from reference screenshots are ignored and never implemented.

## Layer Rules

- Max total layers: `6`.
- Max live window/screen layers: `1`.
- Max image layers: `3`.
- Max note layers: `4`.
- Notes appear above image/window layers by default.
- New layers spawn fully inside the preview.
- Clicking/grabbing a layer brings it to front.
- Dragging outside the preview by more than `60pt` shows “Release to remove”.
- Releasing outside removes the layer.
- Dragging back inside cancels removal.
- If the scene is full, show a non-scary “Scene is full” message with actions: “Replace oldest” and “Cancel”.

## Tech Decisions

**Platform:** macOS 14+  
**Stack:** SwiftUI + AppKit, XCTest, OSLog  
**Camera:** AVFoundation  
**Window/screen capture:** ScreenCaptureKit  
**Hand tracking:** Vision hand pose behind a testable adapter  
**Rendering/compositing:** Start with SwiftUI/CoreAnimation preview; move to CoreImage/Metal frame pipeline before virtual camera  
**Virtual camera:** Core Media I/O Camera Extension + SystemExtensions, implemented late  
**Launch at login:** ServiceManagement, late slice  
**Distribution assumption:** Direct distribution signed/notarized DMG later; App Store not assumed for v1. Keep architecture compatible with a future sandbox/App Store build where practical.  
**Constraints:** Native macOS components, local-only processing, no recording, no cloud, no account

## Asset Policy

- Use real assets for app icon, DMG background, DMG volume icon, and optional custom symbols only.
- Build onboarding cards, pink tutorial rectangles, gesture dots, selection outlines, instruction pills, and success toasts using native SwiftUI/AppKit drawing.
- Reference screenshots are not app assets.
- Red rectangles in onboarding screenshots are privacy masks only and must not appear in the app.

## Open Questions

- [ ] Final bundle identifier and team prefix.
- [ ] Final app icon and brand palette.
- [ ] Whether virtual camera is required for first external test build or can ship after preview MVP.
- [ ] Whether hand tracking should be enabled by default or off by default.
- [ ] Final keyboard shortcuts.
