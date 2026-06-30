# AirStage — TDD Breakdown Plan

## Product Goal

Build AirStage, a native macOS menu bar app that lets a presenter place notes, images, and one live window/screen over their webcam feed, manage those layers quickly during a meeting, learn the interaction through in-preview onboarding, and eventually output the composed scene through a virtual camera.

## Behaviour Inventory

### App Shell

- Launch as native macOS app.
- Provide menu bar control surface.
- Open preview window.
- Open settings window.
- Emit useful debug logs.

### Camera Preview

- Explain missing camera permission.
- Request camera permission.
- Show live camera feed after permission.
- Log permission/session state.

### Scene / Layers

- Represent note, image, window capture, and tutorial layers.
- Enforce max layer rules.
- Add layers in safe positions.
- Select, drag, resize, and bring layers to front.
- Remove layer via Delete, menu, and drag-outside release.

### Add Flows

- Add Note from menu and quick toolbar.
- Add Image from file picker and drag/drop/paste where feasible.
- Add one Window/Screen from ScreenCaptureKit picker.
- Show scene full behaviour.

### Meeting-Speed Controls

- Preview hover quick-add toolbar.
- Keyboard actions for selected layer.
- Clear/remove flows.

### Onboarding

- In-preview tutorial.
- Progresses through real user actions.
- Can be reset from settings.

### Settings

- Launch at login toggle.
- Debug overlay toggle.
- Hand control toggle.
- Snap to grid toggle.
- Onboarding reset/show.
- Persist settings.

### Gestures

- Vision hand pose behind adapter.
- Debug overlay for landmarks/state.
- Pinch-to-grab layer.

### Output

- Compositor frame path.
- Virtual camera extension late in the plan.

## Key Assumptions

- Target is macOS 14+.
- Native SwiftUI + AppKit is preferred.
- The first useful milestone is local preview, not virtual camera.
- Virtual camera extension is required eventually but should not block preview MVP.
- iPhone/iPad sharing, licensing, and Sparkle updates are not v1.
- Reference screenshots are visual/interaction references only, not shippable assets. Onboarding cards, pink rectangles, dots, handles, and toasts must be drawn natively.

## Risks and Dependencies

- Camera and screen recording permissions can slow manual testing.
- ScreenCaptureKit needs real macOS environment; simulator-style testing is not enough.
- Vision hand tracking can be flaky if tested only with live camera; use fake frames/adapter tests first.
- Virtual camera extension requires signing/system extension setup and should be isolated late.
- UI tests for menu bar apps can be brittle; prefer unit/component tests for behaviour and manual QA for native menus.
- Real-time compositor and virtual camera latency are later performance risks.

## Recommended Test Strategy

### Unit Tests

Use unit tests for:

- Scene limits.
- Layer add/remove/select/bring-to-front.
- Drag-outside removal geometry.
- Onboarding state transitions.
- Settings persistence adapter.
- Gesture engine state from fake hand pose frames.

### Integration Tests

Use integration tests for:

- Menu action → scene change.
- Quick-add toolbar → scene change.
- Image picker/drop handler using fixtures.
- Permission service with fake camera permission states.

### UI Tests

Use sparingly for:

- Preview opens.
- Visible permission text appears.
- Settings toggles are visible.
- Onboarding card visible/progresses.

### Manual QA

Required for:

- Actual camera feed.
- ScreenCaptureKit picker.
- Hand tracking with real camera.
- Virtual camera extension installation.
- Zoom/Meet/OBS/QuickTime compatibility.

### What Not To Test

- Private methods.
- Exact SwiftUI hierarchy.
- Exact material blur/radius/shadow.
- Snapshot images as main verification.
- Vision’s internal model output.

---

## TDD Slices

### Slice 1 — Project Foundation, Test Target, and Logger

#### Behaviour

The repo has a buildable macOS app target, a test target, and a central `AppLog` logger. Launching the app writes a clear startup log.

#### Why this slice exists

All later slices need build/test/logging foundation. The user expects to run in Xcode and understand what is happening from console logs.

#### Red

Write/enable a failing test or build check that expects:

- test target exists and runs,
- `AppLog` categories are available,
- app startup path can call a launch logging function without crashing.

Suggested tests:

- `testAppLogCategoriesExist`
- `testLaunchDiagnosticsCanBeCreated`

#### Green

Create minimal app shell and `AppLog.swift` using `OSLog.Logger`. Add a small launch diagnostics function if needed.

#### Refactor

Keep logger names centralized. Remove temporary prints.

#### Acceptance Criteria

- App builds.
- Tests run.
- No `print`-based main logging.
- Xcode console shows AirStage launch log.

#### Suggested `/goal` Prompt

