# AirStage Packaging

Use this folder when building a direct-distribution signed and notarized DMG.

## Expected release structure

```text
Release/
  AirStage.app
Packaging/
  create-dmg.sh
  dmg-background.png      # generated/exported separately at 2x retina
  dmg-volume.icns         # generated/exported separately
Dist/
  AirStage-1.0.0.dmg
```

## Visual target

The DMG should open to a branded Finder window:

```text
AirStage.app  →  Applications
```

Rules:

- Calm dark background.
- Large app icon left.
- Applications folder right.
- Subtle arrow/chevrons in the middle.
- Clear text: `Install AirStage` and `Drag AirStage into Applications`.
- Do not place important text underneath Finder icon labels.

See `docs/AirStage_ICON_AND_DMG_INSTALLER_GUIDE.md` for the full signing, notarization, and design flow.
