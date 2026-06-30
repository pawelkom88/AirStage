# AirStage — Codex Runbook

## First Prompt To Codex

Paste this first:

```markdown
Inspect the repo and the AirStage documentation package.

Do not implement app features yet.

Check:
- app builds, or identify what project setup is missing
- test target exists
- `docs/AirStage_PRD.md` exists
- `docs/AirStage_MASTER_IMPLEMENTATION_PROMPT.md` exists
- `docs/AirStage_TDD_BREAKDOWN_PLAN.md` exists
- `docs/AirStage_DESIGN_GUIDE.md` exists
- `docs/AirStage_UI_REFERENCE.md` exists
- `docs/AirStage_DEBUG_LOGGING_GUIDE.md` exists
- `docs/AirStage_TDD_PROGRESS_TODO.md` exists
- `ui-reference/` folder exists
- reference screenshots exist

If something is missing, tell me exactly what is missing.

If everything is ready, update `docs/AirStage_TDD_PROGRESS_TODO.md` with a short setup note.

Do not start implementing product features.
```

## Slice Execution Prompt Template

Use this for each slice:

```markdown
Read:

- `docs/AirStage_MASTER_IMPLEMENTATION_PROMPT.md`
- `docs/AirStage_TDD_BREAKDOWN_PLAN.md`
- `docs/AirStage_TDD_PROGRESS_TODO.md`
- `docs/AirStage_DESIGN_GUIDE.md`
- `docs/AirStage_UI_REFERENCE.md`
- `docs/AirStage_DEBUG_LOGGING_GUIDE.md`

Find the first incomplete slice in `docs/AirStage_TDD_PROGRESS_TODO.md`.

Implement only that slice.

Rules:
- Follow Red → Green → Refactor.
- Write or update failing tests first.
- Test user/system-observable behaviour, not implementation details.
- Add useful `OSLog.Logger` debug logs for this slice.
- Do not implement later slices early.
- Do not create brittle tests for exact visual styling.
- Keep UI native macOS.
- Update `docs/AirStage_TDD_PROGRESS_TODO.md` when done with files changed, tests added, commands run, and debug logs added.

Stop after this slice is complete.
```

## Manual Review Gate

After each slice, review:

1. Did Codex write tests first?
2. Did it keep the slice small?
3. Did it add useful debug logs?
4. Did it avoid future features?
5. Does the app still build?
6. Do tests pass?
7. Does `AirStage_TDD_PROGRESS_TODO.md` reflect the work?

## Important Sequencing Rule

Do not allow Codex to implement virtual camera first. The correct order is:

```text
local preview → layers → mouse interaction → remove flows → onboarding → settings/debug → hand tracking → screen capture → compositor → virtual camera
```

## If Codex Gets Stuck

Ask it to reduce scope to the smallest observable behaviour in the current slice. Do not let it rewrite the app or skip tests.

## Codex Agent Loop Setup

This package is designed for one-slice Codex runs.

Recommended pattern:

```text
Stable docs in repo
→ AGENTS.md operating rules
→ one current slice prompt
→ Codex writes tests
→ Codex implements minimal code
→ Codex runs tests
→ Codex updates progress todo
→ human review
→ next slice
```

Do not paste the entire master prompt on every run. Keep stable context in files and give Codex only the current slice request.

Use `tasks/CURRENT_SLICE_PROMPT_TEMPLATE.md` for each run.

### Required additional checks

The initial inspection prompt should also check:

- `AGENTS.md` exists.
- `docs/00_PROJECT_INDEX.md` exists.
- `docs/AirStage_ONBOARDING_UI_REFERENCE.md` exists.
- `docs/AirStage_ASSET_POLICY.md` exists.
- `docs/AirStage_ICON_AND_DMG_INSTALLER_GUIDE.md` exists.
- `ui-reference/onboarding/` contains 9 onboarding reference screenshots.
- `assets/app-icon/airstage-shutter-a-icon-reference.png` exists.
- `Packaging/create-dmg.sh` exists.

### Onboarding implementation warning

When Codex reaches onboarding slices, remind it:

- Do not add PNG assets for tutorial cards.
- Draw cards, pills, handles, and gesture dots natively.
- The tutorial card must be a real scene item.
- Ignore red privacy masks in screenshots.