Implement Slice 1 from `docs/AirStage_TDD_BREAKDOWN_PLAN.md`: create/verify macOS app target, test target, and central `AppLog` using `OSLog.Logger`. Write failing tests first for logger availability/launch diagnostics, then minimal implementation. Do not add product features yet.

---

### Slice 2 — Native Menu Bar Shell

#### Behaviour

AirStage appears as a native menu bar app with menu actions: Add Note, Share Image, Share Window or Screen, Remove Layer, Show Preview, Camera, Settings, Quit. Actions can be disabled if not implemented yet, but visible where useful.

#### Why this slice exists

The menu is the primary control surface. It anchors the product and later actions.

#### Red

Write tests around a menu model/provider, not fragile native menu UI internals.

Suggested tests:

- `testMenuContainsPrimaryActions`
- `testDisabledActionsExposeReasonWhenUnavailable`
- `testSelectingShowPreviewEmitsIntent`

#### Green

Implement menu model and minimal native menu surface. Wire actions to logged intents/stubs.

#### Refactor

Separate menu model from AppKit/SwiftUI rendering so it remains testable.

#### Acceptance Criteria

- Menu actions are visible.
- Show Preview intent is emitted/logged.
- Settings intent is emitted/logged.
- Disabled future actions are native-disabled, not hidden without explanation.

#### Suggested `/goal` Prompt

Implement Slice 2: native AirStage menu bar shell. Write tests for the menu model/actions first. Then implement the smallest native menu surface with logged intents. Do not implement preview, camera, or layer logic yet.

---

### Slice 3 — Preview Window Opens With Permission Placeholder

#### Behaviour

Selecting Show Preview opens a preview window. If camera permission is missing/unknown, the window shows a friendly placeholder explaining camera access is needed.

#### Why this slice exists

Before camera capture, users need a visible preview surface and permission state.

#### Red

Test a preview view model/state object with fake permission states.

Suggested tests:

- `testPreviewShowsCameraPermissionRequiredWhenPermissionMissing`
- `testShowPreviewActionCreatesVisiblePreviewState`
- `testCameraPermissionStateIsLogged`

#### Green

Implement preview window controller/view and fake permission service path. Use visible text such as “Camera access needed”.

#### Refactor

Keep permission checking behind a protocol.

#### Acceptance Criteria

- Show Preview opens window.
- Missing camera permission state is visible.
- Permission state is logged.
- No real camera session required yet.

#### Suggested `/goal` Prompt

Implement Slice 3: Show Preview opens a native preview window with a camera permission placeholder. Write tests first with a fake permission service. Add debug logs for preview open and permission status. Do not start real camera capture yet.

---

### Slice 4 — Camera Permission Request and Live Preview Adapter

#### Behaviour

User can request camera permission. When permission is granted, preview transitions to a live camera-ready state and starts the camera session adapter.

#### Why this slice exists

The live camera feed is the base layer of the stage.

#### Red

Test camera permission service and preview state transitions using fakes.

Suggested tests:

- `testRequestingCameraPermissionTransitionsToGrantedState`
- `testGrantedPermissionStartsCameraSession`
- `testDeniedPermissionShowsRecoveryMessage`

#### Green

Implement AVFoundation-backed service behind protocol. In UI, bridge to real preview only after fake tests pass.

#### Refactor

Separate AVFoundation session setup from view state.

#### Acceptance Criteria

- Permission request flow works.
- Denied state is friendly.
- Granted state starts camera session.
- Xcode logs camera permission and session start/failure.

#### Suggested `/goal` Prompt

Implement Slice 4: camera permission request and live camera session adapter. Tests first with fake services. Then add minimal AVFoundation-backed implementation. Log permission/session state. Do not add overlay layers yet.

---

### Slice 5 — Scene Layer Model and Limits

#### Behaviour

AirStage can represent scene layers and enforce max totals: 6 total, 1 window, 3 images, 4 notes.

#### Why this slice exists

All add/remove/move behaviour depends on a testable scene model.

#### Red

Write pure unit tests.

Suggested tests:

- `testCanAddLayerWhenUnderLimit`
- `testCannotExceedSixTotalLayers`
- `testCannotAddMoreThanOneWindowCaptureLayer`
- `testCannotAddMoreThanThreeImageLayers`
- `testCannotAddMoreThanFourNoteLayers`
- `testSceneFullOffersReplaceOldestOrCancel`

#### Green

Implement `SceneLayer`, `SceneLimits`, and `SceneStore` with add result enum.

#### Refactor

Keep layer rules centralized and readable.

#### Acceptance Criteria

- Limits pass tests.
- Add failures return user-displayable reason.
- Logs exist for layer add and scene full.

#### Suggested `/goal` Prompt

