# AirStage — Master Implementation Prompt

## TASK

Your task: implement **AirStage** end-to-end as a native macOS menu bar app using the specs in this prompt. Build all files, compile, fix errors, write tests first, and iterate until all SUCCESS CRITERIA are met.

Do not ask for clarification unless implementation is impossible. If something is ambiguous, choose the simpler native macOS option, keep scope small, add a debug log, and note the decision in `docs/AirStage_TDD_PROGRESS_TODO.md`.

---

## PRODUCT DIRECTION

Build an original native macOS app inspired by the product pattern observed in Shacam: a camera preview scene where users can place images, live windows, and sticky notes over their webcam feed, then move or remove them naturally during live calls.

Do **not** copy Shacam’s name, icon, assets, artwork, exact onboarding copy, purchase copy, or proprietary implementation. Recreate the interaction quality using original AirStage UI, native macOS components, and the UI reference screenshots.

AirStage should feel native, calm, playful, and useful during real meetings.

---

## WHAT YOU'RE BUILDING

AirStage lets presenters place images, notes, and live windows over their webcam feed and manage them quickly during calls. The first build must focus on the local preview magic moment before virtual camera complexity.

**MVP scope:**

In v1:

1. Native macOS menu bar app with action-first menu.
2. Preview window with live camera permission state and camera feed.
3. Scene/layer model for notes, images, and one live window/screen capture layer.
4. Add layer flows: menu, preview quick-add toolbar, image picker, drag/drop, paste where feasible.
5. Mouse interaction: select, bring to front, drag, resize, Delete-key removal.
6. Drag outside preview to remove.
7. In-preview onboarding tutorial using a real tutorial scene item.
8. Settings window with persisted toggles.
9. Debug logging and debug overlay.
10. Vision hand tracking and pinch-to-grab after mouse behaviour works.
11. ScreenCaptureKit window/screen layer.
12. Compositor/output frame path.
13. Core Media I/O virtual camera extension late in the plan.

NOT in v1:

1. iPhone/iPad sharing.
2. Licensing/paywall/purchase.
3. Sparkle auto-updates.
4. Multi-window capture beyond one live capture layer.
5. Advanced double-pinch gesture.
6. Push-pull depth zoom.
7. Cloud sync/accounts/recording.
8. Exact copying of reference app assets/copy/brand.

---

## SOURCE OF TRUTH

Read these docs from repo root:

```text
docs/00_PROJECT_INDEX.md
docs/AirStage_PRD.md
docs/AirStage_DESIGN_GUIDE.md
docs/AirStage_UI_REFERENCE.md
docs/AirStage_ONBOARDING_UI_REFERENCE.md
docs/AirStage_ASSET_POLICY.md
docs/AirStage_DEBUG_LOGGING_GUIDE.md
docs/AirStage_TDD_BREAKDOWN_PLAN.md
docs/AirStage_TDD_PROGRESS_TODO.md
```

The reference screenshots live in:

```text
ui-reference/01-settings-window-reference.png
ui-reference/02-menu-bar-menu-reference.png
ui-reference/03-preview-onboarding-reference.png
ui-reference/onboarding/01_onboarding_welcome_live_preview.png
ui-reference/onboarding/02_onboarding_grab_start.png
ui-reference/onboarding/03_onboarding_grab_success.png
ui-reference/onboarding/04_onboarding_zoom_instruction.png
ui-reference/onboarding/05_onboarding_zoom_success.png
ui-reference/onboarding/06_onboarding_shrink_instruction.png
ui-reference/onboarding/07_onboarding_shrink_hold.png
ui-reference/onboarding/08_onboarding_vanish_success.png
ui-reference/onboarding/09_onboarding_virtual_camera_prompt.png
```

Use them as reference only. Do not ship them as product assets.

---

## HARD CONSTRAINTS

- Use SwiftUI + AppKit.
- Use native macOS components wherever possible.
- Use `AVFoundation` for camera input/preview.
- Use `ScreenCaptureKit` for window/screen capture.
- Use `Vision` for hand pose tracking behind a testable adapter.
- Use `OSLog.Logger` for debug logs in every slice.
- Do not use `print` as the main logging system.
- Do not implement the virtual camera extension until preview, layers, onboarding, and gesture interactions are stable.
- Do not implement iPhone/iPad sharing in v1.
- Do not implement licensing in v1.
- Do not build a custom web-style dashboard UI.
- Do not create brittle snapshot tests as the main verification method.
- Do not test private methods or internal SwiftUI hierarchy.
- Do not hardcode absolute local paths.
- Do not create bitmap/image assets for onboarding tutorial cards, pink rectangles, selection bounds, gesture dots, instruction pills, success toasts, or virtual-camera prompt cards. Draw them natively.
- Treat red rectangles in reference screenshots as privacy masks only. They are not UI.
- Keep all project file references relative to repo root.

