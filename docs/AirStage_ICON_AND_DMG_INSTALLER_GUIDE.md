# AirStage Icon & DMG Installer Production Guide

> Use this document later when creating the final macOS app icon, DMG background, volume icon, and branded drag-to-Applications installer.
>
> Replace **AirStage** with the final app name if the product name changes.

---

## 1. Goal

Create a polished native macOS distribution package:

```text
AirStage.dmg opens
→ Finder shows a branded custom window
→ user drags AirStage.app into Applications
→ app feels professional before it even launches
```

This is **not** a `.pkg` installer. It is a standard macOS drag-to-Applications DMG with a custom Finder background.

The package should feel:

- native to macOS
- premium and trustworthy
- simple enough for non-technical users
- aligned with the app icon and product brand
- calm, dark, and presentation-focused

---

## 2. Brand direction

### Product idea

AirStage is a native macOS virtual-camera presentation tool. Users can place images, windows, notes, and visual objects into their camera feed and control them naturally during meetings.

### Visual keywords

- camera
- stage
- floating canvas
- aperture/shutter
- glass panel
- presenter mode
- live meeting
- macOS utility
- calm pro tool

### Color direction

Use a cool, dark, Apple-quality palette:

```text
Base background:      deep blue-black / graphite navy
Primary glow:         cyan / ice blue
Secondary accent:     steel blue
Metal:                silver / brushed aluminum
Optional warmth:      very subtle spotlight amber, only for DMG background
```

Avoid:

- loud rainbow gradients
- SaaS dashboard colors
- random neon overload
- childish icon shapes
- text inside the app icon
- complex scene illustrations that disappear at small sizes

---

## 3. Final app icon concept

### Chosen direction

The preferred direction is the **camera-shutter letter A** icon:

- rounded-square macOS app icon base
- dark blue / steel glass surface
- glowing cyan rounded inner frame
- central **A** built from metallic camera-aperture blades
- minimal, premium, and readable at Dock size

The symbol should read as:

```text
A = AirStage
A = aperture
A = app icon identity
```

### Icon composition

```text
Outer shape:
- macOS-style rounded square / squircle
- glassy steel-blue rim
- subtle bevel
- soft outer shadow

Inner frame:
- cyan glowing rounded rectangle
- inset from outer edge
- not too bright
- should feel like a camera focus frame / stage boundary

Center symbol:
- capital A
- built from 5–7 shutter/aperture segments
- silver metallic material
- bevelled edges
- clean triangular negative space
- no extra objects
```

### Required icon deliverables

Create a master icon image first:

```text
Master size: 1024 × 1024 px
Format: PNG
Color profile: sRGB
Background: full icon artwork, not transparent
Filename: app-icon-master.png
```

Then export a complete `.icns` file and Xcode asset sizes.

Required AppIcon sizes for macOS/iOS-family compatibility:

```text
16x16
16x16@2x = 32x32
32x32
32x32@2x = 64x64
128x128
128x128@2x = 256x256
256x256
256x256@2x = 512x512
512x512
512x512@2x = 1024x1024
```

If the app target includes iPad/iOS assets, also ensure the AppIcon set contains required iPad sizes such as:

```text
76x76@2x
83.5x83.5@2x
```

---

## 4. Icon generation prompt

Use this prompt for image generation or as a design brief for a designer.

```text
Create a premium macOS app icon for an app called AirStage.

The app lets users place images, windows, notes, and visual objects into their webcam feed during meetings, like a virtual presentation stage.

Design a polished rounded-square macOS Dock icon with a cool dark blue / steel-blue glass base, subtle 3D depth, and a cyan glowing rounded inner frame. In the center, create a clear capital letter A constructed from camera shutter / aperture blade segments. The A should read instantly at small sizes, while also suggesting a camera aperture.

Style requirements:
- native Apple-quality macOS icon style
- premium, calm, professional, not playful
- glossy but not overdone
- clean bevels and soft shadows
- silver metallic A symbol
- dark graphite navy background
- cyan ice-blue glow around the inner frame
- no words, no UI text, no people, no extra objects
- strong silhouette at 64px and 128px
- high-resolution 1024x1024 output
```

