# AirStage — TDD Progress Todo

Use this file as the execution tracker. Codex should update it after every completed slice with:

- date/time
- files changed
- tests added
- test command result
- build command result
- manual notes
- debug logs added
- any assumptions/decisions

## Status Legend

- [ ] Not started
- [~] In progress
- [x] Complete
- [!] Blocked

## Slices

- [x] Slice 1 — Project Foundation, Test Target, and Logger
- [x] Slice 2 — Native Menu Bar Shell
- [x] Slice 3 — Preview Window Opens With Permission Placeholder
- [x] Slice 4 — Camera Permission Request and Live Preview Adapter
- [x] Slice 5 — Scene Layer Model and Limits
- [x] Slice 6 — Add Note Layer From Menu
- [x] Slice 7 — Edit Note Text
- [x] Slice 8 — Add Image Layer From Picker and Drop/Paste Handler
- [x] Slice 9 — Select, Bring to Front, and Delete Layer
- [x] Slice 10 — Mouse Drag Layer
- [x] Slice 11 — Resize Layer With Handles
- [x] Slice 12 — Drag Outside Preview to Remove
- [x] Slice 13 — Remove Layer Menu Reflects Current Layers
- [x] Slice 14 — Preview Hover Quick-Add Toolbar
- [x] Slice 15 — First-Run Onboarding State Machine and Real Tutorial Scene Item
- [x] Slice 16 — Settings Window With Persisted Toggles
- [x] Slice 17 — Debug Overlay
- [x] Slice 18 — Snap to Grid Behaviour
- [x] Slice 19 — Vision Hand Pose Adapter With Fake-Tested Gesture Frames
- [x] Slice 20 — Pinch Detection Gesture Engine
- [x] Slice 21 — Pinch-to-Grab Selected Layer
- [x] Slice 22 — ScreenCaptureKit Window/Screen Layer
- [x] Slice 23 — Compositor Frame Pipeline Spike
- [x] Slice 24 — Virtual Camera Extension Integration Gate
- [x] Slice 25 — Final Native Polish and Regression Pass
- [x] Slice 26 — Onboarding Gesture Fix and Shacam-Style Debug Layer
- [x] Slice 27 — Post-Onboarding Prompt, Dynamic Coordinates, and Menu Gating
- [x] Patch — Auto-Open Preview Window on Launch


## Documentation Integration Notes

- 2026-06-30: Package integrated with `AGENTS.md`, `docs/00_PROJECT_INDEX.md`, onboarding reference docs, asset policy, icon/DMG guide, packaging script, and cleaned reference folders.
- Onboarding screenshots live in `ui-reference/onboarding/` and are references only.
- Pink tutorial UI must be drawn natively, not shipped as bitmap assets.
- Red rectangles in screenshots are privacy masks only.

## Completed Slice Notes

### Slice 1

Status: Complete — 2026-06-30

Files changed:
- `AirStage/Package.swift` — new; defines AirStage library, AirStageApp executable, AirStageTests test target; macOS 14+
- `AirStage/Sources/AirStage/AppLog.swift` — new; OSLog.Logger categories (app, menu, camera, scene, sources, gestures, onboarding, settings, virtualCamera)
- `AirStage/Sources/AirStage/LaunchDiagnostics.swift` — new; logStartup() emits app launch info log
- `AirStage/Sources/AirStageApp/main.swift` — new; app entry point, calls LaunchDiagnostics.logStartup(), holds RunLoop
- `AirStage/Tests/AirStageTests/AppLogTests.swift` — new; testAppLogCategoriesExist, testLaunchDiagnosticsCanBeCreated

Tests added:
- `testAppLogCategoriesExist` ✓
- `testLaunchDiagnosticsCanBeCreated` ✓

Commands run:
- `swift test` → Build complete, 2 tests passed, 0 failures

Debug logs added:
- `AppLog.app.info("AirStage launched version=… ")` via LaunchDiagnostics.logStartup()

Assumptions/decisions:
- Used Swift Package (library + executable + test) rather than bare Xcode project; buildable from CLI, openable in Xcode. SwiftUI/AppKit entry point added in Slice 2.
- All public API uses `public` access modifier so test target can import the library target.

Remaining risks:
- main.swift RunLoop.main.run() is a placeholder; real NSApplication lifecycle needed in Slice 2.
- Bundle.main.infoDictionary will return nil when running tests; logStartup() gracefully falls back to "dev".

### Slice 2

Status: Complete — 2026-06-30

Files changed:
- `AirStage/Sources/AirStage/Menu/MenuActionID.swift` — new; stable enum for all menu action IDs
- `AirStage/Sources/AirStage/Menu/MenuIntent.swift` — new; intent enum emitted to app shell
- `AirStage/Sources/AirStage/Menu/MenuAction.swift` — new; struct with id, title, isEnabled, disabledReason
- `AirStage/Sources/AirStage/Menu/MenuModel.swift` — new; testable model, select() emits intent via onIntent closure
- `AirStage/Sources/AirStageApp/AppDelegate.swift` — new; NSStatusItem + NSMenu wired to MenuModel
- `AirStage/Sources/AirStageApp/main.swift` — updated; NSApplication + AppDelegate lifecycle, .accessory activation policy

Tests added:
- `testMenuContainsPrimaryActions` ✓
- `testDisabledActionsExposeReasonWhenUnavailable` ✓
- `testSelectingShowPreviewEmitsIntent` ✓
- `testSelectingSettingsEmitsIntent` ✓

Commands run:
- `swift test` → Build complete, 6/6 passed, 0 failures

Debug logs added:
- `AppLog.menu.info("Menu action selected action=…")` in MenuModel.select() and AppDelegate.handleMenuAction()
- `AppLog.menu.info("Preview requested")` / `"Settings requested"` in AppDelegate

Assumptions/decisions:
- shareWindowOrScreen and camera are disabled with disabledReason; they become enabled in later slices.
- removeLayer is initially disabled (no layers yet); Slice 13 will make it dynamic.
- AppDelegate uses NSStatusItem with SF Symbol camera.on.rectangle as status bar icon placeholder.
- app.setActivationPolicy(.accessory) keeps app out of Dock; LSUIElement plist key will be added when a proper Xcode project is created.

Remaining risks:
- Status bar icon is an SF Symbol placeholder; real app icon designed in later slice.
- No Info.plist yet (package build); LSUIElement must be set programmatically for now.

### Slice 3

Status: Complete — 2026-06-30

Files changed:
- `Sources/AirStage/Camera/CameraPermissionStatus.swift` — new; platform-agnostic enum (notDetermined, authorized, denied, restricted)
- `Sources/AirStage/Camera/CameraPermissionService.swift` — new; protocol abstracting AVCaptureDevice auth
- `Sources/AirStage/Camera/FakeCameraPermissionService.swift` — new; test double with settable status
- `Sources/AirStage/Preview/CameraState.swift` — new; observable enum (permissionRequired, ready, running, failed)
- `Sources/AirStage/Preview/PreviewViewModel.swift` — new; resolves permission → CameraState, logs status
- `Sources/AirStageApp/AVCameraPermissionService.swift` — new; real AVFoundation-backed service (lives in App target only)
- `Sources/AirStageApp/PreviewWindowController.swift` — new; NSWindow with permission placeholder text
- `Sources/AirStageApp/AppDelegate.swift` — updated; wires onIntent → showPreview/settings, creates PreviewWindowController on demand

Tests added:
- `testPreviewShowsCameraPermissionRequiredWhenPermissionMissing` ✓
- `testPreviewShowsCameraPermissionRequiredWhenPermissionDenied` ✓
- `testShowPreviewActionCreatesVisiblePreviewState` ✓
- `testCameraPermissionStateIsLogged` ✓

Commands run:
- `swift test` → Build complete, 10/10 passed, 0 failures

Debug logs added:
- `AppLog.camera.info("Camera permission status=…")` in PreviewViewModel.init
- `AppLog.camera.info("Preview camera state=…")` in PreviewViewModel.init
- `AppLog.camera.info("Preview window created cameraState=…")` in PreviewWindowController.init
- `AppLog.menu.info("Preview requested")` in PreviewWindowController.showWindow

Assumptions/decisions:
- AVCameraPermissionService lives in AirStageApp (not AirStage library) to avoid pulling AVFoundation into the pure-logic library target.
- FakeCameraPermissionService is public and lives in the AirStage library so tests can use it directly without bridging.
- PreviewWindowController shows NSTextField placeholder; actual camera preview layer added in Slice 4.

Remaining risks:
- No real camera feed yet (Slice 4).
- NSWindow layout uses frame-based approach; SwiftUI hosting view optional in a later refactor.
- Permission request (the actual AVCaptureDevice.requestAccess call) deferred to Slice 4.

### Slice 4

Status: Complete — 2026-06-30

Files changed:
- `Sources/AirStage/Camera/RequestableCameraPermissionService.swift` — new; protocol extending CameraPermissionService with async requestPermission
- `Sources/AirStage/Camera/FakeRequestableCameraPermissionService.swift` — new; test double with configurable grant/deny
- `Sources/AirStage/Camera/CameraSession.swift` — new; protocol with start(completion:) and stop()
- `Sources/AirStage/Camera/FakeCameraSession.swift` — new; test double with failOnStart flag
- `Sources/AirStage/Preview/PreviewViewModel.swift` — updated; added requestCameraPermission(), startCameraSessionIfReady(), stopCameraSession(), permissionDeniedMessage
- `Sources/AirStageApp/AVCameraPermissionService.swift` — updated; now conforms to RequestableCameraPermissionService, adds requestPermission() via AVCaptureDevice.requestAccess
- `Sources/AirStageApp/AVCameraSession.swift` — new; AVCaptureSession-backed real implementation, exposes .session for preview layer
- `Sources/AirStageApp/PreviewWindowController.swift` — updated; wires requestPermission → startSession → refresh(), attaches AVCaptureVideoPreviewLayer when running

