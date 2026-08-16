#!/usr/bin/env bash
# Build a debug-signed release APK for sideloading on Android devices.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -f android/app/google-services.json ]]; then
  cp android/app/google-services.json.example android/app/google-services.json
fi

flutter pub get
flutter build apk --release

APK="build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "✅ APK ready: $APK"
echo "   Install: adb install -r $APK"
echo "   Or copy the file to your phone and open it (enable 'Install unknown apps')."