### Negative prompt / avoid list

```text
Avoid cartoon style, cheap neon, busy gradients, random camera lens, letters that look like generic logos, unreadable symbols, extra text, small decorative UI objects, overcomplicated 3D scenes, fake app screenshots inside the icon, low contrast, flat SaaS logo style.
```

---

## 5. Icon QA checklist

Before using the icon in the app, verify:

```text
[ ] The central symbol clearly reads as A.
[ ] The A still suggests camera shutter / aperture blades.
[ ] The icon is readable at 16px, 32px, 64px, and Dock size.
[ ] The cyan frame does not overpower the A.
[ ] The icon does not look too close to Shacam or any existing product.
[ ] The icon has no text.
[ ] The icon has no accidental artifacts.
[ ] The icon works on light and dark macOS wallpaper.
[ ] The icon feels premium next to Apple apps in the Dock.
[ ] The final exported `.icns` is used by the app target.
```

---

## 6. DMG installer concept

The installer should be simple:

```text
Left:    AirStage.app icon
Center:  subtle glowing arrow / chevrons
Right:   Applications folder alias
Bottom:  short install instruction
```

Recommended instruction text:

```text
Install AirStage
Drag AirStage into Applications
```

Avoid the clunkier wording:

```text
To install AirStage,
drag the icon into the Applications folder
```

The shorter version feels more native and less like a tutorial.

---

## 7. DMG background design spec

### Finder window size

Use this Finder window size:

```text
Finder window: 760 × 500 pt
Retina background: 1520 × 1000 px
```

### Background file

```text
File: Packaging/dmg-background.png
Size: 1520 × 1000 px
Scale: 2x retina
Format: PNG
Color profile: sRGB
```

### Layout grid

For a `760 × 500` Finder window:

```text
App icon position:          x 190, y 230
Applications alias:         x 570, y 230
Icon size:                  128 px
Main text center:           x 380, y 380
Subtext center:             x 380, y 420
Arrow center:               x 380, y 230
```

### Visual style

```text
Background:
- near-black graphite navy
- subtle radial glow behind both icons
- tiny cyan stage-light glow in the center
- no noisy texture
- no excessive gradients

Arrow:
- 4–5 soft chevrons or one clean arrow
- cyan or soft red/coral depending on icon accent
- subtle glow
- not too bright

Typography baked into background:
- Main: Install AirStage
- Sub: Drag AirStage into Applications
- Use a rounded Apple-like system style
- White main text
- muted gray subtext
- generous spacing
```

### Important Finder label note

Finder will normally draw labels under the `.app` and Applications alias. On a dark background, default black Finder labels can become hard to read.

Recommended approach:

```text
Preferred:
- Keep baked instruction text in the background.
- Let Finder show normal icon labels only if readable enough.
- Avoid placing important text directly below the Finder icons.

Alternative:
- Use a slightly lighter glow plate behind each Finder label area.
- Keep the icon labels short: AirStage and Applications.
```

---

## 8. DMG background generation prompt

Use this to generate the background image only. The real `.app` icon and Applications alias will be placed by Finder/create-dmg, so do **not** bake those into the background unless intentionally creating a mockup.

```text
Create a 2x retina DMG installer background image for a native macOS app called AirStage.

Canvas size: 1520 x 1000 px.

Design a calm premium dark background for a drag-to-Applications macOS installer. The background should feel like a polished Apple-quality utility installer: deep graphite navy, subtle glassy radial lighting, soft cyan glow, and very minimal visual noise.

Leave clear empty space for the real Finder icons:
- app icon area on the left around x=380, y=460 in the 2x image
- Applications folder area on the right around x=1140, y=460 in the 2x image
- arrow/chevrons in the center around x=760, y=460

Include a subtle center arrow or chevrons pointing from left to right, using a soft cyan glow. Keep it elegant and not neon-heavy.

At the bottom center, include clean instruction text:
Install AirStage
Drag AirStage into Applications

Text should be white/muted gray, centered, large enough to read, and not overlap the icon areas.

Do not include fake app icons, fake Applications folder icons, screenshots, people, windows, or complex UI. This is only the branded background behind a Finder DMG window.
```

