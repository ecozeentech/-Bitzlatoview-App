#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "🚀 Starting iOS deployment build..."

if [[ ! -f ios/Runner/GoogleService-Info.plist ]]; then
  echo "⚠️  ios/Runner/GoogleService-Info.plist not found."
  echo "   Copy ios/Runner/GoogleService-Info.plist.example and add your Firebase config."
fi

flutter clean
flutter pub get

if [[ "$(uname)" == "Darwin" ]]; then
  (cd ios && pod install)
  flutter build ios --release --no-codesign
  echo "✅ iOS release build prepared."
  echo "📱 Open ios/Runner.xcworkspace in Xcode → Product → Archive → Distribute App"
  open ios/Runner.xcworkspace
else
  flutter build ios --release --no-codesign || true
  echo "⚠️  Full iOS archive requires macOS with Xcode."
  echo "   On a Mac: cd ios && pod install && open Runner.xcworkspace"
fi

# Optional Fastlane upload:
# cd fastlane && fastlane ios deploy
