#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="SnapPii"
SCHEME="ScreenshotTool"
PROJECT="ScreenshotTool.xcodeproj"
CONFIGURATION="Debug"
BUNDLE_ID="com.nic.SnapPii"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="$ROOT_DIR/.build/xcode"
APP_BUNDLE="$DERIVED_DATA/Build/Products/$CONFIGURATION/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"

source "$ROOT_DIR/script/signing.sh"
source "$ROOT_DIR/script/versioning.sh"

cd "$ROOT_DIR"

build_app() {
  local build_timestamp
  build_timestamp="$(screenshottool_build_timestamp)"

  local xcodebuild_args=(
    -project "$PROJECT"
    -scheme "$SCHEME"
    -configuration "$CONFIGURATION"
    -derivedDataPath "$DERIVED_DATA"
  )

  while IFS= read -r version_arg; do
    [[ -n "$version_arg" ]] && xcodebuild_args+=("$version_arg")
  done < <(xcodebuild_version_args "$build_timestamp")

  while IFS= read -r signing_arg; do
    [[ -n "$signing_arg" ]] && xcodebuild_args+=("$signing_arg")
  done < <(xcodebuild_signing_args "$CONFIGURATION")

  echo "==> Version $(screenshottool_marketing_version "$build_timestamp") ($build_timestamp)"

  xcodebuild "${xcodebuild_args[@]}" build

  codesign_app_bundle "$APP_BUNDLE" "$CONFIGURATION"
}

open_app() {
  if [[ ! -x "$APP_BINARY" ]]; then
    echo "error: app executable not found at $APP_BINARY" >&2
    return 1
  fi

  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f -R -trusted "$APP_BUNDLE" >/dev/null 2>&1 || true

  /usr/bin/open -n "$APP_BUNDLE"
}

verify_app_launched() {
  local attempt

  for attempt in 1 2 3; do
    if open_app; then
      sleep 2
      if pgrep -x "$APP_NAME" >/dev/null; then
        return 0
      fi
    fi

    sleep 1
  done

  echo "error: $APP_NAME did not stay running after launch" >&2
  return 1
}

pkill -x "$APP_NAME" >/dev/null 2>&1 || true
build_app

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    verify_app_launched
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
