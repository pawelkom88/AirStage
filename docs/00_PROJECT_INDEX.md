# AirStage — Project Index

This package is the source-of-truth handoff for building AirStage with Codex or another coding agent.

## Product summary

AirStage is a native macOS menu bar app that turns the webcam preview into an interactive presentation canvas. Users can place notes, images, and one live window/screen layer over their camera feed, manipulate them quickly, and later expose the composed scene as a virtual camera for Zoom, Google Meet, OBS, QuickTime, Loom, and similar apps.

## Source-of-truth order

1. `AGENTS.md` — how Codex should operate in this repo.
2. `docs/AirStage_PRD.md` — product scope, flows, acceptance criteria.
3. `docs/AirStage_MASTER_IMPLEMENTATION_PROMPT.md` — implementation context and hard constraints.
4. `docs/AirStage_TDD_BREAKDOWN_PLAN.md` — implementation order and TDD slices.
5. `docs/AirStage_TDD_PROGRESS_TODO.md` — execution tracking.
6. `docs/AirStage_DESIGN_GUIDE.md` — native macOS visual and interaction direction.
7. `docs/AirStage_UI_REFERENCE.md` — reference image inventory and UI rules.
8. `docs/AirStage_ONBOARDING_UI_REFERENCE.md` — detailed first-run onboarding reference.
9. `docs/AirStage_ASSET_POLICY.md` — what is an asset vs what must be built in Swift.
10. `docs/AirStage_DEBUG_LOGGING_GUIDE.md` — OSLog and debug overlay contract.
11. `docs/AirStage_ICON_AND_DMG_INSTALLER_GUIDE.md` — app icon, DMG, signing, notarization.
12. `docs/SHACAM_DMG_STATIC_ANALYSIS.md` — learning/reference only; do not copy proprietary assets.

## Folder map

```text
AirStage_Build_Package/
  AGENTS.md
  README.md
  docs/
    00_PROJECT_INDEX.md
    AirStage_PRD.md
    AirStage_MASTER_IMPLEMENTATION_PROMPT.md
    AirStage_TDD_BREAKDOWN_PLAN.md
    AirStage_TDD_PROGRESS_TODO.md
    AirStage_DESIGN_GUIDE.md
    AirStage_UI_REFERENCE.md
    AirStage_ONBOARDING_UI_REFERENCE.md
    AirStage_ASSET_POLICY.md
    AirStage_DEBUG_LOGGING_GUIDE.md
    AirStage_CODEX_RUNBOOK.md
    AirStage_ICON_AND_DMG_INSTALLER_GUIDE.md
    SHACAM_DMG_STATIC_ANALYSIS.md
  ui-reference/
    01-settings-window-reference.png
    02-menu-bar-menu-reference.png
    03-preview-onboarding-reference.png
    onboarding/
      01_onboarding_welcome_live_preview.png
      02_onboarding_grab_start.png
      03_onboarding_grab_success.png
      04_onboarding_zoom_instruction.png
      05_onboarding_zoom_success.png
      06_onboarding_shrink_instruction.png
      07_onboarding_shrink_hold.png
      08_onboarding_vanish_success.png
      09_onboarding_virtual_camera_prompt.png
    legacy/
      onboarding-step-1.png
      onboarding-step-2.png
  assets/
    app-icon/
      airstage-shutter-a-icon-reference.png
    dmg/
      README.md
  Packaging/
    README.md
    create-dmg.sh
  code-examples/
    AppLog.example.swift
    SceneLayer.example.swift
    SceneStoreTests.example.swift
    GestureEngineTests.example.swift
    OnboardingStateMachineTests.example.swift
  tasks/
    CURRENT_SLICE_PROMPT_TEMPLATE.md
```

## Implementation milestones

1. Project foundation and test target.
2. Native menu bar shell.
3. Preview window with permission placeholder.
4. Camera permission and live preview adapter.
5. Scene model and layer limits.
6. Add/manage note and image layers.
7. Selection, dragging, resizing, deletion, and drag-outside removal.
8. Quick-add toolbar for meeting-speed actions.
9. First-run onboarding using a real tutorial scene item.
10. Settings and debug overlay.
11. Vision hand pose adapter and pinch gesture engine.
12. Window/screen capture through ScreenCaptureKit.
13. Compositor frame pipeline.
14. Virtual camera extension integration gate.
15. Final polish, DMG packaging, signing, notarization.

## Product name rule

The working name is **AirStage**. If the final name changes to **Camvas** or another name, update all user-facing copy, filenames only where needed, bundle display name, and references consistently. Do not mix names in UI.

## Reference image rule

Reference screenshots define interaction quality and layout intent. They are not shippable UI assets. Recreate UI using native SwiftUI/AppKit drawing, SF Symbols, system materials, and original AirStage copy.
