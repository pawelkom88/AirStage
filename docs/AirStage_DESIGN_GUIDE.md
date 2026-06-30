# AirStage — Design Guide

> Use this as the design source of truth together with `AirStage_UI_REFERENCE.md` and the screenshots in `ui-reference/`.

## Design Direction

AirStage should feel like a native macOS utility, not a custom web dashboard. It should be calm, playful, premium, and meeting-safe.

The reference app appears to use native macOS materials and grouped controls rather than a fully custom “liquid glass” system. Recreate the feel using native SwiftUI/AppKit materials and controls:

```swift
.background(.regularMaterial)
.background(.ultraThinMaterial)
.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
.shadow(radius: 12, y: 6)
```

Use default macOS components whenever possible:

- `MenuBarExtra` or AppKit `NSStatusItem` / `NSMenu`
- `Button`
- `Toggle`
- `Settings` scene or custom `NSWindowController`
- `GroupBox` / grouped settings sections
- `NSOpenPanel`
- `SCContentSharingPicker`
- `AVCaptureVideoPreviewLayer`
- native permission prompts and System Settings deep links where possible

## Product Personality

AirStage should feel:

- **Fast** — no heavy dashboard before a meeting.
- **Native** — macOS controls, typography, materials, and window behaviour.
- **Readable** — large enough text inside overlays because it appears on camera.
- **Playful** — sticky notes and cards can feel tactile.
- **Calm** — avoid bright noisy SaaS gradients and clutter.
- **Safe** — clear local-only privacy stance and obvious removal controls.

## Screens / Surfaces

### 1. Menu Bar Menu

Purpose: fast access before or during a meeting.

Required visible actions:

- AirStage title + master on/off toggle.
- Add Note.
- Share Image…
- Share Window or Screen…
- Remove Layer submenu.
- Show Preview.
- Camera submenu.
- Version text.
- Settings…
- Quit.

Design rules:

- Small, action-first, no marketing copy.
- Use native menu semantics.
- Disabled items should look disabled with native disabled styling.
- Remove Layer submenu should list current layers by readable title.

### 2. Preview Window

Purpose: the live stage.

Required behaviour:

- Shows camera feed when permission exists.
- Shows friendly permission state when camera permission is missing.
- Contains overlay layers above camera feed.
- Hover toolbar appears only when pointer moves over preview.
- Onboarding cards appear inside preview, not only in settings.
- Debug overlay appears when enabled.

Design rules:

- Minimal chrome; camera scene is the content.
- Overlay cards have rounded corners and subtle shadow.
- Gesture/onboarding HUD uses native material and large readable text.
- Use safe placement so new layers are not half offscreen.

### 3. Overlay Layers

Layer types:

- Sticky note.
- Image card.
- Live window/screen card.
- Tutorial/gesture hint card.

Layer behaviour:

- Selected layer has an obvious but tasteful affordance.
- Resize handles can appear only when selected/hovered.
- A layer being dragged outside should fade/desaturate and show a removal hint.
- Notes should stay readable at camera-call sizes.

### 4. Hover Quick-Add Toolbar

This is an AirStage improvement over the reference menu-only flow.

Purpose: avoid tedious menu bar dropdowns during a meeting.

Appears when:

- Preview window is focused or pointer enters it.
- Fades out after short inactivity.

Actions:

- `+ Note`
- `+ Image`
- `+ Window`
- `Paste`
- `Clear`

Design:

- Soft material pill, centered near the top or bottom edge.
- Native button style.
- No permanent controls blocking camera.

### 5. Settings Window

Required sections:

- About
- Account placeholder, v1 can say “Local preview build” instead of purchase/licensing
- General
- Gestures
- Onboarding
- Debug

Required settings:

- Launch at login
- Debug overlay
- Hand control
- Snap to grid
- Onboarding tutorial: Show / Reset

Design rules:

