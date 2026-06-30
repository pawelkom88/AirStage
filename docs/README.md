# AirStage Docs

Read these docs in this order:

1. `../AGENTS.md`
2. `00_PROJECT_INDEX.md`
3. `AirStage_PRD.md`
4. `AirStage_MASTER_IMPLEMENTATION_PROMPT.md`
5. `AirStage_TDD_BREAKDOWN_PLAN.md`
6. `AirStage_TDD_PROGRESS_TODO.md`
7. `AirStage_DESIGN_GUIDE.md`
8. `AirStage_UI_REFERENCE.md`
9. `AirStage_ONBOARDING_UI_REFERENCE.md`
10. `AirStage_ASSET_POLICY.md`
11. `AirStage_DEBUG_LOGGING_GUIDE.md`
12. `AirStage_ICON_AND_DMG_INSTALLER_GUIDE.md`
13. `AirStage_CODEX_RUNBOOK.md`
14. `SHACAM_DMG_STATIC_ANALYSIS.md`

## Important rules

- Build one TDD slice at a time.
- Do not implement virtual camera output before local preview, layers, interactions, onboarding, and compositor are stable.
- Do not use onboarding screenshots as app assets.
- Draw onboarding UI natively with SwiftUI/AppKit.
- Ignore red privacy masks in reference screenshots.
- Keep the app native, local-only, and meeting-speed focused.
