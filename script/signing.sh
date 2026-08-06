#!/usr/bin/env bash

select_codesign_identity() {
  local configuration="${1:-Debug}"
  local identities="${2:-}"
  local requested="${SNAPPII_CODESIGN_IDENTITY:-${SCREENSHOTTOOL_CODESIGN_IDENTITY:-}}"

  if [[ -n "$requested" ]]; then
    printf '%s\n' "$requested"
    return 0
  fi

  if [[ "$configuration" == "Release" ]]; then
    awk -F '"' '/Developer ID Application: / { print $2; exit }' <<<"$identities"
    return 0
  fi

  awk -F '"' '
    /Apple Development: / { print $2; exit }
    /Developer ID Application: / { print $2; exit }
  ' <<<"$identities"
}

resolve_codesign_identity() {
  local configuration="${1:-Debug}"
  local identities
  identities="$(security find-identity -p codesigning -v 2>/dev/null || true)"

  select_codesign_identity "$configuration" "$identities"
}

codesign_app_bundle() {
  local app_bundle="$1"
  local configuration="${2:-Debug}"
  local identity="${SCREENSHOTTOOL_RESOLVED_CODESIGN_IDENTITY:-}"

  if [[ -z "$identity" ]]; then
    identity="$(resolve_codesign_identity "$configuration")"
  fi

  if [[ -z "$identity" ]]; then
    cat >&2 <<'EOF'
warning: no stable Apple code signing identity was found.
warning: continuing with the app produced by Xcode, which may be ad-hoc signed.
warning: macOS Screen Recording and Accessibility permissions may need to be granted again after updates.
warning: install an Apple Development or Developer ID Application certificate, or set SNAPPII_CODESIGN_IDENTITY.
EOF
    return 0
  fi

  echo "==> Signing $app_bundle"
  echo "    identity: $identity"
  /usr/bin/codesign --force --deep --options runtime --timestamp=none --sign "$identity" "$app_bundle"
}

xcodebuild_signing_args() {
  local configuration="${1:-Debug}"
  local identity="${SCREENSHOTTOOL_RESOLVED_CODESIGN_IDENTITY:-}"

  if [[ -z "$identity" ]]; then
    identity="$(resolve_codesign_identity "$configuration")"
  fi

  if [[ -n "$identity" ]]; then
    printf 'CODE_SIGN_STYLE=Manual\n'
    printf 'CODE_SIGN_IDENTITY=%s\n' "$identity"
  fi
}