- Grouped native macOS settings style.
- Toggles on the right, labels on the left.
- Experimental labels are small pills.
- Do not overbuild a dashboard.

## Onboarding Pattern

Recreate the reference pattern: onboarding appears as soft material cards inside the preview and teaches the real interaction by doing.

Do not copy exact Shacam copy. Use original AirStage copy.

Required onboarding steps:

1. **Add your first layer** — user creates note or image.
2. **Grab it** — user drags with mouse or pinches when hand control is enabled.
3. **Move it** — user moves layer to another safe position.
4. **Resize it** — user uses corner handles first.
5. **Remove it** — user drags outside preview and releases.
6. **Use it in calls** — later, explains virtual camera selection.

## Native Material Recipes

Use these as guidance, not exact visual tests.

```swift
struct MaterialCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(radius: 12, y: 6)
    }
}
```

```swift
struct ExperimentalBadge: View {
    var body: some View {
        Text("Experimental")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.tertiary)
            .clipShape(Capsule())
    }
}
```

## What Tests Should Verify

Do test:

- visible text
- menu actions
- preview permission states
- onboarding step progression
- layer count rules
- selected/dragged/removing states
- Delete-key removal
- drag-outside removal
- settings persistence
- accessibility labels for key controls

Do not test:

- exact blur radius
- exact color values
- exact corner radii
- exact shadow values
- exact internal SwiftUI view hierarchy
- snapshots as the primary contract

## Do Not Copy

Do not copy Shacam’s:

- app name
- icon
- exact overlay artwork
- exact onboarding copy
- exact purchase copy
- exact brand colors as a trademark-like identity
- proprietary assets or license behaviour

Recreate the product quality and interaction pattern as AirStage.

## Live Camera Onboarding UI

Use `docs/AirStage_ONBOARDING_UI_REFERENCE.md` and `ui-reference/onboarding/` for the detailed flow.

### Implementation rule

The onboarding screenshots are visual references only. Do not use the pink cards, instruction pills, dashed boxes, finger dots, success messages, or modal cards as bitmap assets. Recreate them using native SwiftUI/AppKit drawing primitives.

The red rectangles visible in some screenshots are privacy masks only. They are not part of the product UI and must not be implemented.

The tutorial card must be implemented as a real scene item using the same scene model, rendering pipeline, hit testing, gesture handling, scaling, movement, and removal rules as normal user content.

### Visual style

- Camera preview remains full-bleed behind all onboarding UI.
- Onboarding cards use frosted glass material, generous corner radius, soft blur, and subtle warm tint.
- Text is white or near-white over translucent material.
- Primary buttons use soft capsule shapes with subtle inner highlight.
- Avoid heavy borders, neon effects, or developer-looking panels.

### Components

#### Welcome card

- Position: centered over camera preview.
- Shape: rounded rectangle with large continuous radius.
- Material: translucent frosted glass.
- Content: small gesture icon, title, short body text, primary CTA.

#### Gesture status pill

- Position: bottom-left.
- Purpose: shows hand tracking / gesture readiness.
- Production version uses simple status dots only.
- Developer confidence values may exist behind a debug flag but must not ship as default UI.

#### Tutorial scene card

- Shape: rounded square or rounded rectangle.
- Color: high-contrast accent color.
- Contains an SF Symbol and short instruction text.
- Has selection outline while active.
- Shows manipulation handles / tracked pinch points only when they help the user understand the gesture.

#### Instruction toast

- Position: bottom-center.
- Shape: frosted rounded rectangle.
- Content: small gesture icon, bold action label, one short instruction line.

#### Success toast

- Position: bottom-center.
- Shape: compact frosted or accent capsule.
- Content: checkmark icon and short success label such as `Nice!`, `Well done!`, or `Amazing!`.

#### Virtual camera prompt

- Position: centered over camera preview after tutorial completion.
- Content: camera toggle/icon, title `You’ve got the moves`, body text explaining virtual-camera use, actions `Maybe later` and `Turn it on`.