---

## PLATFORM TARGET

- macOS 14.0+
- Xcode project or Swift Package with macOS app target and test target
- SwiftUI app lifecycle is preferred, with AppKit bridges where necessary
- Menu bar only app: use `LSUIElement = true` later once the app shell is stable
- Unit tests with XCTest
- UI tests only where user-observable flow benefits from them

---

## UI / DESIGN REQUIREMENTS

Use `docs/AirStage_DESIGN_GUIDE.md` and `docs/AirStage_UI_REFERENCE.md`.

Strict:

- Menu bar surface is small and action-first.
- Main actions use clear verbs: Add Note, Share Image, Share Window or Screen.
- Preview window is mostly camera content with minimal chrome.
- Overlay cards float above camera feed with rounded corners and subtle depth.
- Onboarding appears inside preview as a soft material HUD/card.
- Settings uses grouped native macOS sections and standard toggles.
- Experimental features are clearly labelled.
- Debug overlay is optional and off by default.

Do not test exact colors, shadows, radii, blur amounts, spacing, or internal component hierarchy.

Test visible text, actions, states, navigation, layer count, selection, add/remove behaviour, settings persistence, and accessibility labels.

---

## ONBOARDING PRINCIPLE

AirStage onboarding must happen inside the live camera preview. The user should immediately understand the product by doing the real actions:

1. Start with a frosted welcome card over the camera preview.
2. Spawn a tutorial scene item after the user clicks `Show me`.
3. Teach one-hand grab / move.
4. Teach two-hand zoom / scale.
5. Teach shrink-to-vanish deletion.
6. Only after the user completes or skips the gesture tutorial, prompt them to enable the virtual camera.

The onboarding must not feel like a generic setup wizard. It should feel like the user is learning to touch screen-sharing objects in the camera feed.

The tutorial must use the same scene model, renderer, selection bounds, gesture status, and manipulation pipeline as real user content. Do not implement the tutorial as static screenshots, a fake-only overlay, or bitmap assets.

Production builds must not show debug labels such as `layers: 1`, gesture confidence values, or developer measurement dots unless the explicit debug overlay is enabled.

---

## SCENE / LAYER RULES

- Max total layers: `6`.
- Max live window/screen layers: `1`.
- Max image layers: `3`.
- Max note layers: `4`.
- New layers appear fully visible inside the preview.
- Notes appear above image/window layers by default.
- Clicking or grabbing a layer brings it to front.
- Dragging a layer outside the preview by more than `60pt` shows `Release to remove`.
- Releasing outside removes the layer.
- Dragging back inside cancels removal.
- Pressing Delete removes the selected layer.
- `Remove Layer` menu lists current layers by readable title.
- If scene is full, show `Scene is full` and offer `Replace oldest` / `Cancel`.

---

## REQUIRED DEBUG LOGGING

Create `AppLog.swift` early:

```swift
import OSLog

enum AppLog {
    static let app = Logger(subsystem: "com.airstage.app", category: "App")
    static let menu = Logger(subsystem: "com.airstage.app", category: "Menu")
    static let camera = Logger(subsystem: "com.airstage.app", category: "Camera")
    static let scene = Logger(subsystem: "com.airstage.app", category: "Scene")
    static let sources = Logger(subsystem: "com.airstage.app", category: "Sources")
    static let gestures = Logger(subsystem: "com.airstage.app", category: "Gestures")
    static let onboarding = Logger(subsystem: "com.airstage.app", category: "Onboarding")
    static let settings = Logger(subsystem: "com.airstage.app", category: "Settings")
    static let virtualCamera = Logger(subsystem: "com.airstage.app", category: "VirtualCamera")
}
```

Every slice must add logs for new user/system-observable behaviour. Running in Xcode must show useful console output explaining what is happening.

Examples:

```swift
AppLog.scene.info("Layer added id=\(id.uuidString, privacy: .public) kind=\(kind, privacy: .public) title=\(title, privacy: .public)")
AppLog.scene.info("Layer removed id=\(id.uuidString, privacy: .public) reason=draggedOutside")
AppLog.gestures.debug("Pinch changed active=\(active) x=\(x) y=\(y)")
```

---

## CORE CODE CONTRACTS

Use these examples as behavioural contracts. Adapt names to the existing project if needed.

### Scene Layer Model

```swift
import Foundation
import CoreGraphics

struct SceneLayer: Identifiable, Equatable {
    enum Kind: String, Equatable {
        case note
        case image
        case windowCapture
        case tutorial
    }

    let id: UUID
    var kind: Kind
    var title: String
    var position: CGPoint
    var size: CGSize
    var zIndex: Int
    var isSelected: Bool
    var isBeingRemoved: Bool

    init(
        id: UUID = UUID(),
        kind: Kind,
        title: String,
        position: CGPoint,
        size: CGSize,
        zIndex: Int,
        isSelected: Bool = false,
        isBeingRemoved: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.position = position
        self.size = size
        self.zIndex = zIndex
        self.isSelected = isSelected
        self.isBeingRemoved = isBeingRemoved
    }
}
```

