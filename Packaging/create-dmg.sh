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

if ! command -v create-dmg >/dev/null 2>&1; then
  echo "create-dmg is missing. Install with: brew install create-dmg" >&2
  exit 1
fi

if [ ! -d "$APP_PATH" ]; then
  echo "Missing app bundle: $APP_PATH" >&2
  exit 1
fi

if [ ! -f "$BACKGROUND_PATH" ]; then
  echo "Missing DMG background: $BACKGROUND_PATH" >&2
  exit 1
fi

if [ ! -f "$VOLUME_ICON_PATH" ]; then
  echo "Missing volume icon: $VOLUME_ICON_PATH" >&2
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
