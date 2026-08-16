#!/usr/bin/env bash
# Copy Firebase template configs for local development builds.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -f "$ROOT/android/app/google-services.json" ]]; then
  cp "$ROOT/android/app/google-services.json.example" "$ROOT/android/app/google-services.json"
  echo "Created android/app/google-services.json from example (replace with real Firebase config)."
fi

if [[ ! -f "$ROOT/ios/Runner/GoogleService-Info.plist" ]]; then
  cp "$ROOT/ios/Runner/GoogleService-Info.plist.example" "$ROOT/ios/Runner/GoogleService-Info.plist"
  echo "Created ios/Runner/GoogleService-Info.plist from example (replace with real Firebase config)."
fi

echo "Run 'flutterfire configure' to generate production firebase_options.dart."