Implement Slice 5: testable scene layer model and layer limits. Write pure unit tests first. Add `SceneLayer`, `SceneLimits`, `SceneStore`, and logs. No UI layer rendering yet.

---

### Slice 6 — Add Note Layer From Menu

#### Behaviour

Selecting Add Note creates a sticky note layer in the preview scene at a safe visible position.

#### Why this slice exists

Notes are the fastest first “magic moment” and easiest layer type.

#### Red

Test menu action → scene store add note.

Suggested tests:

- `testAddNoteActionAddsNoteLayer`
- `testNewNoteHasDefaultReadableTitle`
- `testNewNoteSpawnsInsidePreviewBounds`
- `testAddNoteLogsLayerAdded`

#### Green

Wire Add Note action to `SceneStore.addNote`. Render a simple sticky note card in preview.

#### Refactor

Extract note card view only after tests pass.

#### Acceptance Criteria

- Add Note adds visible note layer.
- Note is inside preview bounds.
- Note has readable default text.
- Log shows layer added.

#### Suggested `/goal` Prompt

Implement Slice 6: Add Note from menu creates a visible note layer. Write tests first for action-to-scene behaviour and safe spawn. Then render minimal native sticky note card. Do not implement editing/dragging yet.

---

### Slice 7 — Edit Note Text

#### Behaviour

User can click/edit a note and its text persists in scene state.

#### Why this slice exists

A note is only useful if the user can write meeting text into it.

#### Red

Suggested tests:

- `testEditingNoteUpdatesLayerText`
- `testEmptyNoteShowsPlaceholder`
- `testEditedNoteTitleAppearsInRemoveLayerMenu`

#### Green

Add note text field/editor for selected note. Update scene state.

#### Refactor

Keep note content separate from display title if needed.

#### Acceptance Criteria

- Note can be edited.
- Empty note has placeholder.
- Remove Layer menu uses readable note title.
- Edit events log at useful level without logging sensitive long content.

#### Suggested `/goal` Prompt

Implement Slice 7: editable sticky notes. Write tests first for note content updates, placeholder, and readable title. Then add minimal UI editing. Avoid logging private note content beyond short public title.

---

### Slice 8 — Add Image Layer From Picker and Drop/Paste Handler

#### Behaviour

User can add an image layer through Share Image. Preview accepts image drop/paste when focused if feasible.

#### Why this slice exists

Images are a core AirStage use case for showing screenshots or visual aids during calls.

#### Red

Use fixture image data and fake picker/drop handlers.

Suggested tests:

- `testShareImageAddsImageLayerFromSelectedFile`
- `testUnsupportedFileShowsFriendlyError`
- `testImageLayerUsesFilenameAsTitle`
- `testImageLayerLimitIsEnforced`

#### Green

Implement image source abstraction, `NSOpenPanel` bridge, and minimal image card rendering.

#### Refactor

Keep file loading separate from UI picker.

#### Acceptance Criteria

- Share Image adds visible image layer.
- Unsupported files do not crash.
- Image limit works.
- Logs show selected image path as private and layer added as public metadata.

#### Suggested `/goal` Prompt

Implement Slice 8: add image layers from picker and testable drop/paste handler. Tests first with fixture image data. Then add `NSOpenPanel` bridge and minimal rendering. Do not implement window capture yet.

---

### Slice 9 — Select, Bring to Front, and Delete Layer

#### Behaviour

Clicking a layer selects it and brings it to front. Pressing Delete removes the selected layer.

#### Why this slice exists

Selection is the base for move, resize, remove, and gestures.

#### Red

Suggested tests:

- `testSelectingLayerMarksOnlyThatLayerSelected`
- `testSelectingLayerRaisesZIndex`
- `testDeleteRemovesSelectedLayer`
- `testDeleteWithNoSelectionDoesNothing`

#### Green

Implement selection and delete handling in `SceneStore` and preview key handling.

#### Refactor

Centralize z-index management.

#### Acceptance Criteria

- Only one selected layer at a time.
- Selected layer visually indicates selection.
- Delete removes selected layer.
- Logs show select/remove.

#### Suggested `/goal` Prompt

Implement Slice 9: layer selection, bring-to-front, and Delete removal. Write SceneStore tests first. Then add minimal preview interaction. Do not implement dragging/resizing yet.

---

### Slice 10 — Mouse Drag Layer

#### Behaviour

User can drag selected layer around the preview with the mouse. Layer remains within normal usable bounds unless intentionally dragged outside for removal in next slice.

#### Why this slice exists

Mouse control is reliable and must work before hand gestures.

#### Red

Suggested tests:

- `testDraggingLayerUpdatesPosition`
- `testDraggingLayerKeepsLayerVisibleForNormalDrag`
- `testDraggingUnknownLayerDoesNothing`

#### Green

Add drag gesture handling and position updates.

