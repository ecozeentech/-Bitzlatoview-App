# Bitzlatoview Mobile

Native Flutter client for Android and iOS that securely wraps the [Bitzlatoview web platform](https://bitzlatoview.org) with deep device integration.

## Features

- **WebView shell** – High-performance `flutter_inappwebview` renderer for the Bitzlatoview platform
- **Session persistence** – Secure cookie storage via `flutter_secure_storage`
- **JavaScript bridge** – Native file picker, camera, biometrics, location, share, clipboard, and device info
- **Push notifications** – Firebase Cloud Messaging (Android) and APNs (iOS)
- **Deep linking** – Universal Links / App Links for `bitzlatoview.org`
- **Offline support** – Branded offline screen with automatic retry
- **Native settings** – Privacy policy, terms, risk disclosure, logout, and cache management
- **Pull-to-refresh** – Native refresh gesture on the WebView
- **Store compliance** – Native functionality beyond a thin WebView wrapper

## Requirements

- Flutter 3.29+ (Dart 3.7+)
- Android Studio / Xcode for platform builds
- Firebase project (for push notifications)
- Apple Developer account (iOS)
- Google Play Developer account (Android)

## Project Structure

```
lib/
├── main.dart                 # Entry point
├── app.dart                  # App widget, routing, providers
├── config/                   # Constants and theme
├── models/                   # Bridge and event models
├── providers/                # State management (Provider)
├── screens/                  # Splash, WebView, offline, settings
├── services/                 # Cookies, notifications, deep links, JS bridge
├── utils/                    # Helpers and validators
└── widgets/                  # Reusable UI components
```

## Setup

### 1. Clone and install dependencies

```bash
git clone https://github.com/ecozeentech/bitzlatoview-mobile.git
cd bitzlatoview-mobile
flutter pub get
```

### 2. Firebase configuration

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add Android and iOS apps with package `com.bitzlatoview.bitzlatoview_mobile`
3. Download and replace placeholder files:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
4. Update `lib/firebase_options.dart` with your Firebase config (or run `flutterfire configure`)

### 3. Deep linking

Host these files on `bitzlatoview.org`:

- `/.well-known/assetlinks.json` – from `config/deep-linking/assetlinks.json`
- `/.well-known/apple-app-site-association` – from `config/deep-linking/apple-app-site-association`

Update `YOUR_RELEASE_SHA256_FINGERPRINT` and `TEAM_ID` with your signing credentials.

### 4. iOS setup

```bash
cd ios && pod install && cd ..
```

Ensure minimum deployment target is iOS 13.0. Configure push notification capability and associated domains in Xcode.

### 5. Android setup

- Min SDK: 24 (Android 7.0)
- Target SDK: 34
- Signing config for release builds in `android/app/build.gradle.kts`

## Running the App

```bash
# Debug on connected device/emulator
flutter run

# Android release APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (requires macOS + Xcode)
flutter build ios --release
```

## JavaScript Bridge

The web platform can call native features via the `BitzlatoviewBridge`:

```javascript
window.BitzlatoviewBridge.postMessage(JSON.stringify({
  action: 'pickFile',
  params: { accept: 'image/*' },
  callbackId: 'unique-id'
}));

window.onBitzlatoviewBridgeResponse = function(response) {
  console.log(response);
};
```

### Supported actions

| Action | Description |
|--------|-------------|
| `pickFile` | Open native file picker |
| `takePhoto` | Capture photo via camera |
| `getLocation` | Get device GPS coordinates |
| `shareContent` | Open native share sheet |
| `copyToClipboard` | Copy text to clipboard |
| `requestNotificationPermission` | Request push permission |
| `getDeviceInfo` | Return device model and OS |
| `biometricAuthenticate` | Fingerprint / Face ID auth |

## Testing

```bash
# Unit and widget tests
flutter test

# Integration tests (requires device/emulator)
flutter test integration_test
```

## Testing & deployment

```bash
./scripts/run_tests.sh           # Automated tests (analyze + unit/widget)
./scripts/setup_firebase.sh      # Copy Firebase config templates locally
./scripts/deploy_android.sh      # Build Play Store AAB
./scripts/deploy_ios.sh          # Build iOS release (macOS + Xcode)
./scripts/setup_github_repo.sh   # Create & push to bitzlatoview-mobile repo
```

| Guide | Description |
|-------|-------------|
| [Device test walkthrough](docs/DEVICE_TEST_WALKTHROUGH.md) | Step-by-step testing on your Android/iOS device |
| [Store upload guide](docs/STORE_UPLOAD_GUIDE.md) | Google Play + App Store submission |
| [GitHub setup](docs/GITHUB_SETUP.md) | Create `bitzlatoview-mobile` repository |
| [Deep link hosting](config/deep-linking/README.md) | Host App Links / Universal Links on your domain |
| [Test report](docs/TEST_REPORT.md) | Automated results and manual checklist |
| [Deployment guide](docs/DEPLOYMENT.md) | Build, sign, and release |
| [Store listing](docs/STORE_LISTING.md) | Marketing copy and metadata |
| [Beta testing](docs/TESTING.md) | Instructions for internal testers |

## Store Submission

### Google Play

- App icon (512×512)
- Feature graphic (1024×500)
- Screenshots (min. 8)
- Privacy policy URL
- Highlight native features in listing description

### Apple App Store

- App icons (all required sizes)
- Screenshots (iPhone + iPad)
- Privacy policy URL
- TestFlight beta with 10+ testers
- Ensure Guideline 4.2 compliance (native features documented)

## Security

- All traffic over HTTPS
- Cookies stored in encrypted secure storage
- No sensitive financial data stored locally
- Biometric auth for sensitive actions
- Debug logs exclude tokens and passwords

## License

Proprietary – Bitzlatoview. All rights reserved.
