# AirStage — Codex Agent Instructions

You are working on **AirStage**, a native macOS virtual-camera presentation app.

AirStage lets users place notes, images, and live window/screen layers over their webcam preview, manipulate those layers quickly during meetings, and later output the composed scene through a virtual camera.

## Read order

Before implementing any feature slice, read these files from the repo root:

1. `docs/00_PROJECT_INDEX.md`
2. `docs/AirStage_PRD.md`
3. `docs/AirStage_MASTER_IMPLEMENTATION_PROMPT.md`
4. `docs/AirStage_TDD_BREAKDOWN_PLAN.md`
5. `docs/AirStage_TDD_PROGRESS_TODO.md`
6. `docs/AirStage_DESIGN_GUIDE.md`
7. `docs/AirStage_UI_REFERENCE.md`
8. `docs/AirStage_ASSET_POLICY.md`
9. `docs/AirStage_DEBUG_LOGGING_GUIDE.md`

For onboarding work, also read:

- `docs/AirStage_ONBOARDING_UI_REFERENCE.md`
- `ui-reference/onboarding/`

For app icon, packaging, direct distribution, DMG, signing, or notarization work, also read:

- `docs/AirStage_ICON_AND_DMG_INSTALLER_GUIDE.md`
- `Packaging/README.md`
- `Packaging/create-dmg.sh`

## Non-negotiable rules

- Follow strict TDD: Red → Green → Refactor.
- Write or update failing tests first.
- Test user/system-observable behaviour, not private implementation details.
- Implement only the current slice.
- Do not jump ahead to virtual camera output before local preview, layer model, interactions, onboarding, and compositor are stable.
- Do not copy Shacam branding, exact copy, icons, proprietary assets, or artwork.
- Do not ship reference screenshots as app UI assets.
- Do not use static bitmap assets for onboarding cards, pink tutorial rectangles, selection outlines, gesture dots, instruction toasts, or success toasts. Build those with native SwiftUI/AppKit drawing.
- Treat red rectangles in onboarding screenshots as privacy masks only. They are not part of the UI.
- Keep all paths relative to the repo root.
- Use `OSLog.Logger`, not `print`, for product diagnostics.
- Keep the app privacy-first and local-only.
- Prefer native macOS components and system APIs.

## Slice workflow

For each slice:

1. Restate the slice goal in one paragraph.
2. List the docs you read.
3. Add or update tests first.
4. Run the relevant test command and show the failure.
5. Implement the smallest production change needed.
6. Run tests again.
7. Refactor only after tests pass.
8. Update `docs/AirStage_TDD_PROGRESS_TODO.md` with:
   - files changed
   - tests added/updated
   - commands run
   - remaining risks
9. Stop. Do not implement the next slice.

## Architecture intent

The local preview must be useful before virtual camera work begins:

```text
menu bar shell
→ preview window
→ camera permission/live preview
→ scene model
→ add note/image/window layers
→ mouse interactions
→ drag-outside removal
→ onboarding using real scene items
→ debug overlay/logging
→ hand tracking adapter
→ gesture engine
→ compositor
→ virtual camera extension
→ DMG packaging
```

## Onboarding intent

The onboarding teaches by doing inside the live preview:

```text
welcome card
→ Show me
→ real tutorial scene item appears
→ grab/move
→ success toast
→ zoom/scale
→ success toast
→ shrink-to-vanish
→ success toast
→ virtual camera prompt
```

The tutorial card is a real scene item. It uses the same scene model, renderer, selection bounds, hit testing, scaling, movement, removal logic, and gesture pipeline as normal user content.
