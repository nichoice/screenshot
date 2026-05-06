#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${APP_NAME:-ScreenshotTool}"
SCHEME="${SCHEME:-ScreenshotTool}"
PROJECT="${PROJECT:-ScreenshotTool.xcodeproj}"
CONFIGURATION="${CONFIGURATION:-Release}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="${DERIVED_DATA:-$ROOT_DIR/.build/package-xcode}"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
STAGING_DIR="${STAGING_DIR:-$ROOT_DIR/.build/dmg-staging}"

APP_BUNDLE="$DERIVED_DATA/Build/Products/$CONFIGURATION/$APP_NAME.app"

cd "$ROOT_DIR"

echo "==> Building $APP_NAME ($CONFIGURATION)"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA" \
  build

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "error: app bundle not found at $APP_BUNDLE" >&2
  exit 1
fi

APP_INFO_PLIST="$APP_BUNDLE/Contents/Info.plist"
VERSION="${VERSION:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_INFO_PLIST" 2>/dev/null || true)}"
BUILD_NUMBER="${BUILD_NUMBER:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_INFO_PLIST" 2>/dev/null || true)}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
if [[ -z "${DMG_NAME:-}" ]]; then
  if [[ -n "$VERSION" && -n "$BUILD_NUMBER" ]]; then
    DMG_NAME="$APP_NAME-$VERSION-$BUILD_NUMBER.dmg"
  elif [[ -n "$VERSION" ]]; then
    DMG_NAME="$APP_NAME-$VERSION.dmg"
  else
    DMG_NAME="$APP_NAME-$TIMESTAMP.dmg"
  fi
fi
DMG_PATH="$DIST_DIR/$DMG_NAME"

echo "==> Preparing DMG staging area"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR" "$DIST_DIR"
cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

echo "==> Creating $DMG_PATH"
rm -f "$DMG_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "==> Verifying DMG"
hdiutil verify "$DMG_PATH"

echo "DMG created: $DMG_PATH"
