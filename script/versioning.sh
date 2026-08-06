#!/usr/bin/env bash

screenshottool_build_timestamp() {
  if [[ -n "${SCREENSHOTTOOL_BUILD_TIMESTAMP:-}" ]]; then
    printf '%s\n' "$SCREENSHOTTOOL_BUILD_TIMESTAMP"
    return 0
  fi

  date +%s
}

screenshottool_marketing_version() {
  local timestamp="$1"
  printf '0.1.%s\n' "${timestamp: -4}"
}

screenshottool_build_version() {
  local timestamp="$1"
  printf '%s\n' "$timestamp"
}

xcodebuild_version_args() {
  local timestamp="${1:-}"

  if [[ -z "$timestamp" ]]; then
    timestamp="$(screenshottool_build_timestamp)"
  fi

  printf 'MARKETING_VERSION=%s\n' "$(screenshottool_marketing_version "$timestamp")"
  printf 'CURRENT_PROJECT_VERSION=%s\n' "$(screenshottool_build_version "$timestamp")"
}
