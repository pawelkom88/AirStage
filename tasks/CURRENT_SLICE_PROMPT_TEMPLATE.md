# Current Slice Prompt Template

Use this with Codex for each implementation step.

```md
Read:

- `AGENTS.md`
- `docs/00_PROJECT_INDEX.md`
- `docs/AirStage_PRD.md`
- `docs/AirStage_MASTER_IMPLEMENTATION_PROMPT.md`
- `docs/AirStage_TDD_BREAKDOWN_PLAN.md`
- `docs/AirStage_TDD_PROGRESS_TODO.md`
- `docs/AirStage_DESIGN_GUIDE.md`
- `docs/AirStage_UI_REFERENCE.md`
- `docs/AirStage_ASSET_POLICY.md`
- `docs/AirStage_DEBUG_LOGGING_GUIDE.md`

Find the first incomplete slice in `docs/AirStage_TDD_PROGRESS_TODO.md`.

Implement only that slice.

Rules:
- Follow Red → Green → Refactor.
- Write failing tests first.
- Test user/system-observable behaviour.
- Do not implement later slices early.
- Do not add static bitmap assets for onboarding UI.
- Do not copy Shacam assets, copy, or brand.
- Add useful `OSLog.Logger` diagnostics for the slice.
- Run the relevant tests/build.
- Update `docs/AirStage_TDD_PROGRESS_TODO.md` with files changed, tests added, commands run, and remaining risks.

CRITICAL — NON-NEGOTIABLE: Throughout the entire task, until the goal is fully achieved, you must use caveman-style communication and RTK token-saving format. Do not switch back to normal wording unless explicitly instructed. any questions ?

Stop after this slice.
```