---

## 9. Recommended project structure

```text
AirStage/
  AirStage.xcodeproj
  AirStage/
    Assets.xcassets/
      AppIcon.appiconset/
  Packaging/
    app-icon-master.png
    dmg-background.png
    dmg-volume.icns
    create-dmg.sh
    release-dmg.sh
  Release/
    AirStage.app
  dist/
    AirStage-1.0.0.dmg
```

Use this naming consistently so Codex/build scripts do not guess paths.

---

## 10. Install create-dmg

Install once:

```bash
brew install create-dmg
```

`create-dmg` is a simple shell-based DMG builder that supports useful options for polished drag-to-Applications installers, including custom backgrounds, window size, icon positions, hiding extensions, volume icons, and an Applications drop link.

---

## 11. create-dmg script

Create:

```text
Packaging/create-dmg.sh
```

Script:

```bash
#!/bin/bash
set -euo pipefail

APP_NAME="AirStage"
VERSION="1.0.0"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RELEASE_DIR="$ROOT_DIR/Release"
DIST_DIR="$ROOT_DIR/dist"

APP_PATH="$RELEASE_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION.dmg"
BACKGROUND_PATH="$ROOT_DIR/Packaging/dmg-background.png"
VOLUME_ICON_PATH="$ROOT_DIR/Packaging/dmg-volume.icns"

if [ ! -d "$APP_PATH" ]; then
  echo "Missing app bundle: $APP_PATH"
  exit 1
fi

if [ ! -f "$BACKGROUND_PATH" ]; then
  echo "Missing DMG background: $BACKGROUND_PATH"
  exit 1
fi

if [ ! -f "$VOLUME_ICON_PATH" ]; then
  echo "Missing DMG volume icon: $VOLUME_ICON_PATH"
  exit 1
fi

mkdir -p "$DIST_DIR"
rm -f "$DMG_PATH"

create-dmg \
  --volname "$APP_NAME" \
  --volicon "$VOLUME_ICON_PATH" \
  --background "$BACKGROUND_PATH" \
  --window-pos 200 120 \
  --window-size 760 500 \
  --icon-size 128 \
  --text-size 14 \
  --icon "$APP_NAME.app" 190 230 \
  --hide-extension "$APP_NAME.app" \
  --app-drop-link 570 230 \
  --no-internet-enable \
  "$DMG_PATH" \
  "$RELEASE_DIR"

echo "Created: $DMG_PATH"
```

Make it executable:

```bash
chmod +x Packaging/create-dmg.sh
```

Run:

```bash
./Packaging/create-dmg.sh
```

---

## 12. Volume icon

The DMG volume icon should be a simpler version of the app icon.

Recommended:

```text
File: Packaging/dmg-volume.icns
Source: same A shutter icon
Simplify: remove tiny bevel details if needed
Keep: dark rounded square + silver A + cyan glow
```

Do not create a completely separate visual identity for the DMG volume icon.

---

## 13. Signing and notarization flow

Before public distribution, use Developer ID signing and notarization for software distributed outside the Mac App Store.

Typical flow:

```bash
codesign --force --deep --options runtime --timestamp \
  --sign "Developer ID Application: Your Name (TEAMID)" \
  "Release/AirStage.app"

./Packaging/create-dmg.sh

codesign --force --timestamp \
  --sign "Developer ID Application: Your Name (TEAMID)" \
  "dist/AirStage-1.0.0.dmg"

xcrun notarytool submit "dist/AirStage-1.0.0.dmg" \
  --keychain-profile "notarytool-profile" \
  --wait

xcrun stapler staple "dist/AirStage-1.0.0.dmg"
```

