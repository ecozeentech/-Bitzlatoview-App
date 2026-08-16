#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "🚀 Starting Android deployment build..."

if [[ ! -f android/key.properties ]]; then
  echo "⚠️  android/key.properties not found."
  echo "   Copy android/key.properties.example and configure your release keystore."
  echo "   Building with debug signing for now."
fi

if [[ ! -f android/app/google-services.json ]]; then
  echo "⚠️  android/app/google-services.json not found."
  echo "   Copy android/app/google-services.json.example and add your Firebase config."
fi

flutter clean
flutter pub get
flutter build appbundle --release

AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
if [[ -f "$AAB_PATH" ]]; then
  echo "✅ Release AAB built: $AAB_PATH"
  echo "📦 Upload to Google Play Console → Production → Create new release"
else
  echo "❌ AAB not found at expected path."
  exit 1
fi

# Optional Fastlane upload:
# cd fastlane && fastlane android deploy