#### Refactor

Move geometry helpers into `SceneGeometry`.

#### Acceptance Criteria

- Drag updates layer position.
- Movement is smooth enough manually.
- Logs show drag start/end and debug movement.

#### Suggested `/goal` Prompt

Implement Slice 10: mouse dragging for layers. Tests first for position updates and bounds. Then add minimal drag gesture UI. Add debug logs for drag start/move/end. Do not add drag-outside removal yet.

---

### Slice 11 — Resize Layer With Handles

#### Behaviour

Selected image/note/window layers can be resized with visible handles. Resizing respects minimum readable size.

#### Why this slice exists

Presenters need to make content readable on camera.

#### Red

Suggested tests:

- `testResizingLayerUpdatesSize`
- `testResizeDoesNotGoBelowMinimumSize`
- `testResizeKeepsLayerInsidePreviewWhenPossible`

#### Green

Implement corner handle for selected layer. Use simple minimum sizes.

#### Refactor

Centralize min-size rules per layer kind.

#### Acceptance Criteria

- Selected layer shows resize affordance.
- Resize changes size.
- Minimum size enforced.
- Logs show resize start/end.

#### Suggested `/goal` Prompt

Implement Slice 11: selected layer resize handles. Write tests first for size changes and minimum sizes. Then add minimal native resize UI. Do not implement gestures or snap-to-grid yet.

---

### Slice 12 — Drag Outside Preview to Remove

#### Behaviour

Dragging a layer outside preview bounds by more than 60pt arms removal and shows “Release to remove”. Releasing outside removes it. Dragging back inside cancels.

#### Why this slice exists

This is a key AirStage improvement: fast meeting-safe removal without tedious menu usage.

#### Red

Suggested tests:

- `testShouldRemoveLayerWhenCenterOutsideExpandedBounds`
- `testDraggingOutsideArmsRemovalState`
- `testDraggingBackInsideCancelsRemovalState`
- `testReleasingOutsideRemovesLayer`
- `testReleasingInsideKeepsLayer`

#### Green

Implement `shouldRemoveLayer` and drag release behaviour. Add visual removal hint.

#### Refactor

Keep removal geometry pure and unit-tested.

#### Acceptance Criteria

- “Release to remove” appears when armed.
- Releasing outside removes layer.
- Returning inside cancels.
- Logs show removal armed/cancelled/removed reason.

#### Suggested `/goal` Prompt

Implement Slice 12: drag outside preview to remove. Write pure geometry and SceneStore tests first. Then add visual “Release to remove” hint and release behaviour. Add debug logs. Do not alter unrelated drag behaviour.

---

### Slice 13 — Remove Layer Menu Reflects Current Layers

#### Behaviour

Remove Layer submenu lists current layers by readable title and removes the chosen layer.

#### Why this slice exists

Menu removal remains useful before/after meetings and for users who prefer menus.

#### Red

Suggested tests:

- `testRemoveLayerMenuListsCurrentLayers`
- `testSelectingRemoveLayerMenuItemRemovesThatLayer`
- `testRemoveLayerMenuDisabledWhenNoLayersExist`

#### Green

Bind menu model to scene store layer summaries.

#### Refactor

Avoid AppKit-specific logic in tests.

#### Acceptance Criteria

- Submenu updates as layers change.
- Selecting a layer removes it.
- Empty submenu state is clear.
- Logs show menu-based removal.

#### Suggested `/goal` Prompt

Implement Slice 13: Remove Layer submenu backed by current scene layers. Tests first against menu model and scene store. Then wire native menu. Do not change drag/delete removal.

---

### Slice 14 — Preview Hover Quick-Add Toolbar

#### Behaviour

When the preview is focused/hovered, a soft native material toolbar appears with `+ Note`, `+ Image`, `+ Window`, `Paste`, and `Clear`.

#### Why this slice exists

Menu dropdowns are tedious during live meetings. AirStage must support quick in-preview actions.

#### Red

Suggested tests:

- `testQuickAddToolbarVisibleWhenPreviewHovered`
- `testQuickAddNoteAddsNoteLayer`
- `testQuickAddClearRemovesAllLayersAfterConfirmationOrSimpleAction`
- `testQuickAddShowsSceneFullMessageWhenLimitReached`

#### Green

Implement toolbar visibility state and actions. Use native material/pill style.

#### Refactor

Share action handlers with menu actions.

#### Acceptance Criteria

- Toolbar appears/disappears appropriately.
- + Note works.
- + Image opens same picker path.
- Scene full message appears when needed.
- Logs show toolbar action selected.

#### Suggested `/goal` Prompt

Implement Slice 14: preview hover quick-add toolbar. Tests first for toolbar visibility and action routing. Then add native material toolbar UI. Reuse existing menu actions. Do not implement new feature types.