Then verify:

```bash
codesign -vvv --deep --strict "Release/AirStage.app"
codesign -vvv "dist/AirStage-1.0.0.dmg"
spctl --assess --type open --verbose "dist/AirStage-1.0.0.dmg"
spctl --assess --type execute --verbose "Release/AirStage.app"
```

Important:

```text
[ ] Do not modify the app bundle after signing.
[ ] Do not rebuild the DMG after notarization without notarizing again.
[ ] Staple the notarization ticket to the final DMG.
[ ] Test the downloaded DMG on a clean Mac/user account.
```

---

## 14. Release QA checklist

Before uploading the DMG to the website:

```text
Icon / app bundle
[ ] App icon appears correctly in Finder.
[ ] App icon appears correctly in Dock.
[ ] About window shows correct app name and version.
[ ] Bundle identifier is final.
[ ] Version and build number are final.
[ ] App is signed with Developer ID Application certificate.

DMG visual
[ ] DMG opens at the expected window size.
[ ] Background appears crisp on Retina displays.
[ ] App icon is positioned left.
[ ] Applications alias is positioned right.
[ ] Arrow points clearly from app to Applications.
[ ] Instruction text is readable.
[ ] Finder labels do not clash with background.
[ ] No unwanted files are visible in the DMG.
[ ] .app extension is hidden.
[ ] Volume icon appears correctly in Finder sidebar/Desktop.

Install behavior
[ ] Dragging app to Applications works.
[ ] Launching from Applications works.
[ ] App does not require being run from inside DMG.
[ ] App handles permissions/onboarding correctly after install.

Security
[ ] App bundle signature verifies.
[ ] DMG signature verifies.
[ ] Notarization succeeds.
[ ] Stapling succeeds.
[ ] Gatekeeper allows the app on a clean Mac.
```

---

## 15. Codex implementation prompt

Use this prompt when asking Codex to add packaging support:

```text
You are working on the AirStage macOS app.

Add professional DMG packaging support only. Do not change app features.

Read this document first:
- docs/AirStage_ICON_AND_DMG_INSTALLER_GUIDE.md

Create or verify this structure:
- assets/app-icon/airstage-shutter-a-icon-reference.png
- Packaging/dmg-background.png
- Packaging/dmg-volume.icns
- Packaging/create-dmg.sh
- Release/
- dist/

Implement Packaging/create-dmg.sh using create-dmg with:
- volume name: AirStage
- background: Packaging/dmg-background.png
- volume icon: Packaging/dmg-volume.icns
- window size: 760x500
- icon size: 128
- app icon position: 190,230
- Applications drop link position: 570,230
- hide AirStage.app extension
- output: dist/AirStage-1.0.0.dmg

Add defensive checks for missing app bundle, missing background, and missing volume icon.

Do not sign, notarize, or upload anything yet.
Do not create fake app bundles.
Do not modify the product UI.
After implementation, explain exactly how to run the script locally.
```

---

## 16. Future polish ideas

Optional later improvements:

```text
[ ] Add a signed release script that builds archive → exports app → signs → creates DMG → signs DMG → notarizes → staples.
[ ] Add CI release workflow for tagged versions.
[ ] Add a version argument to create-dmg.sh.
[ ] Add a clean uninstall note in website FAQ.
[ ] Add checksum generation for website downloads.
[ ] Add Sparkle appcast support if using direct updates.
```

---

## 17. Source notes

- `create-dmg` supports custom backgrounds, window size, icon positions, hiding extensions, volume icons, and Applications drop links.
- Apple Developer ID signing and notarization are the expected route for distributing macOS software outside the Mac App Store.
- Apple notarization requires a valid code signature before submission; modifying the app bundle after signing can break notarization.

