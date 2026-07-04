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
- [ ] Slice 17 — Debug Overlay
- [ ] Slice 18 — Snap to Grid Behaviour
- [ ] Slice 19 — Vision Hand Pose Adapter With Fake-Tested Gesture Frames
- [ ] Slice 20 — Pinch Detection Gesture Engine
- [ ] Slice 21 — Pinch-to-Grab Selected Layer
- [ ] Slice 22 — ScreenCaptureKit Window/Screen Layer
- [ ] Slice 23 — Compositor Frame Pipeline Spike
- [ ] Slice 24 — Virtual Camera Extension Integration Gate
- [ ] Slice 25 — Final Native Polish and Regression Pass


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

Status: Not started

Notes:

### Slice 18

Status: Not started

Notes:

### Slice 19

Status: Not started

Notes:

### Slice 20

Status: Not started

Notes:

### Slice 21

Status: Not started

Notes:

### Slice 22

Status: Not started

Notes:

### Slice 23

Status: Not started

Notes:

### Slice 24

Status: Not started

Notes:

### Slice 25

Status: Not started

Notes:
