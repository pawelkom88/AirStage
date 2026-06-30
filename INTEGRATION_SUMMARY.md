# AirStage Integrated Package — Change Summary

Updated on: 2026-06-30

## What changed

- Added `AGENTS.md` so Codex has a stable operating manual.
- Added `docs/00_PROJECT_INDEX.md` as the package map and source-of-truth order.
- Added `docs/AirStage_ASSET_POLICY.md` to clarify what is an asset vs what must be built natively.
- Converted the onboarding addendum into `docs/AirStage_ONBOARDING_UI_REFERENCE.md`.
- Moved the icon/DMG guide into `docs/AirStage_ICON_AND_DMG_INSTALLER_GUIDE.md`.
- Moved the app icon reference into `assets/app-icon/airstage-shutter-a-icon-reference.png`.
- Added `Packaging/create-dmg.sh` and `Packaging/README.md`.
- Added `tasks/CURRENT_SLICE_PROMPT_TEMPLATE.md` for repeatable one-slice Codex runs.
- Cleaned macOS archive metadata: removed `__MACOSX`, `.DS_Store`, and `._*` files.
- Moved older onboarding screenshots to `ui-reference/legacy/`.

## Docs updated

- `README.md`
- `docs/README.md`
- `docs/AirStage_PRD.md`
- `docs/AirStage_MASTER_IMPLEMENTATION_PROMPT.md`
- `docs/AirStage_TDD_BREAKDOWN_PLAN.md`
- `docs/AirStage_TDD_PROGRESS_TODO.md`
- `docs/AirStage_DESIGN_GUIDE.md`
- `docs/AirStage_UI_REFERENCE.md`
- `docs/AirStage_DEBUG_LOGGING_GUIDE.md`
- `docs/AirStage_CODEX_RUNBOOK.md`

## Key decisions now wired everywhere

- Onboarding happens inside the live preview.
- Tutorial card is a real scene item.
- Pink tutorial UI is native SwiftUI/AppKit, not image assets.
- Red rectangles in screenshots are privacy masks only.
- Debug confidence values are hidden in production unless debug overlay is enabled.
- Virtual camera comes late, after local preview, scene model, interactions, onboarding, and compositor.
- DMG packaging is direct-distribution focused but architecture should stay future App Store compatible where practical.

## Next use

1. Put this package at the repo root.
2. Ask Codex to read `AGENTS.md` and `docs/00_PROJECT_INDEX.md`.
3. Use `tasks/CURRENT_SLICE_PROMPT_TEMPLATE.md`.
4. Run one slice at a time.