---

### Slice 15 — First-Run Onboarding State Machine and Real Tutorial Scene Item

#### Behaviour

First-run onboarding appears inside the live preview and teaches the real interaction model:

```text
welcome card
→ Show me
→ tutorial scene item appears
→ grab/move
→ success toast
→ zoom/scale
→ success toast
→ shrink-to-vanish
→ success toast
→ virtual camera prompt
```

The tutorial object must be a real scene item. It must use the same scene model, renderer, selection bounds, hit testing, movement, scaling, z-index, and removal rules as normal user content.

The onboarding screenshots in `ui-reference/onboarding/` are visual references only. Do not add bitmap assets for the pink tutorial card, instruction pill, success toast, dashed bounds, gesture dots, or modal cards. Draw them with native SwiftUI/AppKit components.

The red rectangles in screenshots are privacy masks only and must never be implemented.

#### Why this slice exists

The app interaction is unusual. Onboarding should teach the real flow in context and validate that the scene pipeline actually works.

#### Red

Suggested tests:

- `testFirstRunStartsAtWelcome`
- `testReturningUserDoesNotShowWelcome`
- `testShowMeSpawnsOneTutorialSceneItem`
- `testTutorialItemIsRepresentedInSceneStore`
- `testMovingTutorialItemBeyondThresholdCompletesGrabStep`
- `testScalingTutorialItemAboveThresholdCompletesZoomStep`
- `testShrinkingTutorialItemBelowThresholdStartsVanishHold`
- `testVanishHoldRemovesTutorialItemAndShowsSuccess`
- `testVirtualCameraPromptAppearsAfterVanish`
- `testCompletingOnboardingPersistsCompletedState`
- `testResetOnboardingStartsAgain`
- `testProductionOnboardingDoesNotExposeDebugConfidenceLabels`

#### Green

Implement:

- `OnboardingStateMachine` with welcome, grab, zoom, shrink, vanish, virtual-camera-prompt, completed states.
- `TutorialSceneLayer` or `.tutorial` layer kind in the scene model.
- Native SwiftUI onboarding views:
  - `OnboardingWelcomeCard`
  - `TutorialSceneCardView`
  - `OnboardingInstructionPill`
  - `OnboardingSuccessToast`
  - `VirtualCameraPromptCard`
- Scene event hooks that advance onboarding only after real behavior thresholds.
- Mouse/trackpad fallback events so the tutorial can be tested without hand tracking.

#### Refactor

- Keep onboarding copy centralized and original to AirStage.
- Keep debug UI behind the debug overlay setting.
- Keep tutorial layer logic reusable by normal scene interactions.

#### Acceptance Criteria

- Onboarding welcome card visible on first run.
- `Show me` adds exactly one tutorial scene item.
- Steps progress after real move/scale/shrink/remove behavior.
- Tutorial item can be manipulated by the same scene commands as normal layers.
- Virtual camera prompt appears only after tutorial completion or skip.
- Can complete and persist.
- Can reset/show from settings later.
- Logs show onboarding step changes.
- No static onboarding card PNGs are added to app assets.
- Red privacy masks from screenshots are ignored.

#### Suggested `/goal` Prompt

Implement Slice 15: first-run onboarding state machine and real tutorial scene item. Read `docs/AirStage_ONBOARDING_UI_REFERENCE.md`, `docs/AirStage_ASSET_POLICY.md`, and `ui-reference/onboarding/`. Write state-machine and scene-store tests first. Then render native SwiftUI onboarding cards/toasts/pills over the live preview. The tutorial card must be a real scene item, not a bitmap or fake overlay. Do not implement virtual camera output yet.

### Slice 16 — Settings Window With Persisted Toggles

#### Behaviour

Settings window shows grouped native sections and persisted toggles for Launch at login, Debug overlay, Hand control, Snap to grid, and Onboarding reset/show.

#### Why this slice exists

Settings are needed for debug and hand control, and must match native quality.

#### Red

Suggested tests:

- `testDebugOverlaySettingPersists`
- `testHandControlSettingPersists`
- `testSnapToGridSettingPersists`
- `testResetOnboardingClearsCompletedState`

#### Green

Implement settings store using `UserDefaults`/`@AppStorage` behind testable adapter. Add SettingsView.

#### Refactor

Keep launch-at-login as no-op/logged if ServiceManagement is not implemented yet.

#### Acceptance Criteria

- Settings window opens.
- Toggles visible and persist.
- Reset onboarding works.
- Logs show setting changes.

#### Suggested `/goal` Prompt

Implement Slice 16: settings window and persisted toggles. Tests first with an isolated UserDefaults suite. Then add grouped native Settings UI. Log setting changes. Launch at login can be a safe stub unless already supported.