Tests added:
- `testRequestingCameraPermissionTransitionsToGrantedState` ✓
- `testDeniedPermissionShowsRecoveryMessage` ✓
- `testGrantedPermissionStartsCameraSession` ✓
- `testDeniedPermissionDoesNotStartCameraSession` ✓
- `testCameraSessionFailureTransitionsToFailedState` ✓

Commands run:
- `swift test` → Build complete, 15/15 passed, 0 failures

Debug logs added:
- `AppLog.camera.info("Camera permission granted/denied")` in PreviewViewModel.requestCameraPermission
- `AppLog.camera.info("Camera session starting")` / `"running"` / `.error("failed")` in startCameraSessionIfReady
- `AppLog.camera.info("Camera session starting device=…")` in AVCameraSession.start
- `AppLog.camera.info("Camera session stopped")` in PreviewViewModel.stopCameraSession

Assumptions/decisions:
- AVCameraSession runs on global(qos:.userInitiated) then calls completion on main thread; aligns with AVFoundation threading rules.
- AVCaptureVideoPreviewLayer attaches on .running transition; frame keeps in sync via NSView.frameDidChangeNotification.
- FakeRequestableCameraPermissionService is in the AirStage library (not test-only) so tests can import it without bridging tricks.

Remaining risks:
- Manual QA needed to verify real camera feed renders with correct aspect fill.
- NSWindow does not have an NSApplication entry point in the package build; Dock presence suppressed via .accessory policy.
- No entitlement key (NSCameraUsageDescription) in the package build yet; must be added when Xcode project is created.

### Repair/Refactor Slice

Status: Complete — 2026-06-30

Files changed:
- `Sources/AirStage/Preview/PreviewViewModel.swift` — added `onStateChange` callback via `didSet` on `cameraState`; fires on every transition
- `Sources/AirStageApp/PreviewWindowController.swift` — wired `viewModel.onStateChange` to call `refresh()` so `AVCaptureVideoPreviewLayer` attaches when `cameraState` becomes `.running` after async session start
- `Sources/AirStageApp/AVCameraSession.swift` — rewritten `start()`: always calls `commitConfiguration()` via single-exit pattern; returns clear errors for no-device, can't-add-input, and input-creation failure; guards against duplicate `start()` calls with `hasStarted` flag; resets `hasStarted` on `stop()`
- `Sources/AirStageApp/AppDelegate.swift` — added `.quit` case in `handle()` that calls `NSApplication.shared.terminate(nil)`
- `Sources/AirStage/Menu/MenuModel.swift` — disabled `addNote`, `shareImage`, and `settings` with user-readable `disabledReason` strings
- `Sources/AirStage/Camera/FakeCameraPermissionService.swift` — **deleted** (moved to test target)
- `Sources/AirStage/Camera/FakeCameraSession.swift` — **deleted** (moved to test target)
- `Sources/AirStage/Camera/FakeRequestableCameraPermissionService.swift` — **deleted** (moved to test target)
- `Tests/AirStageTests/FakeCameraPermissionService.swift` — **new** (moved from production target)
- `Tests/AirStageTests/FakeCameraSession.swift` — **new** (moved from production target)
- `Tests/AirStageTests/FakeRequestableCameraPermissionService.swift` — **new** (moved from production target)
- `Tests/AirStageTests/PreviewViewModelTests.swift` — added `testOnStateChangeFiresWhenSessionStarts`, `testOnStateChangeFiresWhenSessionFails`, `testOnStateChangeFiresWhenPermissionGranted`
- `Tests/AirStageTests/MenuModelTests.swift` — added `testAddNoteIsDisabledWithReason`, `testShareImageIsDisabledWithReason`, `testSettingsIsDisabledWithReason`, `testShowPreviewIsEnabled`, `testQuitIsEnabled`, `testSelectingQuitEmitsIntent`, `testDisabledActionsDoNotEmitIntents`; removed `testSelectingSettingsEmitsIntent`
- `.gitignore` — **new**; excludes `.build/`, `__MACOSX/`, `.DS_Store`, `DerivedData/`, `*.xcuserdata`

Tests added/updated:
- 8 new tests, 15 existing tests — all 23 pass

Commands run:
- `swift test` → Build complete, 23/23 passed, 0 failures

Assumptions/decisions:
- `onStateChange` fires via `didSet` on `cameraState`; initial state set in init does not fire because no observer is set yet
- `onStateChange` is called on every state change, not just `.running`; `PreviewWindowController` uses it to call `refresh()` unconditionally
- `AVCameraSession.hasStarted` flag prevents duplicate input addition; reset on `stop()` to allow restart
- Fakes are no longer `public` since they live in the test target
- `.build/` was previously committed; `.gitignore` prevents future tracking

Remaining risks:
- Real AVCameraSession still requires hardware for integration testing
- Quit via `NSApplication.shared.terminate(nil)` is a synchronous termination; future slices may need graceful cleanup

### Cleanup/Consistency Repair Slice

Status: Complete — 2026-06-30

Files changed:
- `Sources/AirStage/Menu/MenuModel.swift` — `select(_:)` now guards on `action.isEnabled` before emitting intent; logs ignored disabled actions
- `Sources/AirStageApp/PreviewWindowController.swift` — added `resizeObserver` token; `refresh()` removes observer before detaching preview layer; `attachPreviewLayer` stores observer token instead of leaking a new one each call
- `.gitignore` — added `._*` and `.swiftpm/` patterns
- `Tests/AirStageTests/MenuModelTests.swift` — replaced `testSelectingSettingsEmitsIntent` with `testSelectingQuitEmitsIntent` + `testDisabledActionsDoNotEmitIntents`; preserved all other tests

Tests added/updated:
- 2 new tests (`testSelectingQuitEmitsIntent`, `testDisabledActionsDoNotEmitIntents`)
- 1 removed (`testSelectingSettingsEmitsIntent`)
- 24 tests total, all pass

Commands run:
- `swift test` → Build complete, 24/24 passed, 0 failures

Assumptions/decisions:
- `MenuModel.select(_:)` uses `actions.first(where:)` lookup to check enabled state; O(n) but actions array is small (<10) and immutable after init
- Resize observer is cleaned up in `refresh()` on every call, not just when the layer is attached — simpler and prevents stale observers
### Slice 5

Status: Complete — 2026-07-04

Files changed:
- `Sources/AirStage/Scene/SceneLayer.swift` — new; defines SceneLayer struct with properties, selection/removal states, and transformation properties
- `Sources/AirStage/Scene/SceneLimits.swift` — new; defines count limits, removal margin, and tutorial geometry/gesture state helpers
- `Sources/AirStage/Scene/SceneStore.swift` — new; implements layer limit checks, selection zIndex promotion, endDrag removal bounds, and oldest replacement
- `Tests/AirStageTests/SceneStoreTests.swift` — new; tests limit enforcement, selection zIndex, drag outside removal, and oldest replacement

Tests added:
- `testCanAddLayerWhenUnderLimit` ✓
- `testCannotExceedSixTotalLayers` ✓
- `testCannotAddMoreThanOneWindowCaptureLayer` ✓
- `testCannotAddMoreThanThreeImageLayers` ✓
- `testCannotAddMoreThanFourNoteLayers` ✓
- `testSceneFullOffersReplaceOldestOrCancel` ✓
- `testSelectingLayerRaisesZIndex` ✓
- `testReleasingOutsideRemovesLayer` ✓

Commands run:
- `swift test` → Build complete, 32/32 passed, 0 failures

Debug logs added:
- `AppLog.scene.info("Layer added id=... kind=... title=...")`
- `AppLog.scene.info("Layer selected id=...")`
- `AppLog.scene.info("Layer removed id=... reason=...")`
- `AppLog.scene.debug("Layer moved id=... x=... y=...")`
- `AppLog.scene.notice("Scene full kind=... total=...")`

Assumptions/decisions:
- Finding oldest layer to replace uses minimum zIndex among candidates (either within specific kind, or globally depending on limit type).
- zIndex increases for newly added or selected layers.
- Non-note limits (e.g. total 6, images 3, window 1) are also subject to oldest-replacement logic if `replaceOldestIfFull` is enabled.

Remaining risks:
- The UI layer does not bind to this store yet (to be implemented in Slice 6).

### Slice 6

Status: Complete — 2026-07-04

Files changed:
- `Sources/AirStage/Menu/MenuModel.swift` — enabled `.addNote` action by default, removing disabled placeholder
- `Sources/AirStageApp/AppDelegate.swift` — instantiated `SceneStore` and wired the `.addNote` intent to call `sceneStore.addNote` and open the preview window
- `Sources/AirStageApp/PreviewWindowController.swift` — updated initializer to accept `SceneStore` dependency and embed an `NSHostingView` rendering `PreviewView`
- `Sources/AirStageApp/PreviewView.swift` — new; SwiftUI view containing ZStack rendering sticky note layers and a fallback rendering for other layer kinds
- `Tests/AirStageTests/MenuModelTests.swift` — updated tests to verify `addNote` is enabled and emits intents properly
- `Tests/AirStageTests/AddNoteTests.swift` — new; tests menu action wiring, store insertion, and safe center spawning

