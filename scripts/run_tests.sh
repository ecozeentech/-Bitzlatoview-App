#!/usr/bin/env bash
set -euo pipefail

echo "🧪 Bitzlatoview Mobile – test suite"
echo "===================================="

flutter pub get
flutter analyze
flutter test "$@"

echo ""
echo "✅ Automated tests passed."
echo "📱 Run device tests: flutter run (Android/iOS emulator or physical device)"
echo "📄 See docs/TEST_REPORT.md for full manual test checklist."
