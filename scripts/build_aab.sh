#!/usr/bin/env bash
# Build a release-signed Android App Bundle for Google Play Console.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -f android/key.properties ]]; then
  echo "❌ android/key.properties not found."
  echo "   Copy android/key.properties.example and configure your release keystore."
  exit 1
fi

if [[ ! -f android/app/google-services.json ]]; then
  cp android/app/google-services.json.example android/app/google-services.json
fi

flutter pub get
flutter build appbundle --release

AAB="build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "✅ AAB ready: $AAB"
echo "   Upload to Google Play Console → Release → Create new release"