Tests added:
- `testSelectingAddNoteEmitsIntentAndAddsNoteToStore` ✓
- `testNewNoteSpawnsInsidePreviewBounds` ✓

Commands run:
- `swift test` → Build complete, 34/34 passed, 0 failures

Debug logs added:
- `AppLog.menu.info("Menu action selected action=addNote")` (via existing MenuModel)
- `AppLog.scene.info("Layer added id=... kind=note title=...")` (via SceneStore)

Assumptions/decisions:
- New notes spawn at center `CGPoint(x: 320, y: 240)` with size `CGSize(width: 150, height: 150)` within `640x480` bounds.
- Overlaid transparent `NSHostingView` on top of camera container to keep AVFoundation session view separated from SwiftUI layers.

Remaining risks:
- Note text is not yet editable by the user (Slice 7).

### Slice 7

Status: Complete — 2026-07-04

Files changed:
- `Sources/AirStage/Scene/SceneLayer.swift` — added `displayTitle` computed property that falls back to "Empty Note" if empty
- `Sources/AirStage/Scene/SceneStore.swift` — added `updateNoteText(layerID:text:)` with truncated privacy logging
- `Sources/AirStageApp/PreviewView.swift` — updated `StickyNoteView` to show editable SwiftUI `TextField` when `layer.isSelected == true` using custom binding back to `SceneStore`
- `Tests/AirStageTests/EditNoteTests.swift` — new; tests note text updates, empty placeholders, and menu title reflection

Tests added:
- `testEditingNoteUpdatesLayerText` ✓
- `testEmptyNoteShowsPlaceholder` ✓
- `testEditedNoteTitleAppearsInRemoveLayerMenu` ✓

Commands run:
- `swift test` → Build complete, 37/37 passed, 0 failures

Debug logs added:
- `AppLog.scene.info("Layer text updated id=... title=...")` (via SceneStore)

Assumptions/decisions:
- Note text field is editable ONLY when selected (`layer.isSelected == true`) to prevent text selection gestures from colliding with layer move/resize gestures.
- Display title for empty notes falls back to "Empty Note" for menu presentation and testing verification.

Remaining risks:
- User cannot yet select layers using mouse click or select drag in the main preview window apart from clicking the note (fully implement selection/bring-to-front in Slice 9).

### Slice 8

Status: Complete — 2026-07-04

Files changed:
- `AirStage/Sources/AirStage/Scene/SceneLayer.swift` — added `imageURL: URL?` property and initializer support
- `AirStage/Sources/AirStage/Scene/SceneStore.swift` — added optional `imageURL` parameter to `addImage` and `addLayer`
- `AirStage/Sources/AirStage/Menu/MenuModel.swift` — enabled `.shareImage` menu action
- `AirStage/Sources/AirStage/Sources/ImageSourcePicker.swift` — new; protocol for image picking interface
- `AirStage/Sources/AirStage/Sources/ImageImporter.swift` — new; handles validation, file title, and limits
- `AirStage/Sources/AirStage/Sources/DropPasteHandler.swift` — new; handles drop and paste inputs
- `AirStage/Sources/AirStageApp/NSOpenPanelImageSourcePicker.swift` — new; NSOpenPanel wrapper
- `AirStage/Sources/AirStageApp/AppDelegate.swift` — handles `.shareImage` intent with picker & import
- `AirStage/Sources/AirStageApp/PreviewWindowController.swift` — added `PreviewWindow` subclass to intercept cmd-V paste and wired to `DropPasteHandler`
- `AirStage/Sources/AirStageApp/PreviewView.swift` — added `ImageCardView` and `.onDrop` support
- `AirStage/Tests/AirStageTests/ImageImportTests.swift` — new; tests file pick/import, formats, limits
- `AirStage/Tests/AirStageTests/MenuModelTests.swift` — updated tests for enabled `.shareImage` action

Tests added/updated:
- `testShareImageAddsImageLayerFromSelectedFile` ✓
- `testUnsupportedFileShowsFriendlyError` ✓
- `testImageLayerUsesFilenameAsTitle` ✓
- `testImageLayerLimitIsEnforced` ✓
- `testSelectingShareImageEmitsIntent` ✓
- `testShareImageIsEnabled` ✓

Commands run:
- `swift test` → Build complete, 42 tests passed, 0 failures

Debug logs added:
- `AppLog.sources.info("Importing image from path=…")`
- `AppLog.sources.error("Failed to import image: unsupported format path=…")`
- `AppLog.sources.error("Failed to add image layer to store: …")`

Assumptions/decisions:
- Formats validated using UTType check (conforming to `UTType.image`) with filename extension backup.
- Image layers default to `size: CGSize(width: 200, height: 150)`.
- Alerts shown on main thread in case of import failures.

Remaining risks:
- Sandbox access restrictions when running outside dev mode could impact loading arbitrary external file URLs; security scope bookmarks may be needed in a future sandbox-specific build.

### Slice 9

Status: Complete — 2026-07-04

Files changed:
- `AirStage/Sources/AirStage/Scene/SceneStore.swift` — implemented `deleteSelectedLayer()` method
- `AirStage/Sources/AirStageApp/PreviewWindowController.swift` — updated `PreviewWindow` subclass to intercept Delete/Backspace keys and route to store deletion
- `AirStage/Tests/AirStageTests/SceneStoreTests.swift` — added tests for exclusive selection, z-index, and Delete removal

Tests added/updated:
- `testSelectingLayerMarksOnlyThatLayerSelected` ✓
- `testDeleteRemovesSelectedLayer` ✓
- `testDeleteWithNoSelectionDoesNothing` ✓
- `testSelectingLayerRaisesZIndex` ✓ (existing)

Commands run:
- `swift test` → Build complete, 45 tests passed, 0 failures

Debug logs added:
- `AppLog.scene.info("Layer removed id=... reason=deleteKey")` (via existing removeLayer log in deleteSelectedLayer)

Assumptions/decisions:
- Intercepts Delete (key code 51) and Forward Delete (key code 117) on macOS.
- Deletion applies only if a layer is currently selected.

Remaining risks:
- Key equivalent interception could clash with native text input fields inside note editing. However, editing text requires text selection focus which has its own key handling, so this should not conflict under normal use.

### Slice 10

Status: Complete — 2026-07-04

Files changed:
- `AirStage/Sources/AirStage/Scene/SceneGeometry.swift` — new; implements `clampPosition` to keep layers visible inside scene bounds
- `AirStage/Sources/AirStage/Scene/SceneStore.swift` — added `dragLayer(withID:to:sceneBounds:)` and updated `endDrag` to clamp final positioning using `SceneGeometry`
- `AirStage/Sources/AirStageApp/PreviewView.swift` — attached SwiftUI `DragGesture` to note and image cards
- `AirStage/Tests/AirStageTests/SceneGeometryTests.swift` — new; tests position clamping bounds
- `AirStage/Tests/AirStageTests/SceneStoreTests.swift` — added tests for drag updating, clamping visibility, and unknown layers

Tests added/updated:
- `testClampPositionKeepsLayerPartiallyVisible` ✓
- `testDraggingLayerUpdatesPosition` ✓
- `testDraggingLayerKeepsLayerVisibleForNormalDrag` ✓
- `testDraggingUnknownLayerDoesNothing` ✓

Commands run:
- `swift test` → Build complete, 49 tests passed, 0 failures

Debug logs added:
- `AppLog.scene.debug("Layer dragging id=... x=... y=...")` (via dragLayer)
- `AppLog.scene.debug("Layer moved id=... x=... y=...")` (via endDrag)

Assumptions/decisions:
- Clamping keeps at least 20pt of the layer's bounding box visible inside the scene bounds.
- Selection is promoted immediately when a drag gesture begins to bring the dragged layer to front.

Remaining risks:
- Dragging coordinates are based on window scale; scaling window size will map back to the same coordinate scale. Window resizing changes coordinates accordingly.

### Slice 11

Status: Complete — 2026-07-04

Files changed:
- `AirStage/Sources/AirStage/Scene/SceneLimits.swift` — added min size constants for notes, images, window, and tutorial layers
- `AirStage/Sources/AirStage/Scene/SceneStore.swift` — added `beginResize`, `endResize`, and `resizeLayer` with clamping checks
- `AirStage/Sources/AirStageApp/PreviewView.swift` — added `SelectedLayerOverlay` with circle handle and dashed outline, added `DefaultCardView` fallback, wired overlay to note, image, and default cards
- `AirStage/Tests/AirStageTests/SceneStoreTests.swift` — added `testResizingLayerUpdatesSize`, `testResizeDoesNotGoBelowMinimumSize`, and `testResizeKeepsLayerInsidePreviewWhenPossible`

Tests added/updated:
- `testResizingLayerUpdatesSize` ✓
- `testResizeDoesNotGoBelowMinimumSize` ✓
- `testResizeKeepsLayerInsidePreviewWhenPossible` ✓

Commands run:
- `swift test` → Build complete, 52 tests passed, 0 failures

Debug logs added:
- `AppLog.scene.info("Layer resize began id=...")`
- `AppLog.scene.info("Layer resize ended id=... size=...x...")`
- `AppLog.scene.debug("Layer resized id=... width=... height=...")`

Assumptions/decisions:
- Dragging bottom-right corner scales width/height while maintaining top-left position.
- Clamping prevents layers from going completely offscreen (at least 20pt edges remain inside bounds).

