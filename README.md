# Bitzlatoview Mobile

A native Flutter application for Android and iOS that wraps the
[app.bitzlatoview.com](https://app.bitzlatoview.com) fintech platform in a
high-performance WebView, while providing real native functionality: push
notifications, biometric app-lock, a native file picker/camera bridge for KYC,
deep linking, offline handling and a native settings screen.

This is intentionally **not** a thin WebView wrapper — see
["Why this isn't just a WebView wrapper"](#why-this-isnt-just-a-webview-wrapper)
for how the app satisfies Apple App Store Guideline 4.2 and Google Play policy.

> ⚠️ All financial transactions happen server-side on app.bitzlatoview.com.
> This app only renders the platform's UI and forwards user input/native
> device capabilities to it — it never stores or processes funds locally.

## Table of contents

- [Tech stack](#tech-stack)
- [Project structure](#project-structure)
- [Getting started](#getting-started)
- [Firebase setup (push notifications)](#firebase-setup-push-notifications)
- [Deep linking setup](#deep-linking-setup)
- [Running the app](#running-the-app)
- [Testing](#testing)
- [Building for release](#building-for-release)
- [Store submission checklist](#store-submission-checklist)
- [Security notes](#security-notes)
- [Why this isn't just a WebView wrapper](#why-this-isnt-just-a-webview-wrapper)
- [Troubleshooting](#troubleshooting)

## Tech stack

| Concern | Package |
| --- | --- |
| WebView | `flutter_inappwebview` |
| State management | `provider` |
| Navigation | `go_router` |
| Push notifications | `firebase_messaging` + `flutter_local_notifications` |
| Local storage | `shared_preferences` + `flutter_secure_storage` |
| JS ↔ Native bridge | `flutter_inappwebview` JavaScript handlers |
| File picker | `file_picker` |
| Camera (selfie/KYC) | `image_picker` |
| Biometrics | `local_auth` |
| Deep linking | `app_links` |
| Connectivity | `connectivity_plus` |
| Location (P2P matching) | `geolocator` |
| Share sheet | `share_plus` |
| App icon / splash | `flutter_launcher_icons` / `flutter_native_splash` |

Minimum platform versions: **Android 7.0 (API 24)**, target **Android 14
(API 34)**; **iOS 13.0**.

> **Why `flutter_inappwebview` instead of `webview_flutter` +
> `webview_cookie_manager_plus`?** `flutter_inappwebview` bundles a built-in,
> cross-platform cookie manager, pull-to-refresh controller and a richer
> JavaScript-handler API, which covers everything the original spec asked
> `webview_cookie_manager_plus` + `smart_refresher` + custom
> `javascriptChannels` for for with a single, actively maintained dependency.

## Project structure

```text
lib/
├── main.dart                      # Entry point (Firebase/splash/orientation bootstrap)
├── app.dart                       # MaterialApp.router + provider wiring
├── config/
│   ├── constants.dart             # URLs, storage keys, timeouts
│   └── theme.dart                 # Dark theme with gold accent
├── models/
│   └── webview_events.dart        # JS bridge request/response + push payload models
├── providers/
│   ├── webview_provider.dart      # Loading/error/progress state for the WebView
│   ├── auth_provider.dart         # Session + biometric app-lock state
│   └── notification_provider.dart # Push notification permission/state
├── screens/
│   ├── splash_screen.dart
│   ├── main_shell.dart            # Bottom-nav shell (Home/Settings) + app-lock gate
│   ├── webview_screen.dart        # The core WebView screen
│   ├── offline_screen.dart
│   └── settings_screen.dart
├── widgets/
│   ├── loading_indicator.dart
│   ├── error_widget.dart          # AppErrorView (avoids clashing with Flutter's ErrorWidget)
│   └── bottom_nav_bar.dart
├── services/
│   ├── notification_service.dart  # FCM / local notifications
│   ├── cookie_service.dart        # Cookie persistence (native jar + encrypted backup)
│   ├── js_bridge_service.dart     # JS ↔ Flutter bridge implementation
│   └── deep_link_service.dart     # Universal Links / App Links handling
└── utils/
    ├── validators.dart
    └── helpers.dart

android/                # Android project (manifest, Gradle, signing)
ios/                    # iOS project (Info.plist, entitlements, Podfile)
deep_linking/           # assetlinks.json / apple-app-site-association templates
assets/icon, assets/splash  # Source images for launcher icon & splash screen
```

## Getting started

### Prerequisites

- Flutter 3.29+ (developed against Flutter 3.44 stable) — [install guide](https://docs.flutter.dev/get-started/install)
- Dart 3.7+ (bundled with Flutter)
- Android Studio + Android SDK (API 24–34) for Android builds
- Xcode 15+ for iOS builds (macOS only)
- A Firebase project (for push notifications) — optional for local development

### Install dependencies

```bash
flutter pub get
```

### Regenerate app icon / splash screen (only needed if you change the source images)

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Source images live in `assets/icon/app_icon.png` and
`assets/splash/splash_logo.png`.

## Firebase setup (push notifications)

Real Firebase config files contain project secrets and are **not** committed.
Templates are provided so the project structure is clear:

1. Create a Firebase project and register an Android app
   (`com.bitzlatoview.bitzlatoview_mobile`) and an iOS app
   (`com.bitzlatoview.bitzlatoviewMobile`).
2. Download `google-services.json` and place it at `android/app/google-services.json`
   (see `android/app/google-services.json.example` for the expected shape).
3. Download `GoogleService-Info.plist` and place it at
   `ios/Runner/GoogleService-Info.plist`, then add it to the `Runner` target
   in Xcode so it's copied into the app bundle (see
   `ios/Runner/GoogleService-Info.plist.example`).
4. For iOS, upload your APNs authentication key in the Firebase console
   (Project settings → Cloud Messaging → Apple app configuration).
5. Both `android/app/build.gradle.kts` and the Podfile only wire up
   Firebase when these files are present, so the app **builds and runs fine
   without them** — `NotificationService.initialize()` fails soft and push
   notifications are simply unavailable.

## Deep linking setup

The app supports both a custom scheme (`bitzlatoview://...`, works
immediately, no server config needed) and HTTPS Universal/App Links (requires
hosting two files on the web platform):

- **Android App Links**: host `deep_linking/assetlinks.json` at
  `https://app.bitzlatoview.com/.well-known/assetlinks.json`, filling in your
  real release/debug keystore SHA-256 fingerprints (`keytool -list -v
  -keystore your.jks`).
- **iOS Universal Links**: host `deep_linking/apple-app-site-association` at
  `https://app.bitzlatoview.com/.well-known/apple-app-site-association`
  (served with `Content-Type: application/json`, **no** `.json` extension),
  filling in your real Apple Team ID. Also confirm the
  `com.apple.developer.associated-domains` entitlement in
  `ios/Runner/Runner.entitlements` matches.

Once configured, links like `https://app.bitzlatoview.com/trade/123` or
`bitzlatoview://trade/123` opened outside the app will launch Bitzlatoview
Mobile and load `/trade/123` directly in the WebView
(`lib/services/deep_link_service.dart`).

## Running the app

```bash
flutter run                 # runs on a connected device/emulator
flutter run -d <device-id>  # target a specific device (see `flutter devices`)
```

## Testing

```bash
flutter analyze   # static analysis - should report no issues
flutter test      # unit + widget tests
```

The test suite (`test/`) covers:

- **Utils**: email/URL validation, JSON helpers (`test/utils/`)
- **Models**: JS bridge request/response (de)serialization (`test/models/`)
- **Providers**: `WebViewProvider` loading/error state machine,
  `AuthProvider` session/biometric-lock logic with fake cookie/biometric
  services (`test/providers/`)
- **Services**: the JS bridge dispatcher (unknown actions, clipboard,
  device info, biometric auth, notification permission) and deep-link URL
  resolution (`test/services/`)
- **Screens**: the offline screen's UI and retry behavior (`test/screens/`)

## Building for release

### Android

1. Generate a release keystore (see `android/key.properties.example`) and
   copy it to `android/key.properties` (git-ignored).
2. Build:

   ```bash
   flutter build appbundle --release   # Play Store (.aab)
   flutter build apk --release         # sideloadable .apk
   ```

   Without `android/key.properties`, release builds still work but are
   signed with the debug key (fine for local testing, **not** for Play Store
   submission).

### iOS

1. Open `ios/Runner.xcworkspace` in Xcode (run `pod install` in `ios/` first
   if `Pods/` isn't present yet).
2. Set your Team in the Runner target's Signing & Capabilities tab.
3. Confirm the Associated Domains and Push Notifications capabilities are
   enabled (backed by `ios/Runner/Runner.entitlements`).
4. Archive via Xcode (`Product ▸ Archive`) or:

   ```bash
   flutter build ipa --release
   ```

## Store submission checklist

**Google Play**

- [ ] App icon (512×512 PNG) — export from `assets/icon/app_icon.png`
- [ ] Feature graphic (1024×500 PNG)
- [ ] 8+ screenshots taken from a running build (showing native settings,
      splash, and offline screens alongside the WebView content)
- [ ] Privacy policy URL (`AppConstants.privacyPolicyUrl`)
- [ ] Content rating questionnaire
- [ ] Store listing copy that describes this as a **native companion app**
      with push notifications, biometric lock and offline support — not "just
      a website"
- [ ] Internal test track release

**Apple App Store**

- [ ] App icon (all sizes — generated automatically into
      `ios/Runner/Assets.xcassets/AppIcon.appiconset`)
- [ ] 3+ screenshots per required device class
- [ ] Privacy policy URL
- [ ] App description highlighting native features (Guideline 4.2)
- [ ] TestFlight beta with 10+ testers
- [ ] Final pass against the [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

## Security notes

- All network traffic uses HTTPS; `NSAllowsArbitraryLoads` is `false` on iOS
  and `android:usesCleartextTraffic="false"` on Android.
- Session cookies are the only credential-like data persisted, and only in
  `flutter_secure_storage` (Android Keystore-backed / iOS Keychain-backed
  encryption) — see `lib/services/cookie_service.dart`.
- No financial data, card numbers or passwords are ever stored on-device;
  all financial operations happen server-side.
- `Helpers.debugLog` only prints in debug builds (`kDebugMode`), so release
  binaries never emit diagnostic logs that could leak session data.
- Sensitive actions can be gated behind biometric authentication
  (`AuthProvider.unlock`, and the `biometricAuthenticate` JS bridge action)
  before the web app submits an operation like a withdrawal.
- Privacy Policy / Terms of Service / Risk Disclosure are one tap away from
  the native Settings screen at all times.

## Why this isn't just a WebView wrapper

Beyond rendering `app.bitzlatoview.com`, the app ships with functionality
that has no web equivalent and works even when the WebView content hasn't
loaded:

- Branded native splash screen and bottom navigation (`main_shell.dart`)
- A fully native Settings screen (biometric lock toggle, notification
  toggle, cache management, legal links, support contact, app version)
- Native push notifications (FCM/APNs) that route into the WebView via
  `window.handlePushNotification(...)`, and can be delivered/tapped even
  when the app is backgrounded or killed
- Biometric app-lock that blocks all content (including the WebView) until
  the user authenticates
- A native file picker + camera bridge for KYC document/selfie capture,
  independent of the mobile browser's (often clunky) `<input type=file>` UX
- Deep linking (custom scheme + Universal/App Links) that opens specific
  in-app destinations directly, bypassing the web login/redirect flow
- A dedicated offline screen with automatic reconnection detection

## Troubleshooting

- **`flutter pub get` reports a version-solver conflict around `win32`**:
  several plugins (`file_picker`, `share_plus`, `device_info_plus`,
  `flutter_secure_storage`, `package_info_plus`) also ship optional
  Windows-desktop implementations that pull in different `win32` major
  versions. The versions pinned in `pubspec.yaml` were chosen so they all
  agree on the same `win32` range — if you bump any of them independently,
  re-check this.
- **Android release build fails during `checkDebugAarMetadata` /
  `checkReleaseAarMetadata`** complaining about a required `compileSdk`:
  some plugins require a newer `compileSdk` than the app's `targetSdk`. This
  is expected and already handled (`android/app/build.gradle.kts` sets
  `compileSdk = 37`, independent of `minSdk`/`targetSdk`, which only affect
  runtime behavior and device compatibility).
- **iOS: "no such module 'Firebase...'"**: run `pod install` inside `ios/`
  after adding `GoogleService-Info.plist`, or delete `ios/Podfile.lock` and
  retry if pods are out of sync.
