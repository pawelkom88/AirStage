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
- [ ] Slice 5 — Scene Layer Model and Limits
- [ ] Slice 6 — Add Note Layer From Menu
- [ ] Slice 7 — Edit Note Text
- [ ] Slice 8 — Add Image Layer From Picker and Drop/Paste Handler
- [ ] Slice 9 — Select, Bring to Front, and Delete Layer
- [ ] Slice 10 — Mouse Drag Layer
- [ ] Slice 11 — Resize Layer With Handles
- [ ] Slice 12 — Drag Outside Preview to Remove
- [ ] Slice 13 — Remove Layer Menu Reflects Current Layers
- [ ] Slice 14 — Preview Hover Quick-Add Toolbar
- [ ] Slice 15 — First-Run Onboarding State Machine and Real Tutorial Scene Item
- [ ] Slice 16 — Settings Window With Persisted Toggles
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

### Slice 5

Status: Not started

Notes:

### Slice 6

Status: Not started

Notes:

### Slice 7

Status: Not started

Notes:

### Slice 8

Status: Not started

Notes:

### Slice 9

Status: Not started

Notes:

### Slice 10

Status: Not started

Notes:

### Slice 11

Status: Not started

Notes:

### Slice 12

Status: Not started

Notes:

### Slice 13

Status: Not started

Notes:

### Slice 14

Status: Not started

Notes:

### Slice 15

Status: Not started

Notes:

### Slice 16

Status: Not started

Notes:

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