Remaining risks:
- Corner handle dragging might clash with window resizing bounds if dragged right at the window borders.

### Slice 12

Status: Complete — 2026-07-04

Files changed:
- `AirStage/Sources/AirStage/Scene/SceneStore.swift` — updated `dragLayer` to check for arming state transitions and log them; updated `endDrag` to clamp position on release inside and clear `isBeingRemoved`.
- `AirStage/Sources/AirStageApp/PreviewView.swift` — added red removal badge and opacity/saturation effects, hid resize handles when `isBeingRemoved` is true.
- `AirStage/Tests/AirStageTests/SceneStoreTests.swift` — updated `testDraggingLayerKeepsLayerVisibleForNormalDrag` to cover drag updating and end-drag clamping; added `testDraggingOutsideArmsRemovalState`, `testDraggingBackInsideCancelsRemovalState`, and `testReleasingInsideKeepsLayer`.

Tests added/updated:
- `testDraggingOutsideArmsRemovalState` ✓
- `testDraggingBackInsideCancelsRemovalState` ✓
- `testReleasingInsideKeepsLayer` ✓

Commands run:
- `swift test` → Build complete, 55 tests passed, 0 failures

Debug logs added:
- `AppLog.scene.info("Layer removal armed id=... reason=draggedOutside")`
- `AppLog.scene.info("Layer removal cancelled id=...")`

Assumptions/decisions:
- We allow layers to follow the mouse outside the preview window during drag to visually indicate removal intent.
- Clamping is deferred until `endDrag` if the layer is released inside the preview.

Remaining risks:
- Fast cursor movements outside the preview window might bypass the visual arming check if coordinates skip boundary intervals, though standard gesture updates poll at a high enough frequency to prevent this.

### Slice 13

Status: Complete — 2026-07-04

Files changed:
- `AirStage/Sources/AirStage/Menu/MenuModel.swift` — modified initializer to accept optional `SceneStore` reference; updated `actions` to dynamically determine `.removeLayer` status based on active layers; added `removableLayers` and `removeLayer(withID:)`.
- `AirStage/Sources/AirStageApp/AppDelegate.swift` — initialized `menuModel` lazily with `sceneStore`; implemented `NSMenuDelegate` to rebuild status bar menu and dynamically populate `.removeLayer` submenu before showing; added `handleRemoveLayerAction` selector.
- `AirStage/Tests/AirStageTests/MenuModelTests.swift` — added `testRemoveLayerMenuDisabledWhenNoLayersExist`, `testRemoveLayerMenuListsCurrentLayers`, and `testSelectingRemoveLayerMenuItemRemovesThatLayer`.

Tests added/updated:
- `testRemoveLayerMenuDisabledWhenNoLayersExist` ✓
- `testRemoveLayerMenuListsCurrentLayers` ✓
- `testSelectingRemoveLayerMenuItemRemovesThatLayer` ✓

Commands run:
- `swift test` → Build complete, 58 tests passed, 0 failures

Debug logs added:
- `AppLog.menu.info("Menu action selected action=removeLayer id=...")` (via MenuModel.removeLayer)
- `AppLog.scene.info("Layer removed id=... reason=menu")` (via SceneStore.removeLayer)

Assumptions/decisions:
- Using `NSMenuDelegate`'s `menuNeedsUpdate(_:)` is the most reliable way to dynamically synchronise native menu state whenever it is opened.
- Keeps tests free of AppKit class instantiations by structuring MenuModel to expose layer properties directly.

Remaining risks:
- Menu click event latency: Rebuilding a small menu on delegate call takes <0.1ms, so no user-perceivable lag will occur even with 6 layers.

### Slice 14

Status: Complete — 2026-07-04

Files changed:
- `AirStage/Sources/AirStage/Preview/PreviewViewModel.swift` — made class an `ObservableObject`; added `isToolbarVisible` and `toolbarErrorMessage` `@Published` properties; added methods for quick-add actions (`quickAddNote()`, `quickAddClear()`, `quickAddImage()`, `quickAddWindow()`, `quickAddPaste()`) and picker delegate closures.
- `AirStage/Sources/AirStage/Scene/SceneStore.swift` — added `clearAllLayers()` method to remove all active scene items.
- `AirStage/Sources/AirStageApp/PreviewWindowController.swift` — passed `sceneStore` reference to `PreviewViewModel` initialization; set up action delegation closures for image picker, paste operations, and a window capture placeholder alert; passed `viewModel` to `PreviewView` instantiation.
- `AirStage/Sources/AirStageApp/PreviewView.swift` — injected `viewModel` as `@ObservedObject`; added `.onHover` to track hover state; rendered overlay container with bottom-centered pill toolbar (`.background(.ultraThinMaterial)`); added top-aligned sliding toast alert for error warnings with auto-dismissal.
- `AirStage/Tests/AirStageTests/PreviewViewModelTests.swift` — added tests for hover tracking, note adding, canvas clearing, and limit warnings.

Tests added/updated:
- `testQuickAddToolbarVisibleWhenPreviewHovered` ✓
- `testQuickAddNoteAddsNoteLayer` ✓
- `testQuickAddClearRemovesAllLayersAfterConfirmationOrSimpleAction` ✓
- `testQuickAddShowsSceneFullMessageWhenLimitReached` ✓

Commands run:
- `swift test` → Build complete, 62 tests passed, 0 failures

Debug logs added:
- `AppLog.menu.info("Toolbar action selected action=...")`
- `AppLog.scene.info("All layers cleared reason=quickAddClear")`
- `AppLog.scene.warning("Toolbar action failed action=... reason=...")`

Assumptions/decisions:
- The SwiftUI view delegates asynchronous/picker operations back to `PreviewWindowController` via closures to avoid AppKit coupling in views.
- User feedback toasts are styled elegantly using a black translucent box and auto-dismiss after 3 seconds.

Remaining risks:
- SwiftUI `.onHover` mouse tracking can occasionally be lost during rapid movements near window borders, but standard AppKit hover events are sufficiently responsive.

### Slice 15

Status: Complete — 2026-07-04

Files changed:
- `AirStage/Sources/AirStage/Onboarding/OnboardingStateMachine.swift` — new; onboarding steps, event handlers, thresholds
- `AirStage/Tests/AirStageTests/OnboardingStateMachineTests.swift` — new; tests state machine transitions and triggers
- `AirStage/Sources/AirStage/Preview/PreviewViewModel.swift` — updated; tracks onboarding state, integrates UserDefaults persistence, manages vanish hold timer, listens to store layer removals
- `AirStage/Sources/AirStageApp/PreviewView.swift` — updated; renders welcome/camera prompt modals, instruction pills, success toasts, and pink tutorial cards

Tests added/updated:
- `testFirstRunStartsAtWelcome` ✓
- `testReturningUserStartsCompleted` ✓
- `testShowMeSpawnsTutorialItemAndAdvancesToGrab` ✓
- `testMoveBeyondThresholdCompletesGrabStep` ✓
- `testScaleAboveThresholdCompletesZoomStep` ✓
- `testShrinkBelowThresholdStartsVanishHold` ✓
- `testVanishHoldRemovesTutorialItemAndShowsVirtualCameraPrompt` ✓
- `testVirtualCameraTurnOnTappedTransitionsToCompleted` ✓
- `testVirtualCameraPromptDismissedTransitionsToCompleted` ✓
- `testResetOnboardingStartsAgain` ✓
- `testViewModelOnboardingSpawnsAndRemovesTutorialCard` ✓
- `testViewModelOnboardingReset` ✓
- `testViewModelOnboardingAutoVanishAfterHold` ✓
- `testViewModelOnboardingVanishViaDeleteKeyOrOutsideDrag` ✓

Commands run:
- `swift test` → Build complete, 76 tests passed, 0 failures

Debug logs added:
- `AppLog.onboarding.info("Onboarding step changed step=…")`
- `AppLog.onboarding.info("Onboarding completed")`
- `AppLog.onboarding.info("Onboarding reset")`

Assumptions/decisions:
- Tutorial card is added dynamically to the store and selected immediately to display outlines and handles.
- Removal observation is done via a sink on the layers array, ensuring that any manual removal of the tutorial card (Delete/backspace key, or dragging it outside) transitions the state machine forward to the prompt immediately.
- Automatic vanish hold is managed in the view model via a main thread async deadline dispatch that triggers after 0.6 seconds if the state remains `.shrinkHold`.

Remaining risks:
- In the future, once hand pose gestural tracking is enabled in Slice 19, the same state machine will be driven by gestural pinch scale/distance events instead of mouse fallback drag/resize handles.

### Slice 16

Status: Complete — 2026-07-04

Files changed:
- `AirStage/Sources/AirStage/Settings/SettingsStore.swift` — new; handles UserDefaults settings persistence, reset onboarding triggers
- `AirStage/Sources/AirStage/Settings/SettingsView.swift` — new; SwiftUI grouped native sections settings form
- `AirStage/Sources/AirStageApp/SettingsWindowController.swift` — new; AppKit window controller hosting settings view
- `AirStage/Sources/AirStageApp/AppDelegate.swift` — updated; handles settings intent, opens settings window lazily
- `AirStage/Sources/AirStage/Preview/PreviewViewModel.swift` — updated; listens to reset onboarding requests from settings notification
- `AirStage/Tests/AirStageTests/SettingsStoreTests.swift` — new; tests settings persistence and reset notification firing

Tests added/updated:
- `testDebugOverlaySettingPersists` ✓
- `testHandControlSettingPersists` ✓
- `testSnapToGridSettingPersists` ✓
- `testResetOnboardingClearsCompletedState` ✓

Commands run:
- `swift test` → Build complete, 80 tests passed, 0 failures

Debug logs added:
- `AppLog.settings.info("Setting changed launchAtLogin=…")`
- `AppLog.settings.info("Setting changed debugOverlay=…")`
- `AppLog.settings.info("Setting changed handControl=…")`
- `AppLog.settings.info("Setting changed snapToGrid=…")`
- `AppLog.settings.info("Onboarding reset requested from settings")`

Assumptions/decisions:
- Launch at login is structured as a standard toggle, logging state changes, but operates as a safe stub since ServiceManagement launch agent setup will be added in a later slice.
- Reset onboarding uses a global `NotificationCenter` publisher decoupled broadcast, allowing `PreviewViewModel` to dynamically reset its onboarding state machine state back to welcome without setting up tight controller references.

Remaining risks:
- Real sandboxed UserDefaults access could be restricted depending on macOS system sandbox profiles, which may require app group identifiers for camvas extensions.

### Slice 17

Status: Complete — 2026-07-04

Files changed:
- `AirStage/Sources/AirStage/Debug/DebugOverlayState.swift` — new; read-only value type capturing camera status, layer count, selected layer title, hand control status, and gesture state placeholder
- `AirStage/Sources/AirStage/Preview/PreviewViewModel.swift` — updated; added optional `settingsStore` dependency, `isDebugOverlayVisible` computed property, and `debugOverlaySnapshot()` method
- `AirStage/Sources/AirStageApp/PreviewView.swift` — updated; added `DebugOverlayView` SwiftUI component with monospaced developer-friendly layout using `.ultraThinMaterial`; wired into `PreviewView` ZStack at top-left corner, rendered only when debug overlay setting is enabled
- `AirStage/Tests/AirStageTests/DebugOverlayTests.swift` — new; tests for overlay visibility and displayed state

Tests added:
- `testDebugOverlayHiddenByDefault` ✓
- `testDebugOverlayVisibleWhenSettingEnabled` ✓
- `testDebugOverlayShowsLayerCountAndSelectedLayer` ✓
- `testDebugOverlayShowsCameraStatus` ✓
- `testDebugOverlayShowsHandControlAndGesturePlaceholder` ✓

Commands run:
- `swift test` → Build complete, 85 tests passed, 0 failures
- `swift build` → Build complete

Debug logs added:
- `AppLog.app.debug("Debug overlay snapshot layers=... selected=... camera=... hand=...")` — emitted each time the overlay snapshot is computed

Assumptions/decisions:
- `DebugOverlayState` is a pure value type in the library target so tests verify data without SwiftUI
- `settingsStore` is an optional parameter with nil default on `PreviewViewModel.init` to avoid breaking all existing call sites
- Gesture state is a placeholder string `"idle"` until the gesture engine is implemented in Slice 19–21
- The overlay uses `.allowsHitTesting(false)` so it never intercepts mouse/gesture events on scene layers
- The overlay is positioned top-left to avoid colliding with the bottom-center toolbar and onboarding toasts

Remaining risks:
- Overlay re-renders on every SwiftUI update cycle since it reads from `@Published` layers; acceptable for a debug panel
- Gesture state will remain `"idle"` until Slice 19+ implements the hand pose adapter

### Slice 18

Status: Complete — 2026-07-04

Files changed:
- `AirStage/Sources/AirStage/Scene/SceneLimits.swift` — added `gridSize: CGFloat = 20` constant
- `AirStage/Sources/AirStage/Scene/SceneGeometry.swift` — added `snapToGrid(_:gridSize:)` pure function that rounds position to nearest grid point
- `AirStage/Sources/AirStage/Scene/SceneStore.swift` — updated `endDrag` to accept optional `snapToGrid: Bool` parameter; when true, applies grid snapping after clamping
- `AirStage/Sources/AirStageApp/PreviewView.swift` — wired all 4 drag gesture `onEnded` handlers to pass `viewModel.settingsStore?.snapToGrid` to `endDrag`
- `AirStage/Tests/AirStageTests/SnapToGridTests.swift` — new; 3 tests for snap behaviour

Tests added:
- `testSnapToGridRoundsLayerPositionWhenEnabled` ✓
- `testSnapToGridDoesNotChangePositionWhenDisabled` ✓
- `testSnapToGridAppliesOnlyAfterDragEnd` ✓

Commands run:
- `swift test` → Build complete, 88 tests passed, 0 failures
- `swift build` → Build complete

Debug logs added:
- `AppLog.scene.debug("Layer snapped id=... x=... y=...")` — emitted when snap-to-grid applied on drag end

Assumptions/decisions:
- Grid size is 20pt, centralized in `SceneLimits.gridSize`
- Snap applies only at drag end, not during drag, so movement stays smooth
- Snap happens after clamp so layers never snap to an out-of-bounds position
- `endDrag` uses `snapToGrid: Bool = false` default to avoid breaking all existing call sites and tests
- Tutorial card drag also respects snap when enabled

Remaining risks:
- Grid size is fixed at 20pt; a user-configurable grid size could be added later if needed
- Snap visual feedback (grid lines overlay) not implemented; could be added as a debug overlay extension

### Slice 19

Status: Complete — 2026-07-04

Files changed:
- `AirStage/Sources/AirStage/Gestures/HandPoseFrame.swift` — new; fake-testable hand landmark frame with confidence gate and stateless pinch candidate center helper
- `AirStage/Sources/AirStage/Gestures/HandPoseTracking.swift` — new; async `CVPixelBuffer` processing protocol
- `AirStage/Sources/AirStage/Gestures/FakeHandPoseTracker.swift` — new; queued fake tracker for deterministic tests
- `AirStage/Sources/AirStage/Gestures/VisionHandPoseTracker.swift` — new; minimal Vision-backed adapter wrapper using `VNDetectHumanHandPoseRequest`
- `AirStage/Tests/AirStageTests/HandPoseTrackingTests.swift` — new; fake-frame and fake-tracker tests

Tests added:
- `testFakeHandPoseFrameCanRepresentPinchCandidate` ✓
- `testNoLandmarksProducesNoGestureCandidate` ✓
- `testLowConfidenceFrameIgnored` ✓
- `testFakeHandPoseTrackerReturnsQueuedFrames` ✓

Commands run:
- `swift test --filter HandPoseTrackingTests` → red first: compile failed because `HandPoseFrame` and `FakeHandPoseTracker` did not exist
- `swift test --filter HandPoseTrackingTests` → Build complete, 4 tests passed, 0 failures
- `swift test` → Build complete, 92 tests passed, 0 failures
- `swift build` → Build complete

Debug logs added:
- `AppLog.gestures.debug("Fake hand pose frame confidence=...")`
- `AppLog.gestures.debug("Fake hand pose tracker empty")`
- `AppLog.gestures.debug("Hand landmarks updated count=...")`
- `AppLog.gestures.error("Hand pose tracking failed error=...")`

Assumptions/decisions:
- Kept the Vision adapter isolated behind `HandPoseTracking`; UI and preview still do not depend directly on Vision.
- Added only stateless landmark/confidence helpers in this slice; stateful pinch began/moved/ended stays for Slice 20.
- `FakeHandPoseTracker` lives in the library target so future gesture tests can reuse it without camera/Vision.

Remaining risks:
- Real Vision tracking needs manual QA with live camera frames.
- Coordinate mapping from normalized Vision points into preview coordinates is intentionally deferred to pinch/grab slices.

### Slice 20

Status: Complete — 2026-07-04

Files changed:
- `AirStage/Sources/AirStage/Gestures/GestureEngine.swift` — new; stateful pinch engine emits began/moved/ended/none from `HandPoseFrame`
- `AirStage/Tests/AirStageTests/GestureEngineTests.swift` — new; fake frame tests for pinch start, move, end, and low-confidence ignore

Tests added:
- `testCloseThumbAndIndexStartsPinch` ✓
- `testPinchMovementProducesMovedEvent` ✓
- `testSeparatedFingersEndPinch` ✓
- `testLowConfidenceDoesNotStartPinch` ✓

Commands run:
- `swift test --filter GestureEngineTests` → red first: compile failed because `GestureEngine` and gesture event cases did not exist
- `swift test --filter GestureEngineTests` → Build complete, 4 tests passed, 0 failures
- `swift test` → Build complete, 96 tests passed, 0 failures
- `swift build` → Build complete

Debug logs added:
- `AppLog.gestures.info("Pinch began hand=primary")`
- `AppLog.gestures.debug("Pinch moved x=... y=...")`
- `AppLog.gestures.info("Pinch ended hand=primary")`

Assumptions/decisions:
- Reused `HandPoseFrame.pinchCandidateCenter` from Slice 19 instead of adding a second threshold path.
- Kept the engine as a tiny value type with one `isPinching` flag; no UI movement or layer selection added in this slice.
- Low-confidence and separated-finger frames both produce `.none` when idle, and `.pinchEnded` only when a pinch was already active.

Remaining risks:
- Pinch distance threshold is still inherited from `HandPoseFrame.maximumPinchCandidateDistance`; real-camera tuning may need calibration later.
- Preview coordinate mapping and selected-layer movement are intentionally deferred to Slice 21.

### Slice 21

Status: Complete — 2026-07-05

