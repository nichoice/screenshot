#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT_DIR/script/versioning.sh"

assert_equal() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "$actual" != "$expected" ]]; then
    echo "assertion failed: $message" >&2
    echo "  expected: $expected" >&2
    echo "  actual:   $actual" >&2
    exit 1
  fi
}

test_marketing_version_uses_timestamp_suffix() {
  local version
  version="$(screenshottool_marketing_version "1777771234")"

  assert_equal "$version" "0.1.1234" "Marketing version should use the last four timestamp digits"
}

test_build_version_uses_full_timestamp() {
  local version
  version="$(screenshottool_build_version "1777771234")"

  assert_equal "$version" "1777771234" "Build version should use the full timestamp"
}

test_marketing_version_uses_timestamp_suffix
test_build_version_uses_full_timestamp

echo "versioning tests passed"
