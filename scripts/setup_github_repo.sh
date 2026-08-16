#!/usr/bin/env bash
# Create ecozeentech/bitzlatoview-mobile and push this project.
# Requires: gh CLI authenticated as ecozeentech (or org admin).
set -euo pipefail

REPO="ecozeentech/bitzlatoview-mobile"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if gh repo view "$REPO" &>/dev/null; then
  echo "✅ Repository $REPO already exists."
else
  echo "📦 Creating $REPO..."
  gh repo create "$REPO" \
    --public \
    --description "Bitzlatoview Mobile – Flutter WebView app for Android and iOS" \
    --source . \
    --remote mobile \
    --push
  echo "✅ Created and pushed to https://github.com/$REPO"
  exit 0
fi

git remote remove mobile 2>/dev/null || true
git remote add mobile "https://github.com/$REPO.git"
git push mobile main --tags
git push mobile cursor/bitzlatoview-mobile-app-6cf7 2>/dev/null || true

echo "✅ Pushed main + tags to https://github.com/$REPO"