---

### Slice 17 — Debug Overlay

#### Behaviour

When Debug overlay is enabled, preview shows useful debug state: permission status, layer count, selected layer, hand control status, and gesture state placeholder.

#### Why this slice exists

The user wants to run in Xcode and see what is happening. Visual debug state helps alongside logs.

#### Red

Suggested tests:

- `testDebugOverlayHiddenByDefault`
- `testDebugOverlayVisibleWhenSettingEnabled`
- `testDebugOverlayShowsLayerCountAndSelectedLayer`

#### Green

Implement debug overlay view bound to scene/settings state.

#### Refactor

Keep debug overlay read-only.

#### Acceptance Criteria

- Overlay off by default.
- Toggle shows overlay.
- Overlay updates with layer count/selection.
- Logs still emitted; overlay does not replace logs.

#### Suggested `/goal` Prompt

Implement Slice 17: debug overlay controlled by setting. Write tests first for visibility and displayed state. Then add read-only overlay in preview. Do not add hand tracking yet.

---

### Slice 18 — Snap to Grid Behaviour

#### Behaviour

When Snap to grid is enabled, moved layers snap to a simple grid. When disabled, movement is free.

#### Why this slice exists

Snap to grid is present in settings and helps keep the stage tidy.

#### Red

Suggested tests:

- `testSnapToGridRoundsLayerPositionWhenEnabled`
- `testSnapToGridDoesNotChangePositionWhenDisabled`
- `testSnapToGridAppliesOnlyAfterDragEnd`

#### Green

Implement grid snapping in scene geometry/drag end.

#### Refactor

Keep grid size centralized.

#### Acceptance Criteria

- Toggle controls snapping.
- Drag remains smooth; snap happens at end.
- Logs show snap result when applied.

#### Suggested `/goal` Prompt

Implement Slice 18: Snap to grid behaviour. Write pure geometry tests first. Then apply snapping on drag end when setting is enabled. Add debug logs. Do not change layer limits/removal.

---

### Slice 19 — Vision Hand Pose Adapter With Fake-Tested Gesture Frames

#### Behaviour

The app has a hand pose tracking adapter. Tests can feed fake hand frames without using the real camera or Vision.

#### Why this slice exists

Hand tracking must be testable before live Vision integration.

#### Red

Suggested tests:

- `testFakeHandPoseFrameCanRepresentPinchCandidate`
- `testNoLandmarksProducesNoGesture`
- `testLowConfidenceFrameIgnored`

#### Green

Create `HandPoseFrame`, `HandPoseTracking` protocol, fake tracker, and initial `VisionHandPoseTracker` wrapper.

#### Refactor

Do not let UI depend directly on Vision.

#### Acceptance Criteria

- Gesture tests can run without camera.
- Real Vision adapter compiles.
- Debug logs show tracker status.

#### Suggested `/goal` Prompt

Implement Slice 19: hand pose tracking adapter. Write tests first using fake hand frames. Then add protocol and minimal Vision-backed adapter that compiles. Do not connect it to layer movement yet.

---

### Slice 20 — Pinch Detection Gesture Engine

#### Behaviour

Given hand pose frames, the gesture engine detects pinch began, moved, and ended states.

#### Why this slice exists

Layer control should depend on stable gesture events, not raw Vision landmarks.

#### Red

Suggested tests:

- `testCloseThumbAndIndexStartsPinch`
- `testPinchMovementProducesMovedEvent`
- `testSeparatedFingersEndPinch`
- `testLowConfidenceDoesNotStartPinch`

#### Green

Implement simple distance-threshold pinch engine.

#### Refactor

Keep thresholds centralized and adjustable.

#### Acceptance Criteria

- Pinch state is deterministic in tests.
- Gesture logs show began/moved/ended.
- No UI movement yet.

#### Suggested `/goal` Prompt

Implement Slice 20: pinch detection gesture engine. Write tests first with fake hand frames. Then implement threshold-based pinch events and logs. Do not move layers yet.

---

### Slice 21 — Pinch-to-Grab Selected Layer

#### Behaviour

When hand control is enabled, a pinch can grab and move the selected/top target layer in preview.

#### Why this slice exists

This is the core “touch the screen share” magic.

#### Red

Suggested tests:

- `testPinchBeginSelectsTopLayerAtGesturePoint`
- `testPinchMoveUpdatesGrabbedLayerPosition`
- `testPinchEndReleasesLayer`
- `testHandControlDisabledIgnoresPinchEvents`

#### Green

Connect gesture events to scene store movement. Use fake gesture source in tests; real Vision can be manually QA’d.

#### Refactor

Keep hand coordinate mapping isolated.

#### Acceptance Criteria