### Scene Limits

```swift
struct SceneLimits {
    static let maxTotalLayers = 6
    static let maxWindowLayers = 1
    static let maxImageLayers = 3
    static let maxNoteLayers = 4
    static let removalMargin: CGFloat = 60
}
```

### Drag Outside Removal Rule

```swift
func shouldRemoveLayer(center: CGPoint, sceneBounds: CGRect, margin: CGFloat = SceneLimits.removalMargin) -> Bool {
    let expandedBounds = sceneBounds.insetBy(dx: -margin, dy: -margin)
    return !expandedBounds.contains(center)
}
```

### Onboarding State

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

### Gesture Adapter

```swift
struct HandPoseFrame: Equatable {
    var indexTip: CGPoint?
    var thumbTip: CGPoint?
    var confidence: Double
}

protocol HandPoseTracking {
    func processFrame(_ frame: CVPixelBuffer) async throws -> HandPoseFrame
}
```

Do not bind UI directly to Vision APIs. Put Vision behind an adapter so gesture behaviour can be unit-tested with fake hand frames.

---

## ARCHITECTURE

Use a small native architecture, not a giant framework.

Recommended files/areas:

```text
AirStage/
  App/
    AirStageApp.swift
    AppLog.swift
    MenuBarController.swift or MenuBarView.swift
  Scene/
    SceneLayer.swift
    SceneLimits.swift
    SceneStore.swift
    SceneGeometry.swift
  Preview/
    PreviewWindowController.swift
    PreviewView.swift
    CameraPreviewView.swift
    OverlayLayerView.swift
    QuickAddToolbar.swift
    DebugOverlayView.swift
  Camera/
    CameraPermissionService.swift
    CameraSessionController.swift
  Sources/
    ImageSourcePicker.swift
    DropPasteHandler.swift
    ScreenCaptureSource.swift
  Gestures/
    HandPoseTracking.swift
    VisionHandPoseTracker.swift
    GestureEngine.swift
  Onboarding/
    OnboardingStateMachine.swift
    OnboardingOverlayView.swift
  Settings/
    SettingsStore.swift
    SettingsView.swift
  VirtualCamera/
    VirtualCameraInstaller.swift
    VirtualCameraOutput.swift
Tests/
  SceneStoreTests.swift
  SceneGeometryTests.swift
  OnboardingStateMachineTests.swift
  GestureEngineTests.swift
  SettingsStoreTests.swift
```

If the repo already has a different structure, preserve it and map these responsibilities into existing folders.

---

## IMPLEMENTATION ORDER

Execute through the TDD slices in `docs/AirStage_TDD_BREAKDOWN_PLAN.md`.

High-level order:

1. Project/test/logging foundation.
2. Menu bar shell.
3. Preview window and camera permission state.
4. Scene/layer model and limits.
5. Notes.
6. Images.
7. Selection/drag/resize.
8. Drag-outside removal.
9. Quick-add toolbar.
10. Onboarding.
11. Settings persistence.
12. Debug overlay.
13. Vision hand tracking adapter.
14. Pinch-to-grab.
15. ScreenCaptureKit window layer.
16. Compositor frame path.
17. Virtual camera extension.
18. Final integration and QA.

Do not combine slices.

---

## SUCCESS CRITERIA

The implementation is complete when:

1. App builds with zero errors.
2. Tests pass.
3. App launches as a native macOS utility.
4. Menu bar menu exposes AirStage actions.
5. Preview window opens.
6. Camera permission missing/granted states are visible and logged.
7. Camera feed appears after permission is granted.
8. User can add a note layer.
9. User can add an image layer.
10. User can add one window/screen capture layer.
11. Scene layer limits are enforced.
12. User can select, move, resize, and bring layers to front.
13. User can remove selected layer with Delete.
14. User can drag a layer outside preview and release to remove it.
15. Preview quick-add toolbar appears on hover/focus and works.
16. Onboarding teaches grab/move, zoom/scale, shrink-to-vanish, and virtual-camera activation timing.
17. Settings toggles persist.
18. Debug overlay shows useful state when enabled.
19. Hand tracking can be tested through fake frames.
20. Pinch-to-grab moves a layer in preview.
21. Virtual camera extension is only added after local preview pipeline is stable.
22. Xcode console logs clearly show app/menu/camera/scene/gesture state changes.
23. No proprietary reference assets/copy are shipped.
24. No raw visual constants are asserted in tests unless they are product rules.