Files changed:
- `AirStage/Sources/AirStage/Gestures/GestureLayerController.swift` — new; bridges GestureEngine pinch events to SceneStore layer selection and movement with hit-testing and hand-control guard
- `AirStage/Sources/AirStage/Preview/PreviewViewModel.swift` — updated; added `gestureLayerController` property; debug overlay now shows real gesture state ("idle"/"grabbing <id>") instead of hardcoded placeholder
- `AirStage/Tests/AirStageTests/GestureLayerControllerTests.swift` — new (by Codex); 4 tests for pinch grab, move, release, and disabled ignore

Tests added:
- `testPinchBeginSelectsTopLayerAtGesturePoint` ✓
- `testPinchMoveUpdatesGrabbedLayerPosition` ✓
- `testPinchEndReleasesLayer` ✓
- `testHandControlDisabledIgnoresPinchEvents` ✓

Commands run:
- `swift test --filter GestureLayerControllerTests` → red first: compile failed because `GestureLayerController` did not exist
- `swift test --filter GestureLayerControllerTests` → Build complete, 4 tests passed, 0 failures
- `swift test` → Build complete, 100 tests passed, 0 failures
- `swift build` → Build complete

Debug logs added:
- `AppLog.gestures.info("Pinch grab began layer=... x=... y=...")` — emitted on pinch begin with layer hit
- `AppLog.gestures.debug("Pinch grab moved layer=... x=... y=...")` — emitted on each pinch move
- `AppLog.gestures.info("Pinch grab released layer=...")` — emitted on pinch end
- Debug overlay `gestureState` now shows `"grabbing <uuid-prefix>"` when actively grabbing, `"idle"` otherwise

Assumptions/decisions:
- `GestureLayerController` is a value type (struct) that holds a reference to SceneStore and scene bounds
- Hit-testing uses center-based bounding rect (position ± half size) and selects topmost layer by zIndex
- On pinch end, `endDrag` is called to clamp the layer position back inside scene bounds
- Hand coordinate mapping assumed to be preview-coordinate-space; real Vision coordinate normalisation may need tuning in manual QA
- Tests were written by Codex prior to implementation; implementation satisfies all 4 test contracts

Remaining risks:
- Real Vision hand coordinates are normalised 0..1; preview coordinate mapping needs calibration with live camera frames
- Gesture controller is not yet wired into the actual PreviewWindowController/PreviewView rendering pipeline; that integration is deferred to when the full hand tracking pipeline runs end-to-end

### Slice 22

Status: Complete — 2026-07-05

Files changed:
- `AirStage/Sources/AirStage/Sources/CaptureTarget.swift` — new; value type representing a capturable window or screen target
- `AirStage/Sources/AirStage/Sources/WindowCaptureSource.swift` — new; protocol abstracting ScreenCaptureKit behind a testable interface
- `AirStage/Sources/AirStage/Sources/FakeWindowCaptureSource.swift` — new; test double with configurable windows and error simulation
- `AirStage/Sources/AirStage/Sources/WindowCaptureImporter.swift` — new; validates and adds window capture layers to the SceneStore, enforcing the 1-window limit
- `AirStage/Sources/AirStage/Menu/MenuModel.swift` — updated; enabled `.shareWindowOrScreen` menu action
- `AirStage/Sources/AirStageApp/AppDelegate.swift` — updated; wired `.shareWindowOrScreen` intent to `presentWindowCapturePicker()` with error alerts
- `AirStage/Tests/AirStageTests/WindowCaptureTests.swift` — new; 6 tests for capture import, limits, fake source, and menu enablement
- `AirStage/Tests/AirStageTests/MenuModelTests.swift` — updated; removed `.shareWindowOrScreen` from disabled actions list

Tests added:
- `testShareWindowAddsWindowCaptureLayer` ✓
- `testCannotAddSecondWindowCaptureLayer` ✓
- `testWindowCaptureFailureShowsFriendlyError` ✓
- `testFakeWindowCaptureSourceReturnsConfiguredWindows` ✓
- `testFakeWindowCaptureSourceCanSimulateFailure` ✓
- `testShareWindowMenuIsEnabled` ✓

Commands run:
- `swift test --filter WindowCaptureTests` → red first: compile failed because `WindowCaptureImporter`, `CaptureTarget`, `FakeWindowCaptureSource` did not exist
- `swift test --filter WindowCaptureTests` → Build complete, 6 tests passed, 0 failures
- `swift test` → 106 tests passed, 1 failure (menu regression in `testDisabledActionsDoNotEmitIntents`)
- Fixed menu test, `swift test` → 106 tests passed, 0 failures
- `swift build` → Build complete

Debug logs added:
- `AppLog.sources.info("Importing window capture title=... captureID=...")` — emitted when import is attempted
- `AppLog.sources.info("Window capture layer added id=...")` — emitted on success
- `AppLog.sources.error("Window capture limit exceeded")` — emitted when 1-window limit hit
- `AppLog.sources.error("Scene full, cannot add window capture")` — emitted when scene is full
- `AppLog.sources.info("Window capture picker requested")` — emitted from AppDelegate

Assumptions/decisions:
- ScreenCaptureKit is abstracted behind `WindowCaptureSource` protocol; real implementation will live in the App target
- `FakeWindowCaptureSource` lives in the library target so tests can use it directly
- `WindowCaptureImporter` mirrors `ImageImporter` pattern — validates, delegates to SceneStore, maps errors
- AppDelegate currently adds a placeholder "Screen Capture" layer; full `SCShareableContentPicker` integration deferred to when ScreenCaptureKit permission flow is stable
- Window capture layer spawns at center with 240×180 default size

Remaining risks:
- Real ScreenCaptureKit integration needs screen recording permission; manual QA required
- Placeholder picker does not show actual window list; real picker implementation deferred
- Live frame rendering of captured window content is not implemented in this slice

### Slice 23

Status: Complete — 2026-07-05

Files changed:
- `AirStage/Sources/AirStage/Compositor/Compositor.swift` — new; `Compositor` class produces `CompositorFrame` metadata snapshots from `SceneStore`; `CompositorFrame` and `CompositorLayerEntry` value types describe camera background + overlay layers sorted by zIndex
- `AirStage/Tests/AirStageTests/CompositorTests.swift` — new; 5 tests for frame snapshot, layer ordering, output metadata, removal exclusion, and empty scene

Tests added:
- `testCompositorReceivesCameraFrameAndLayerSnapshot` ✓
- `testCompositorOrdersLayersByZIndex` ✓
- `testCompositorProducesOutputFrameMetadata` ✓
- `testCompositorExcludesRemovedLayers` ✓
- `testCompositorSnapshotWithEmptyScene` ✓

Commands run:
- `swift test --filter CompositorTests` → red first: compile failed because `Compositor` did not exist
- `swift test --filter CompositorTests` → Build complete, 5 tests passed, 0 failures
- `swift test` → Build complete, 111 tests passed, 0 failures
- `swift build` → Build complete

Debug logs added:
- `AppLog.app.debug("Compositor snapshot camera=... layers=... output=...")` — emitted on each snapshot, uses debug level to avoid spamming info logs during real-time compositing

Assumptions/decisions:
- Compositor is a metadata/test abstraction — produces `CompositorFrame` structs describing what to render, not actual pixel output
- Real CoreImage/Metal rendering will be added when virtual camera extension needs pixel output (Slice 24+)
- Layers with `isBeingRemoved == true` are excluded from the compositor snapshot since they are visually fading and should not appear in the output
- Layer entries are sorted by zIndex ascending (lowest first = drawn first, highest = drawn on top)
- Timestamp uses ISO-8601 format via `ISO8601DateFormatter`
- `CompositorLayerEntry` captures all rendering-relevant properties (position, size, scale, rotation, kind, imageURL) from `SceneLayer`

Remaining risks:
- Real pixel compositing will need CoreImage or Metal; this metadata abstraction is the seam for that future work
- Frame rate / performance characteristics unknown until real rendering is connected

### Slice 24

Status: Complete — 2026-07-05

Files changed:
- `AirStage/Sources/AirStage/VirtualCamera/VirtualCameraManager.swift` — new; `VirtualCameraStatus` model and `VirtualCameraManager` to handle extension status and installation requests.
- `AirStage/Sources/AirStage/Preview/PreviewViewModel.swift` — updated; added `virtualCameraManager` reference, wired onboarding activation request to manager.
- `AirStage/Sources/AirStage/Settings/SettingsView.swift` — updated; added "Virtual Camera" section displaying current status and a prominent "Install" button.
- `AirStage/Sources/AirStageApp/SettingsWindowController.swift` — updated; passed `VirtualCameraManager` to `SettingsView`.
- `AirStage/Sources/AirStageApp/PreviewWindowController.swift` — updated; passed `VirtualCameraManager` to `PreviewViewModel`.
- `AirStage/Sources/AirStageApp/AppDelegate.swift` — updated; instantiates `VirtualCameraManager` and passes it to both preview and settings window controllers.
- `AirStage/Tests/AirStageTests/VirtualCameraTests.swift` — new; tests initial status, install transition, and user-friendly status message representations.
- `AirStage/Tests/AirStageTests/ViewModelVirtualCameraTests.swift` — new; tests connection between onboarding state machine and the virtual camera manager.

Tests added:
- `testVirtualCameraDisabledBeforeSetup` ✓
- `testInstallRequestTransitionsToPendingApproval` ✓
- `testExtensionStatusMessagesAreUserFriendly` ✓
- `testViewModelCallsManagerOnVirtualCameraActivationRequest` ✓

Commands run:
- `swift test --filter VirtualCameraTests` → red first: compiler failed because `VirtualCameraManager` / `VirtualCameraStatus` did not exist
- `swift test` → 115 tests passed, 0 failures
- `swift build` → Build complete