- With hand control on, pinch moves a layer.
- With hand control off, pinch does nothing.
- Debug overlay shows pinch state.
- Logs show pinch grab/move/release.

#### Suggested `/goal` Prompt

Implement Slice 21: pinch-to-grab selected/top layer. Tests first with fake gesture events. Then wire gesture engine to scene movement. Add debug overlay state and logs. Do not add advanced gestures.

---

### Slice 22 — ScreenCaptureKit Window/Screen Layer

#### Behaviour

User can choose one window/screen capture and add it as a live layer. A second window layer is blocked by scene limits.

#### Why this slice exists

Window sharing is a core AirStage layer type and must use native ScreenCaptureKit.

#### Red

Use fake capture source for tests.

Suggested tests:

- `testShareWindowAddsWindowCaptureLayer`
- `testCannotAddSecondWindowCaptureLayer`
- `testWindowCaptureFailureShowsFriendlyError`

#### Green

Add ScreenCaptureKit picker/source wrapper and placeholder/live layer rendering. Degrade gracefully if permission missing.

#### Refactor

Keep ScreenCaptureKit behind protocol.

#### Acceptance Criteria

- Share Window or Screen opens native flow.
- One live capture layer can be added.
- Second is blocked with friendly message.
- Logs show capture start/failure.

#### Suggested `/goal` Prompt

Implement Slice 22: ScreenCaptureKit window/screen layer. Tests first with fake capture source. Then add native ScreenCaptureKit wrapper. Enforce one-window limit. Do not implement iPhone/iPad sharing.

---

### Slice 23 — Compositor Frame Pipeline Spike

#### Behaviour

The app can produce a composed frame representation from camera background and overlay layers, suitable for later virtual camera output.

#### Why this slice exists

Virtual camera needs a stable frame pipeline. Do this before extension work.

#### Red

Suggested tests:

- `testCompositorReceivesCameraFrameAndLayerSnapshot`
- `testCompositorOrdersLayersByZIndex`
- `testCompositorProducesOutputFrameMetadata`

#### Green

Implement minimal compositor abstraction. It may start with metadata/test renderer before full CoreImage/Metal rendering.

#### Refactor

Keep UI rendering and output rendering responsibilities clear.

#### Acceptance Criteria

- Compositor can be tested without real camera.
- Layer ordering is deterministic.
- Logs show frame pipeline status without spamming info logs.

#### Suggested `/goal` Prompt

Implement Slice 23: compositor frame pipeline abstraction. Tests first for layer ordering and output metadata. Then add minimal renderer abstraction. Do not add virtual camera extension yet.

---

### Slice 24 — Virtual Camera Extension Integration Gate

#### Behaviour

The app has an explicit virtual camera integration path/gate. It can request install/activation and report status, but only after preview pipeline exists.

#### Why this slice exists

Virtual camera is the hardest system integration and must be isolated.

#### Red

Tests around status model and installer intent, not actual system extension install.

Suggested tests:

- `testVirtualCameraDisabledBeforeSetup`
- `testInstallRequestTransitionsToPendingApproval`
- `testExtensionStatusMessagesAreUserFriendly`

#### Green

Add virtual camera status model and installer wrapper. Create extension target only if signing/capabilities are available. Otherwise leave a clearly logged/manual-gated implementation note.

#### Refactor

Keep virtual camera output separate from preview UI.

#### Acceptance Criteria

- UI explains virtual camera status.
- Install request is logged.
- No crash when extension unavailable in development.
- Manual QA checklist documents `/Applications` and System Settings approval requirements.

#### Suggested `/goal` Prompt

Implement Slice 24: virtual camera integration gate/status. Tests first for status model and install intent. Then add minimal SystemExtensions wrapper/extension target only if project signing supports it. Do not break local preview.

---

### Slice 25 — Final Native Polish and Regression Pass

#### Behaviour

All MVP flows work together without regressions. UI feels native and reference-aligned without brittle copying.

#### Why this slice exists

Integration work often breaks earlier flows. This slice is verification and polish, not feature expansion.

#### Red

Add regression tests only for bugs found during QA.

Suggested scenarios:

- Add note → edit → drag → remove outside.
- Add image → resize → delete.
- Add window → try adding second window → blocked.
- Complete onboarding → reset from settings → appears again.
- Debug overlay toggled on/off.

#### Green

Fix failing tests and manual QA issues with smallest changes.

#### Refactor

Remove dead code, tighten naming, keep logs useful.

#### Acceptance Criteria

- Full test suite passes.
- App builds cleanly.
- Manual QA checklist passes.
- No Shacam assets/copy are shipped.
- Logs are useful but not spammy.

#### Suggested `/goal` Prompt

Implement Slice 25: final regression and native polish pass. Run full tests/build, add regression tests for any failures, and fix only issues found. Verify UI against design guide/reference screenshots without copying assets or testing exact styling.

