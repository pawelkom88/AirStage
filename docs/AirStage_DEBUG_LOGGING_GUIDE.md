# AirStage — Debug Logging Guide

AirStage must be easy to run in Xcode and understand from Console logs. Every TDD slice must add logs for the behaviour it implements.

## Logger Contract

Use `OSLog.Logger`, not `print`, for production debug logs.

Create a central logger file early:

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

Replace `com.airstage.app` with the final bundle identifier only when the project has one.

## Required Log Events

### App/Menu

```swift
AppLog.app.info("AirStage launched version=\(version, privacy: .public)")
AppLog.menu.info("Menu action selected action=\(action, privacy: .public)")
AppLog.menu.info("Preview requested")
AppLog.menu.info("Settings requested")
```

### Camera

```swift
AppLog.camera.info("Camera permission status=\(status, privacy: .public)")
AppLog.camera.info("Camera session starting device=\(deviceName, privacy: .public)")
AppLog.camera.error("Camera session failed error=\(error.localizedDescription, privacy: .public)")
```

### Scene / Layers

```swift
AppLog.scene.info("Layer added id=\(id.uuidString, privacy: .public) kind=\(kind, privacy: .public) title=\(title, privacy: .public)")
AppLog.scene.info("Layer selected id=\(id.uuidString, privacy: .public)")
AppLog.scene.debug("Layer moved id=\(id.uuidString, privacy: .public) x=\(x) y=\(y)")
AppLog.scene.info("Layer removal armed id=\(id.uuidString, privacy: .public) reason=draggedOutside")
AppLog.scene.info("Layer removed id=\(id.uuidString, privacy: .public) reason=\(reason, privacy: .public)")
AppLog.scene.notice("Scene full kind=\(kind, privacy: .public) total=\(total)")
```

### Onboarding

```swift
AppLog.onboarding.info("Onboarding started")
AppLog.onboarding.info("Onboarding step changed step=\(step, privacy: .public)")
AppLog.onboarding.info("Onboarding completed")
AppLog.onboarding.info("Onboarding reset")
```

### Gestures

```swift
AppLog.gestures.debug("Hand landmarks updated count=\(count)")
AppLog.gestures.info("Pinch began hand=\(hand, privacy: .public)")
AppLog.gestures.debug("Pinch moved x=\(x) y=\(y)")
AppLog.gestures.info("Pinch ended hand=\(hand, privacy: .public)")
```

### Virtual Camera

```swift
AppLog.virtualCamera.info("Virtual camera install requested")
AppLog.virtualCamera.info("System extension status=\(status, privacy: .public)")
AppLog.virtualCamera.error("Virtual camera failed error=\(error.localizedDescription, privacy: .public)")
```

## Debug Overlay

When `Debug overlay` is enabled:

- Show current camera permission status.
- Show layer count and selected layer title.
- Show hand tracking status.
- Show pinch state.
- Show frame/render status once compositor exists.

Do not show debug overlay by default.

## Testing Logs

Tests do not need to assert every log line. Behaviour tests should verify behaviour. Add log assertions only when a log line is itself part of the required debug contract for the slice.

## What Not To Do

- Do not use `print` as the main debug system.
- Do not log private image paths unless needed; use `.private` for local file paths.
- Do not spam frame-by-frame logs at `.info` level.
- Use `.debug` for high-frequency movement/gesture updates.

## Production Debug Visibility Rule

Reference screenshots show developer diagnostics such as `layers: 1`, gesture confidence values, and tracking dots. These are useful during development, but they must not be visible in production by default.

Required behavior:

- Debug overlay is off by default.
- Confidence labels and layer-count debug panels are shown only when Debug overlay is enabled.
- Production onboarding may show simplified gesture readiness dots, but not raw confidence numbers.
- Logs should record onboarding and gesture state, but UI should stay clean during normal use.
