#!/usr/bin/env bash
# Print SHA-256 fingerprints for assetlinks.json
set -euo pipefail

echo "=== Release keystore (production) ==="
if [[ -f "${1:-}" ]]; then
  keytool -list -v -keystore "$1" -alias "${2:-bitzlatoview}" | grep -A1 "SHA256"
else
  echo "Usage: $0 /path/to/bitzlatoview-release.keystore [alias]"
  echo "Or set KEYSTORE path:"
  echo "  KEYSTORE=~/bitzlatoview-release.keystore $0"
fi

if [[ -n "${KEYSTORE:-}" && -f "$KEYSTORE" ]]; then
  keytool -list -v -keystore "$KEYSTORE" -alias "${ALIAS:-bitzlatoview}" | grep -A1 "SHA256"
fi

echo ""
echo "=== Debug keystore (local testing) ==="
DEBUG_KS="${HOME}/.android/debug.keystore"
if [[ -f "$DEBUG_KS" ]]; then
  keytool -list -v -keystore "$DEBUG_KS" \
    -alias androiddebugkey -storepass android -keypass android \
    | grep -A1 "SHA256"
else
  echo "Debug keystore not found at $DEBUG_KS"
  echo "Run 'flutter run' once on Android to generate it."
fi

echo ""
echo "Add fingerprints to config/deep-linking/assetlinks.json"