---

## Final Verification Checklist

### Commands

Use the commands discoverable in the repo. If this is an Xcode project, prefer:

```bash
xcodebuild test -scheme AirStage -destination 'platform=macOS'
xcodebuild build -scheme AirStage -destination 'platform=macOS'
```

If package-based:

```bash
swift test
swift build
```

### Manual QA

- [ ] Launch app.
- [ ] Confirm menu bar item appears.
- [ ] Open preview.
- [ ] Deny camera permission and verify friendly state.
- [ ] Grant camera permission and verify camera feed.
- [ ] Add note.
- [ ] Edit note.
- [ ] Add image.
- [ ] Select/drag/resize layers.
- [ ] Drag outside and release to remove.
- [ ] Add layers until full and verify Scene is full behaviour.
- [ ] Use Remove Layer menu.
- [ ] Use Delete key.
- [ ] Use quick-add toolbar.
- [ ] Complete onboarding.
- [ ] Reset onboarding from settings.
- [ ] No static bitmap onboarding UI assets are used.
- [ ] Red privacy masks from reference screenshots do not appear in the app.
- [ ] Debug confidence labels are hidden unless debug overlay is enabled.
- [ ] Toggle debug overlay.
- [ ] Toggle hand control.
- [ ] Test pinch with real camera.
- [ ] Add one ScreenCaptureKit window layer.
- [ ] Verify second window layer is blocked.
- [ ] Check Xcode console logs.
- [ ] If virtual camera slice is implemented, test QuickTime first, then OBS/Zoom/Meet.

### Accessibility

- [ ] Key buttons have accessible labels.
- [ ] Settings toggles are reachable with keyboard.
- [ ] Onboarding card text is readable.
- [ ] Delete/remove actions are not only gesture-based.
- [ ] Debug overlay does not block core interaction permanently.

### Regression

- [ ] Layer limits still work after adding image/window/notes.
- [ ] Onboarding does not reappear after completion unless reset.
- [ ] Settings persist after relaunch.
- [ ] Scene full state does not crash add flows.
- [ ] Removing selected layer clears selection safely.
- [ ] Hand control disabled ignores gestures.

## Suggested Execution Order

Run the slices in exact order:

1. Slice 1 — Project Foundation, Test Target, and Logger
2. Slice 2 — Native Menu Bar Shell
3. Slice 3 — Preview Window Opens With Permission Placeholder
4. Slice 4 — Camera Permission Request and Live Preview Adapter
5. Slice 5 — Scene Layer Model and Limits
6. Slice 6 — Add Note Layer From Menu
7. Slice 7 — Edit Note Text
8. Slice 8 — Add Image Layer From Picker and Drop/Paste Handler
9. Slice 9 — Select, Bring to Front, and Delete Layer
10. Slice 10 — Mouse Drag Layer
11. Slice 11 — Resize Layer With Handles
12. Slice 12 — Drag Outside Preview to Remove
13. Slice 13 — Remove Layer Menu Reflects Current Layers
14. Slice 14 — Preview Hover Quick-Add Toolbar
15. Slice 15 — First-Run Onboarding State Machine and Real Tutorial Scene Item
16. Slice 16 — Settings Window With Persisted Toggles
17. Slice 17 — Debug Overlay
18. Slice 18 — Snap to Grid Behaviour
19. Slice 19 — Vision Hand Pose Adapter With Fake-Tested Gesture Frames
20. Slice 20 — Pinch Detection Gesture Engine
21. Slice 21 — Pinch-to-Grab Selected Layer
22. Slice 22 — ScreenCaptureKit Window/Screen Layer
23. Slice 23 — Compositor Frame Pipeline Spike
24. Slice 24 — Virtual Camera Extension Integration Gate
25. Slice 25 — Final Native Polish and Regression Pass

## Notes for Codex

- Stay behaviour-driven.
- Write failing tests first.
- Do not combine slices.
- Do not skip debug logs.
- Do not over-engineer.
- Inspect existing code before editing.
- Preserve existing architecture unless it blocks the slice.
- Do not implement features from later slices early.
- Do not test exact visual styling.
- Ask only when genuinely blocked.


## Onboarding-Specific Codex Rules

When implementing onboarding, use the reference screenshots in `ui-reference/onboarding/` for layout and behavior only.

Do not:

- Add image assets for the pink cards.
- Add image assets for selection boxes, gesture dots, handles, instruction pills, or success toasts.
- Implement red privacy masks.
- Show raw debug confidence values in production UI.

Do:

- Draw onboarding UI natively.
- Spawn a real tutorial scene item.
- Advance steps from real scene events.
- Keep mouse/trackpad fallback testable before Vision gestures are complete.
