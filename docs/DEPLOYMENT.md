# Bitzlatoview Mobile – Deployment Guide

Complete guide for building, signing, and publishing to Google Play and the Apple App Store.

## Prerequisites checklist

- [ ] Flutter 3.29+ (`flutter doctor`)
- [ ] Firebase project with Android + iOS apps
- [ ] Google Play Developer account ($25)
- [ ] Apple Developer account ($99/year)
- [ ] Privacy policy: https://bitzlatoview.org/privacy
- [ ] Deep link files hosted on production domain

## 1. Local setup

```bash
git clone https://github.com/ecozeentech/bitzlatoview-mobile.git
cd bitzlatoview-mobile
flutter pub get
./scripts/setup_firebase.sh   # Creates local Firebase files from examples
flutterfire configure         # Generates production firebase_options.dart
```

## 2. Deep linking (required before store submission)

Upload files from `config/deep-linking/` to your web server:

| File | Destination |
|------|-------------|
| `assetlinks.json` | `https://bitzlatoview.org/.well-known/assetlinks.json` |
| `apple-app-site-association` | `https://bitzlatoview.org/.well-known/apple-app-site-association` |

Update placeholders:

- `YOUR_RELEASE_SHA256_FINGERPRINT` in `assetlinks.json`
- `TEAM_ID` in `apple-app-site-association`

Verify:

```bash
curl -I https://bitzlatoview.org/.well-known/assetlinks.json
curl -I https://bitzlatoview.org/.well-known/apple-app-site-association
```

## 3. Android – Google Play

### 3.1 Create release keystore

```bash
keytool -genkey -v \
  -keystore ~/bitzlatoview-release.keystore \
  -alias bitzlatoview \
  -keyalg RSA -keysize 2048 -validity 10000
```

### 3.2 Configure signing

```bash
cp android/key.properties.example android/key.properties
# Edit storePassword, keyPassword, keyAlias, storeFile
```

### 3.3 Build release AAB

```bash
./scripts/deploy_android.sh
# Output: build/app/outputs/bundle/release/app-release.aab
```

### 3.4 Google Play Console

1. Create app: **Bitzlatoview** (Free, Finance category)
2. **Production** → Create release → Upload `app-release.aab`
3. Complete store listing (see `docs/STORE_LISTING.md`)
4. Content rating: Adults 18+, financial app questionnaire
5. Start with **Internal testing** track before production rollout

### 3.5 Fastlane (optional)

```bash
cd fastlane
fastlane android deploy
```

## 4. iOS – App Store

### 4.1 Configure Xcode (macOS required)

```bash
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

In Xcode:

- **Bundle ID:** `com.bitzlatoview.bitzlatoviewMobile` (or align to `com.bitzlatoview.app` before first upload)
- **Signing:** Automatic signing with your Apple Developer team
- **Capabilities:** Push Notifications, Associated Domains (`applinks:bitzlatoview.org`), Background Modes → Remote notifications

### 4.2 Build and archive

```bash
./scripts/deploy_ios.sh
```

In Xcode: **Product → Archive → Distribute App → App Store Connect**

### 4.3 App Store Connect

1. Create app: **Bitzlatoview**, SKU `bitzlatoview-001`
2. Category: **Finance**
3. Upload screenshots (iPhone 6.7", optional iPad)
4. Privacy policy URL: https://bitzlatoview.org/privacy
5. Demo account for App Review (provide in Review Notes)
6. Submit for review (typically 24–48 hours)

### 4.4 TestFlight

```bash
cd fastlane && fastlane ios deploy
```

## 5. Post-launch monitoring

- Firebase Crashlytics (configured in `lib/main.dart`)
- Monitor Play Console / App Store Connect crashes and reviews
- Tag releases: `git tag -a v1.0.0 -m "First production release"`

## 6. Troubleshooting

| Issue | Solution |
|-------|----------|
| Android build fails | `flutter clean`, check `minSdk 24`, verify `key.properties` |
| iOS pod errors | `cd ios && pod deintegrate && pod install` |
| Blank WebView | Check HTTPS access to bitzlatoview.org |
| Push not working | Verify Firebase config and device token registration |
| Deep links fail | Confirm `.well-known` files return 200 (currently 404 on production) |
| Apple 4.2 rejection | Highlight native features: push, biometrics, file picker, offline, settings |

## 7. Update workflow

```bash
# Bump version in pubspec.yaml
flutter pub get
./scripts/run_tests.sh
./scripts/deploy_android.sh   # or deploy_ios.sh
git add .
git commit -m "chore: release v1.0.1"
git tag -a v1.0.1 -m "Release v1.0.1"
git push origin main --tags
```
