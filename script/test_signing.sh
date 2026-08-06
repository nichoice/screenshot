#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT_DIR/script/signing.sh"

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

test_selects_developer_id_for_release() {
  local identities
  identities='  1) ABCDEF1234567890 "Apple Development: Nic Example (TEAMID)"
  2) 1234567890ABCDEF "Developer ID Application: Nic Example (TEAMID)"
     2 valid identities found'

  local identity
  identity="$(select_codesign_identity "Release" "$identities")"

  assert_equal "$identity" "Developer ID Application: Nic Example (TEAMID)" \
    "Release builds should prefer Developer ID Application"
}

test_selects_apple_development_for_debug() {
  local identities
  identities='  1) ABCDEF1234567890 "Apple Development: Nic Example (TEAMID)"
     1 valid identities found'

  local identity
  identity="$(select_codesign_identity "Debug" "$identities")"

  assert_equal "$identity" "Apple Development: Nic Example (TEAMID)" \
    "Debug builds should accept Apple Development"
}

test_returns_empty_when_no_stable_identity_exists() {
  local identity
  identity="$(select_codesign_identity "Release" "     0 valid identities found")"

  assert_equal "$identity" "" "Missing identities should not silently invent a signing identity"
}

test_selects_snappii_requested_identity() {
  local identities
  identities='  1) ABCDEF1234567890 "Apple Development: Nic Example (TEAMID)"
  2) 1234567890ABCDEF "Developer ID Application: Nic Example (TEAMID)"
     2 valid identities found'

  local identity
  identity="$(SNAPPII_CODESIGN_IDENTITY="Apple Development: Nic Example (TEAMID)" \
    select_codesign_identity "Release" "$identities")"

  assert_equal "$identity" "Apple Development: Nic Example (TEAMID)" \
    "Explicit SNAPPII_CODESIGN_IDENTITY should win"
}

test_snappii_identity_takes_priority_over_legacy_variable() {
  local identity
  identity="$(SNAPPII_CODESIGN_IDENTITY="Developer ID Application: New (TEAMID)" \
    SCREENSHOTTOOL_CODESIGN_IDENTITY="Apple Development: Legacy (TEAMID)" \
    select_codesign_identity "Release" "")"

  assert_equal "$identity" "Developer ID Application: New (TEAMID)" \
    "SnapPii identity should take priority over the legacy variable"
}

test_selects_developer_id_for_release
test_selects_apple_development_for_debug
test_returns_empty_when_no_stable_identity_exists
test_selects_snappii_requested_identity
test_snappii_identity_takes_priority_over_legacy_variable

echo "signing tests passed"