Debug logs added:
- `AppLog.virtualCamera.info("Virtual camera install requested")` — logged when installation request is initiated
- `AppLog.virtualCamera.info("Virtual camera status updated to pendingApproval")` — logged on state transition
- `AppLog.virtualCamera.info("Virtual camera status manually updated to ...")` — logged on manual updates

Assumptions/decisions:
- Real system extension installation requires specific developer identities/signing certificates. To avoid failure in dev mode, we model this as a clean status machine (`VirtualCameraStatus`) transitioning to `.pendingApproval` with stubs/logs.
- The UI under settings explains the virtual camera status. An installer request will transition the UI state and log the event.
- Cleans up `UserDefaults.standard` in test setUp/tearDown to avoid polluting other onboarding test flows.

Manual QA Checklist (Virtual Camera extension registration):
1. AirStage must be moved to `/Applications` directory for SystemExtensions to load successfully.
2. When install is triggered, the user must approve the extension in macOS System Settings -> Privacy & Security -> Extensions (or a system authorization dialog).
3. Once approved by the system, status transitions to `.installed`.

### Slice 25

Status: Complete — 2026-07-05

Files changed:
- `AirStage/Tests/AirStageTests/IntegrationRegressionTests.swift` — new; integration tests verifying core product scenarios (add-edit-drag-remove, add-resize-delete, window limit block, settings onboarding reset, debug overlay toggle).

Tests added:
- `testIntegrationAddNoteEditDragRemoveOutside` ✓
- `testIntegrationAddImageResizeDelete` ✓
- `testIntegrationWindowLimitBlocked` ✓
- `testIntegrationSettingsResetOnboarding` ✓
- `testIntegrationDebugOverlayToggle` ✓

Commands run:
- `swift test --filter IntegrationRegressionTests` → Build complete, 5 tests passed, 0 failures
- `swift test` → Build complete, 120 tests passed, 0 failures
- `swift build` → Build complete

Debug logs added:
- None (this slice focuses strictly on validation tests and regression control).

Assumptions/decisions:
- Created clean integration test cases representing end-to-end presenter workflows.
- Re-verified all previous slices through the full package test run. 
- `AirStage/Sources/AirStageApp/AVCameraSession.swift` — updated; inherited from NSObject, conformed to AVCaptureVideoDataOutputSampleBufferDelegate, added videoDataOutput, set delegate queue, and configured video mirroring on connection
- `AirStage/Sources/AirStageApp/PreviewWindowController.swift` — updated; configured window to be borderless with rounded corners, transparency, and background movability, mirrored the preview layer, and passed settingsStore
- `AirStage/Sources/AirStageApp/AppDelegate.swift` — updated; passed settingsStore to PreviewWindowController
- `AirStage/Sources/AirStageApp/PreviewView.swift` — updated; blocked mouse drag and resize gestures on layers when handControl is enabled, and customized instruction texts
- `AirStage/Tests/AirStageTests/FakeCameraSession.swift` — updated; conformed to CameraSession protocol update and imported `CoreVideo`
- `AirStage/Tests/AirStageTests/PreviewViewModelTests.swift` — updated; added `testShowMeAutoEnablesHandControl` and `testOnFrameCapturedDrivesGestureEngine`

Tests added:
- `testShowMeAutoEnablesHandControl` ✓
- `testOnFrameCapturedDrivesGestureEngine` ✓

Commands run:
- `swift test` → 122/122 tests passed

Debug logs added:
- Logged when video frame processing fails inside `PreviewViewModel` task

Assumptions/decisions:
- Coordinates from Vision are mapped from normalized space to 640x480 space (inverting Y). The mapping sets mapped coordinates for indexTip and thumbTip to match the mapped center when a pinch is active, so that core distance thresholds inside the gesture engine remain valid.
- Settings store is passed into PreviewWindowController to keep settings reactive and available to the view model in the real application.
- Rounded corners on the borderless window are implemented via the contentView layer to avoid standard macOS window borders.
- Hand control is automatically enabled when the user starts onboarding to allow them to experience hand tracking immediately.

### Onboarding Gesture and Fallback Refinement

Status: Complete — 2026-07-05

Files changed:
- `AirStage/Sources/AirStage/Preview/PreviewViewModel.swift` — updated; added `updateTutorialCardTitle()` to dynamically set tutorial card title depending on current onboarding step.
- `AirStage/Sources/AirStageApp/PreviewView.swift` — updated; removed handControl drag block for corner resize handle to enable mouse resize fallback, added pulsing micro-animation to the blue resize handle, and updated instruction pills texts.
- `AirStage/Tests/AirStageTests/PreviewViewModelTests.swift` — updated; added `testViewModelOnboardingUpdatesTutorialCardTitle`.

Tests added:
- `testViewModelOnboardingUpdatesTutorialCardTitle` ✓

Commands run:
- `swift test` → 123/123 tests passed

Assumptions/decisions:
- The single-hand Vision tracker configures `maximumHandCount = 1`, meaning two-hand pinch gestures are physically unsupported. The onboarding instructions have been refined to guide the user to use the pulsing blue corner resize handle fallback, which is fully interactive.
- Micro-animations (pulsing scale and opacity) are applied specifically to the `.tutorial` card's resize handle during onboarding to draw immediate visual attention to the interaction target.



### Bug Fix: Onboarding Step 3 Polish

Status: Complete — 2026-07-05

Files changed:
- `AirStage/Sources/AirStage/Onboarding/OnboardingStateMachine.swift` — extended vanish duration to 3.0s
- `AirStage/Sources/AirStage/Preview/PreviewViewModel.swift` — delayed removeTutorialSceneItem for 1.5s on vanish
- `AirStage/Sources/AirStageApp/PreviewView.swift` — added top-left handle, added disintegration effect hook
- `AirStage/Sources/AirStageApp/DisintegrationEffect.swift` — new; custom view modifier for shatter/snap effect
- `AirStage/Tests/AirStageTests/PreviewViewModelTests.swift` — updated timeouts for vanish flow

Tests updated:
- `testViewModelOnboardingAutoVanishAfterHold` ✓
- `testViewModelOnboardingSpawnsAndRemovesTutorialCard` ✓

Commands run:
- `swift test` → Build complete, 123 tests passed, 0 failures


### Slice 26

Status: Complete — 2026-07-05

Files changed:
- `AirStage/Sources/AirStage/Scene/SceneGeometry.swift` — added `convertHandPointToCanvas`
- `AirStage/Sources/AirStage/Debug/DebugDataStructures.swift` — new; structured debug data models
- `AirStage/Sources/AirStage/Onboarding/OnboardingStateMachine.swift` — refactored to `observe(grabbing:scale:)` pattern
- `AirStage/Sources/AirStage/Preview/PreviewViewModel.swift` — integrated observation mapping for gestures and generated debug data
- `AirStage/Sources/AirStageApp/PreviewView.swift` — expanded resize handle hit areas to 72x72, added invisible keyboard shortcut `Cmd+Shift+D` to toggle debug layer
- `AirStage/Sources/AirStage/Debug/DebugLayer.swift` — new; renders bounding boxes, resize handles, dots for pinch points, and formatted debug readout

Tests added:
- Updated existing `OnboardingStateMachineTests` to test `observe(grabbing:scale:)` behavior

Commands run:
- `swift test` → Build complete, 124 tests passed, 0 failures

Assumptions/decisions:
- Onboarding now relies on simplified live gesture state mapping over frame-based counters where possible, observing grab presence and scaling factors.
- Expand visual handles' touch target using `.contentShape(Rectangle())` internally in resize components to alleviate precision issues during onboarding with a mouse.
- `Cmd+Shift+D` toggle integrated via invisible `Button` utilizing `@AppStorage` linked `SettingsStore.debugOverlay`.

Remaining risks:
- True test of gestural ease still depends on live human interaction with webcam.

Manual QA notes:
- enable debug overlay
- move finger left/right/up/down
- confirm dot follows fingertip
- confirm no mirror/vertical flip bug
- enter zoom step
- confirm scale, baseline, target, success frames update live
- enter shrink step
- confirm shrink baseline resets from zoomed scale

### Slice 26

Status: Complete — 2026-07-05

Files changed:
- `AirStage/Sources/AirStage/Preview/PreviewViewModel.swift` — Re-ordered operations in `replaceTutorialSceneItemForCurrentStep` to insert the new card *before* removing the old one, preventing the `.hasTutorial == false` check from prematurely completing the flow. Removed auto-continue on pinch-end. Added strict `shouldShowQuickAddToolbar` logic.
- `AirStage/Sources/AirStage/Gestures/GestureLayerController.swift` — Added `cancelActiveGesture()` to clear state between steps, and implemented constraints in `resizeLayer` to force tutorial layers to remain square.
- `AirStage/Tests/AirStageTests/PreviewViewModelTests.swift` — Added `setUp()` and `tearDown()` to clear `UserDefaults.standard` between test runs, preventing leakage of `hasCompletedOnboarding` flag. Updated logic inside `testQuickAddToolbarVisibleWhenPreviewHovered` to match new conditions.

Tests added/updated:
- Fixed `testQuickAddToolbarVisibleWhenPreviewHovered`
- Fixed `testViewModelOnboardingAutoVanishAfterHold`
- Fixed `testShowMeAutoEnablesHandControl`

Commands run:
- `swift test` → 124/124 tests passed

Debug logs added:
- None

