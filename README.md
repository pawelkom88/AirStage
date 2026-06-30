# AirStage Build Package

This is the integrated spec handoff for building **AirStage**, a native macOS menu bar app for placing images, notes, and live window/screen layers over a webcam scene.

AirStage is inspired by the interaction pattern observed in Shacam, but it must be an original product: original name, icon, copy, assets, implementation, and release package.

## Start here

1. Read `AGENTS.md`.
2. Read `docs/00_PROJECT_INDEX.md`.
3. Give Codex the prompt in `tasks/CURRENT_SLICE_PROMPT_TEMPLATE.md`.
4. Let Codex implement one TDD slice at a time.
5. Review after each slice.

## Source of truth order

1. `AGENTS.md`
2. `docs/00_PROJECT_INDEX.md`
3. `docs/AirStage_PRD.md`
4. `docs/AirStage_MASTER_IMPLEMENTATION_PROMPT.md`
5. `docs/AirStage_TDD_BREAKDOWN_PLAN.md`
6. `docs/AirStage_TDD_PROGRESS_TODO.md`
7. `docs/AirStage_DESIGN_GUIDE.md`
8. `docs/AirStage_UI_REFERENCE.md`
9. `docs/AirStage_ONBOARDING_UI_REFERENCE.md`
10. `docs/AirStage_ASSET_POLICY.md`
11. `docs/AirStage_DEBUG_LOGGING_GUIDE.md`
12. `docs/AirStage_ICON_AND_DMG_INSTALLER_GUIDE.md`

## Included folders

```text
docs/               Product, design, TDD, onboarding, asset, logging, and distribution specs.
ui-reference/       Reference screenshots only. Do not ship as app assets.
assets/             App icon reference and release asset notes.
Packaging/          DMG creation script and packaging notes.
code-examples/      Example Swift contracts/tests for Codex to adapt.
tasks/              Prompt template for one-slice Codex runs.
```

## Core implementation rule

The first useful milestone is **local preview magic**, not virtual camera output.

Build in this order:

```text
menu bar shell
→ preview window
→ camera permission/live preview
→ scene model
→ add/manage layers
→ mouse interactions
→ drag-outside removal
→ onboarding with real scene item
→ debug/settings
→ hand tracking
→ screen capture
→ compositor
→ virtual camera
→ DMG packaging
```

## Onboarding rule

The onboarding screenshots in `ui-reference/onboarding/` are visual references only. The pink cards, instruction pills, selection boxes, gesture dots, and success toasts must be drawn natively in SwiftUI/AppKit.

The red rectangles in some screenshots are privacy masks only. Do not implement them.

## Non-goals

Do not copy Shacam’s exact name, icon, brand, artwork, onboarding copy, purchase copy, or proprietary implementation. Build AirStage as a clean original macOS app using native Apple frameworks and the documented interaction pattern.
