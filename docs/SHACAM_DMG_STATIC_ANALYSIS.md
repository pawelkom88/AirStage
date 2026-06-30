# Shacam DMG Static Analysis

> Static inspection only. The app was not launched. This report is for architecture/product learning, not copying proprietary assets or bypassing licensing.

## What was inspected

- Uploaded file: `Shacam.dmg`
- DMG type: UDIF/zlib-compressed HFS+ image
- Extracted app bundle: `Shacam.app`
- App version: `1.0.1`
- Bundle ID: `works.renato.shacam`
- Minimum macOS: `14.0`
- App style: menu bar app (`LSUIElement = true`)

## Bundle structure

Important bundle contents:

```text
Shacam.app/
  Contents/
    MacOS/Shacam
    Info.plist
    Resources/
      AppIcon.icns
      MenuIconFill.svg
      MenuIconOutline.svg
      shacam-virtual-cam.png
    Frameworks/
      Sparkle.framework
    Library/SystemExtensions/
      works.renato.shacam.cameraext.systemextension/
        Contents/MacOS/works.renato.shacam.cameraext
        Contents/Info.plist
        Contents/embedded.provisionprofile
    embedded.provisionprofile
```

## Confirmed architecture

Shacam uses a modern macOS virtual camera architecture:

```text
macOS menu bar host app
→ camera preview / compositor / UI layers
→ Vision hand tracking
→ ScreenCaptureKit window/screen capture
→ Core Media I/O camera system extension
→ Zoom / Meet / OBS / QuickTime as virtual camera consumers
```

## Important frameworks used by the host app

Confirmed linked frameworks:

- `AVFoundation` — camera input
- `Vision` — hand pose / gesture tracking
- `ScreenCaptureKit` — window/screen capture
- `CoreMediaIO` — virtual camera integration
- `SystemExtensions` — installing/managing the camera extension
- `CoreImage`, `CoreVideo`, `CoreMedia`, `Metal`, `QuartzCore` — rendering/compositing/video pipeline
- `SwiftUI` + `AppKit` — UI/window/menu bar app
- `ServiceManagement` — launch at login
- `Sparkle` — automatic updates outside the Mac App Store

## Virtual camera extension

Extension bundle:

```text
works.renato.shacam.cameraext.systemextension
```

Extension bundle ID:

```text
works.renato.shacam.cameraext
```

Extension package type:

```text
SYSX
```

Camera extension declaration:

```plist
CMIOExtension:
  CMIOExtensionMachServiceName: XATZFBHVVN.works.renato.shacam
```

This confirms the app uses a Core Media I/O Camera Extension rather than only an in-app preview.

## Permissions and system integration

Main app `Info.plist` includes:

```plist
NSCameraUsageDescription:
Shacam uses your camera to show a live feed and let you move overlaid content with your hands.

NSSystemExtensionUsageDescription:
Shacam installs a virtual camera so video-call apps can use the composited view.
```

The app also uses:

- Sparkle update feed: `https://shacam.com/appcast.xml`
- automatic update checks every 86400 seconds
- system extension install entitlement
- application group entitlement
- Developer ID provisioning profile

Main app provisioning entitlements include:

```text
com.apple.developer.system-extension.install = true
com.apple.security.application-groups = XATZFBHVVN.*
keychain-access-groups = XATZFBHVVN.*
```

Extension provisioning entitlements include:

```text
com.apple.security.application-groups = XATZFBHVVN.*
keychain-access-groups = XATZFBHVVN.*
```

## Internal feature names visible from symbols/strings

Static symbol/string inspection revealed useful architecture names:

```text
ARCanvasView
CameraManager
CameraPreview
CompositeRenderer
DeviceScreenManager
DeviceScreenCapture
FileDropView
GestureEngine
HandTracker
HandOverlay
HandHUD
Layer
OverlayCard
OverlayContent
NoteEditor
NotePaper
NoteGrid
OnboardingOverlay
PreviewWindow
SettingsView
SettingsWindowController
SourceManager
VirtualCamera
VirtualCameraOutput
LicenseManager
PaywallView
MenuBarController
```

These names strongly suggest a clean architecture split:

- source capture
- layer model
- preview/compositor
- gesture engine
- virtual camera output
- settings/license/onboarding

## Feature behaviour visible from UI/screenshots/strings

Observed or inferred user-facing features:

- Menu bar control panel
- Master on/off toggle for virtual camera
- Share a window or screen
- Share an image
- Add a note
- Share iPhone or iPad, currently disabled in the screenshot
- Remove layer submenu
- Show preview
- Camera source submenu
- Settings window
- Launch at login
- Debug overlay
- Hand control toggle
- Snap to grid toggle
- Double-pinch to grab, experimental
- Push-pull zoom/depth gesture, experimental
- Onboarding tutorial
- Purchase/licensing flow
- Sparkle update checks

## UI style notes worth recreating, not copying

The UI feels good because it is focused and native:

- Small menu bar surface, not a heavy dashboard
- Minimal labels with clear verbs: “Share a window…”, “Share an image…”, “Add a note”
- Calm grouped settings layout
- Large rounded cards with subtle inner contrast
- Native macOS typography and spacing
- Preview window prioritizes the camera scene, not controls
- Overlay cards are simple, high-contrast, and playful
- Gesture help appears as a soft glass HUD over the camera feed
- Experimental features are clearly marked without overwhelming the main menu

For our own app, recreate the product pattern and interaction quality, but do not copy the app name, icon, proprietary artwork, exact assets, or distinctive copy verbatim.

## Recommended MVP for our version

Do not start by cloning every feature. Build the magic moment first.

### v1 MVP

1. Menu bar app with preview window
2. Camera feed in preview
3. Add one image layer
4. Add one sticky note layer
5. Move layer with mouse first
6. Add Vision-based hand pinch to grab/move layer
7. Add debug overlay/logging
8. Add virtual camera extension only after preview interaction works well

### Defer

- iPhone/iPad sharing
- multi-window capture
- multi-layer advanced editing
- push-pull depth zoom
- double-pinch gesture
- polished licensing
- Sparkle updates
- complex onboarding

## Suggested implementation stack

```text
SwiftUI + AppKit
AVFoundation
Vision
ScreenCaptureKit
CoreImage or Metal compositor
CoreMediaIO Camera Extension
SystemExtensions
ServiceManagement for launch at login
OSLog Logger for debug logs
```

## Main build risk

The hard part is not the UI. The hard parts are:

1. reliable real-time compositing
2. Vision gesture stability
3. virtual camera extension installation and approval UX
4. keeping latency low enough for video calls
5. making permissions understandable

## Best sequencing

```text
1. Local preview only
2. Image/note layers
3. Mouse layer manipulation
4. Gesture tracking debug overlay
5. Pinch-to-grab
6. Window/screen capture
7. Compositor output frame pipeline
8. Virtual camera extension
9. Permission/onboarding polish
10. Licensing/updates
```