Assumptions/decisions:
- Replacing the tutorial card cleanly clears any prior scale/position state left from the user's interaction on the previous step.
- Hiding the quick-add toolbar during onboarding reduces visual noise and aligns with Shacam's focused approach.
- State leak across test runs in `PreviewViewModelTests` was the root cause of seemingly random failures, addressed reliably via `setUp`/`tearDown`.

### Slice 27

Status: Complete — 2026-07-06

Files changed:
- `AirStage/Sources/AirStage/Onboarding/OnboardingStateMachine.swift`
- `AirStage/Sources/AirStage/Preview/PreviewViewModel.swift`
- `AirStage/Sources/AirStage/Menu/MenuModel.swift`
- `AirStage/Sources/AirStage/Debug/DebugLayer.swift`
- `AirStage/Sources/AirStage/Gestures/GestureLayerController.swift`
- `AirStage/Sources/AirStage/Settings/SettingsStore.swift`
- `AirStage/Sources/AirStageApp/PreviewView.swift`
- `AirStage/Sources/AirStageApp/AppDelegate.swift`
- `AirStage/Tests/AirStageTests/OnboardingStateMachineTests.swift`
- `AirStage/Tests/AirStageTests/PreviewViewModelTests.swift`
- `AirStage/Tests/AirStageTests/MenuModelTests.swift`
- `AirStage/Tests/AirStageTests/SceneGeometryTests.swift`
- `AirStage/Tests/AirStageTests/ViewModelVirtualCameraTests.swift`
- `AirStage/Tests/AirStageTests/IntegrationRegressionTests.swift`

Tests added/updated:
- `testVanishHoldRemovesTutorialItemAndShowsVanishSuccess` ✓
- `testCompletionDelayElapsedShowsFinalPrompt` ✓
- `testMenuOnlyShowsQuitBeforeOnboardingCompletes` ✓
- `testMenuShowsNormalActionsAfterOnboardingCompletes` ✓
- `testQuitIsAlwaysEnabled` ✓
- Updated test assertions to handle delayed state transitions.

Commands run:
- `swift test` → 138/138 tests passed

Debug logs added:
- `AppLog.onboarding.info("Onboarding completed")`
- `AppLog.gestures.debug("Pinch moved...")`

Assumptions/decisions:
- The 3-second transition to virtual camera prompt card utilizes .vanishSuccess transition state inside the state machine.
- GeometryReader on PreviewView dynamically updates the canvas size, enabling correct coordinate mapping under resizing.
- Status menu options are gated dynamically behind onboarding status, and Cmd+Q shortcut is set as keyEquivalent.

### Slice 28: Drag-to-Edge Delete Interaction

Status: Complete — 2026-07-06

Files changed:
- `AirStage/Sources/AirStage/Preview/EdgeDeleteState.swift` [NEW] — Defines the side, state enum, and properties for the edge delete zone.
- `AirStage/Sources/AirStage/Preview/EdgeDeleteController.swift` [NEW] — Implements state transitions (idle, hovering, armed, disintegrating), hysteresis offsets, and async timers.
- `AirStage/Sources/AirStage/Preview/PreviewViewModel.swift` — Wired controller to the view model, exposing state, adding mouse/hand gesture updates, and handling disintegration & scene deletion.
- `AirStage/Sources/AirStage/Debug/DebugOverlayState.swift` — Added diagnostic structures for edge delete tracking.
- `AirStage/Sources/AirStage/Debug/DebugLayer.swift` — Displayed live edge delete parameters on the debug overlay.
- `AirStage/Sources/AirStageApp/PreviewView.swift` — Connected SwiftUI card drag gestures (StickyNote, ImageCard, DefaultCard) to edge delete actions, added EdgeDeleteZoneView and EmitterView overlays.
- `AirStage/Sources/AirStageApp/EdgeDeleteZoneView.swift` [NEW] — SwiftUI implementation of the translucent liquid glass wave capsule overlay and trash bin icon.
- `AirStage/Sources/AirStageApp/EmitterView.swift` [NEW] — AppKit CAEmitterLayer wrap for particle disintegration effect.
- `AirStage/Tests/AirStageTests/EdgeDeleteTests.swift` [NEW] — Added unit/integration tests covering edge boundaries, onboarding constraints, cancellation offset, timing delays, and view model integration.

Tests added/updated:
- `testEdgeDeleteBeginsHoveringWhenLayerEntersLeftZone` ✓
- `testEdgeDeleteBeginsHoveringWhenLayerEntersRightZone` ✓
- `testEdgeDeleteCancelsWhenLayerLeavesZone` ✓
- `testEdgeDeleteDoesNotStartDuringOnboarding` ✓
- `testEdgeDeleteDoesNotStartForTutorialLayer` ✓
- `testEdgeDeleteUsesCurrentSceneBoundsAfterResize` ✓
- `testEdgeDeleteTransitionsToArmedAndDeletesAsync` ✓
- `testEdgeDeleteForceArmAndForceDeleteHelpers` ✓
- `testVMIntegratesWithEdgeDeleteController` ✓
- `testVMOnboardingGatingForEdgeDelete` ✓
- `testVMTutorialCardGatingForEdgeDelete` ✓

Commands run:
- `swift test` → 149/149 tests passed

Debug logs added:
- `AppLog.scene.info("Layer deletion armed on side ... id=...")`
- `AppLog.scene.info("Layer deletion complete id=...")`
- `AppLog.scene.info("Layer deletion cancelled id=...")`

Assumptions/decisions:
- Hysteresis boundary allows cancellation when the card is pulled back 32pt inside the trigger boundary (trigger at 96pt, cancel at 128pt).
- Liquid glass wave utilizes `.ultraThinMaterial` and soft drop-shadow animations.
- Particle effect uses native `CAEmitterLayer` for optimized high-fidelity rendering.
- Gated edge-deletion gesture during onboarding to avoid interference with the tutorial cards/flow.

### Patch — Auto-Open Preview Window on Launch

Status: Complete — 2026-07-06

Files changed:
- `Sources/AirStageApp/AppDelegate.swift` — added `showPreview()` call at the end of `applicationDidFinishLaunching(_:)`, after observers are registered; also added `AppLog.app.info("Preview window opened automatically at launch")`.

Tests added: none (AppDelegate is in the app target, not importable by the test target; behaviour is verified manually. All 149 existing tests continue to pass.)

Commands run:
- `swift test --package-path AirStage` → 149/149 passed, 0 failures

Reason for change:
- The dropdown menu is locked to [Quit only] during onboarding. Requiring the user to navigate the menu to show the preview was impossible during first-run onboarding and confusing on subsequent launches. The preview now opens immediately at launch, independently of the menu model, matching the product intent ("app opens to the live camera preview").

Remaining risks:
- None; change is a single call to the existing `showPreview()` path which was already exercised by all other launch paths (Add Note, Share Image, etc.).

### Patch — Hit Region Policy Bug Fix

Status: Complete — 2026-07-06

Files changed:
- `AirStage/Sources/AirStage/Gestures/InteractionHitPolicy.swift` [NEW] — Implements dynamic resize radius bounded by minimum card dimension, and central drag-safe bounds.
- `AirStage/Sources/AirStage/Gestures/LayerInteractionResolver.swift` [NEW] — Evaluates a point against a rect using `InteractionHitPolicy` to return `.drag`, `.resize(handle)`, or `.none`.
- `AirStage/Sources/AirStage/Gestures/GestureLayerController.swift` — Replaced scale-based hit calculation with `LayerInteractionResolver`.
- `AirStage/Sources/AirStage/Preview/PreviewViewModel.swift` — Replaced scale-based hit calculation for debug overlay with `InteractionHitPolicy` and `LayerInteractionResolver`. Updated `CardDebugInfo` creation.
- `AirStage/Sources/AirStage/Debug/DebugDataStructures.swift` — Removed redundant global `nearestHandle` and updated `CardDebugInfo` to hold `dragSafeRect` and `interactionModeDescription`. Added `CaseIterable` to `ResizeHandle`.
- `AirStage/Sources/AirStage/Debug/DebugLayer.swift` — Switched debug handle zones from solid fill to rings and added `dragSafeRect` visual indicator along with text labels.
- `AirStage/Tests/AirStageTests/InteractionHitPolicyTests.swift` [NEW] — Tests to ensure correct interaction resolution and bounded handle radii.

Tests added:
- `testResizeRadiusDoesNotExplodeForVeryWideCard` ✓
- `testResizeRadiusIsCappedForLargeCard` ✓
- `testResizeRadiusForStandardCard` ✓
- `testInteriorPointPrefersDragOverResize` ✓
- `testCornerPointPrefersResize` ✓
- `testWideCardCenterStillDrags` ✓
- `testWideCardInteriorNearSideDoesNotTriggerResizeUnlessNearCorner` ✓
- `testPointOutsideExpandedHitAreaDoesNothing` ✓
- `testDebugRadiusUsesSharedInteractionHitPolicy` ✓

Commands run:
- `swift test` → 158 tests passed, 0 failures

Manual Notes:
- Standard card: confirmed corner hit zones are small rings, pinch center drags, pinch corner resizes.
- Wide card: confirmed resize hit circles do not become massive, center drags, far-right center drags, bottom-right corner resizes.
- Small card: center still drags, only near corners trigger resize.
- Debug UI shows descriptive label.

Assumptions/decisions:
- The `InteractionHitPolicy` limits handle zones based on `min(rect.width, rect.height)` ensuring large/wide cards do not monopolize gesture hits.
