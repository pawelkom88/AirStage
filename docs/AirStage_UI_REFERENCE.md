# AirStage — UI Reference Inventory

Use the screenshots in `ui-reference/` as reference for structure and interaction quality. They are not assets to ship.

## Reference Files

### `ui-reference/01-settings-window-reference.png`

What to learn:

- Dark native settings window.
- Grouped sections: About, Account, General, Gestures.
- Large section headings.
- Rounded setting groups.
- Native toggles aligned right.
- “Experimental” badges next to risky gesture settings.
- Onboarding tutorial accessible from settings.

Strict requirements for AirStage:

- Settings must use grouped native macOS controls.
- Settings must include General, Gestures, Debug, and Onboarding areas.
- Toggles must persist.
- Experimental features must be visually labelled if included.

Do not test exact window size, colors, blur, or radius.

---

### `ui-reference/02-menu-bar-menu-reference.png`

What to learn:

- Menu bar surface is compact.
- Top row contains app name and master toggle.
- Primary actions are simple verbs.
- Disabled feature appears disabled, not hidden.
- Remove layer is a submenu.
- Version and settings are separated from main actions.

Strict requirements for AirStage:

- Menu must be fast to scan during a meeting.
- Actions required: Add Note, Share Image, Share Window/Screen, Remove Layer, Show Preview, Camera, Settings, Quit.
- Remove Layer submenu must reflect current layers.
- Menu actions must emit useful debug logs.

---

### `ui-reference/03-preview-onboarding-reference.png`

What to learn:

- Preview window puts camera scene first.
- Overlay cards float above the camera with soft depth.
- Sticky notes are playful and readable.
- Gesture instruction appears as a soft material HUD.
- Onboarding teaches by showing the gesture inside the actual preview.

Strict requirements for AirStage:

- Onboarding appears inside the preview window.
- Onboarding teaches the real actions: grab/move, zoom/scale, shrink-to-vanish removal, and virtual-camera activation timing.
- Overlay layers must appear above camera feed.
- Gesture debug/onboarding HUD must not permanently block the whole preview.

---

## Missing UI References AirStage Must Define in Code

The reference app menu flow can be tedious during a meeting. AirStage must improve this with:

### Preview Hover Quick-Add Toolbar

Behaviour:

- Hidden by default.
- Appears on pointer enter / preview focus.
- Contains `+ Note`, `+ Image`, `+ Window`, `Paste`, `Clear`.
- Fades out after inactivity.

Testable contract:

- When preview is hovered, toolbar controls are visible.
- When user clicks `+ Note`, a note layer is added.
- When scene is full, toolbar add actions show “Scene is full”.

### Drag Outside to Remove

Behaviour:

- When selected layer is dragged beyond preview bounds by 60pt, show “Release to remove”.
- If released outside, remove the layer.
- If dragged back inside, cancel removal state.

Testable contract:

- Drag outside sets `isBeingRemoved = true`.
- Releasing outside removes the layer.
- Re-entering bounds sets `isBeingRemoved = false`.

## Accessibility Labels

Use stable accessibility labels for UI tests where needed:

- `AirStage Menu`
- `AirStage Master Toggle`
- `Add Note`
- `Share Image`
- `Share Window or Screen`
- `Show Preview`
- `Preview Quick Add Toolbar`
- `Scene Full Message`
- `Onboarding Card`
- `Debug Overlay`
- `Layer Card`
- `Remove Layer`

## Visual Testing Rule

Do not create brittle tests for exact colors, shadows, radii, spacing, or internal component hierarchy. Tests should verify user-observable behaviour, visible labels, states, actions, persistence, and accessibility output.

## Onboarding Reference Set

Location: `ui-reference/onboarding/`

These screenshots define the onboarding experience for AirStage. The flow must teach the product inside the real camera preview instead of using a separate static wizard.

Important: red privacy masks in the source screenshots are not UI. Ignore them.

| File | What it shows | Implementation notes |
|---|---|---|
| `01_onboarding_welcome_live_preview.png` | Centered frosted welcome card on top of live camera preview | First-run onboarding begins inside the camera preview. Copy should be app-specific, not mention Shacam. Primary CTA starts the tutorial. |
| `02_onboarding_grab_start.png` | Tutorial card appears with dashed selection bounds and grab instruction | A real scene item is spawned. The tutorial must use the same scene model and gesture pipeline as normal objects, not a fake overlay. |
| `03_onboarding_grab_success.png` | User moves the tutorial card and receives success feedback | Show a compact success toast after the movement threshold is met. |
| `04_onboarding_zoom_instruction.png` | Two-hand zoom gesture instruction | Teach scale using two tracked pinch points. The object shows visible resize handles / gesture dots. |
| `05_onboarding_zoom_success.png` | Zoomed object and success feedback | Confirm completion after scale passes a required threshold. |
| `06_onboarding_shrink_instruction.png` | Shrink-to-vanish instruction | Teach deletion by squeezing object very small and holding briefly. |
| `07_onboarding_shrink_hold.png` | Object becomes very small while hold/progress feedback is visible | Show hold progress before deleting the object. |
| `08_onboarding_vanish_success.png` | Object disappears and layer count returns to zero | Confirm deletion with a success toast. |
| `09_onboarding_virtual_camera_prompt.png` | Final prompt to enable virtual camera after tutorial completion | Do not request virtual camera activation until the user understands the interaction model. |

### Native recreation rule

Do not use these screenshots as UI images. Recreate the components with native SwiftUI/AppKit drawing. See `docs/AirStage_ASSET_POLICY.md`.
