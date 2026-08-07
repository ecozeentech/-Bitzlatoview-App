# Bitzlatoview Mobile

Native Flutter client for the [Bitzlatoview](https://app.bitzlatoview.com) platform. The app renders the licensed web application inside a high-performance WebView while providing native capabilities required for App Store / Google Play compliance (Guideline 4.2 minimum functionality).

## Native capabilities

- Secure session / cookie persistence (`flutter_secure_storage`)
- JavaScript bridge for file picker, camera, biometrics, share, clipboard, location, device info
- Firebase Cloud Messaging (Android) + APNs (iOS) with local notification display
- Universal Links / App Links + custom `bitzlatoview://` scheme
- Offline detection with branded recovery screen
- Native settings (privacy, terms, risk disclosure, logout, clear cache, version)
- Branded splash + dark/gold theme aligned with the web platform

All financial transactions are processed server-side over HTTPS. The app does not store sensitive financial data locally and does not promise guaranteed returns.

## Requirements

| Tool | Version |
|------|---------|
| Flutter | 3.29+ (stable) |
| Dart | 3.7+ |
| Android | minSdk 24, targetSdk 34 |
| iOS | 13.0+ |

## Quick start

```bash
git clone https://github.com/ecozeentech/-Bitzlatoview-App.git
cd -Bitzlatoview-App
flutter pub get
flutter run
```

### Firebase (push notifications)

1. Create a Firebase project and add Android / iOS apps with package:
   - Android: `com.bitzlatoview.bitzlatoview_mobile`
   - iOS: `com.bitzlatoview.bitzlatoviewMobile`
2. Copy configs:
   ```bash
   cp android/app/google-services.json.example android/app/google-services.json
   # replace with the real file from Firebase Console
   cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist
   ```
3. Rebuild. Without these files the app still runs; push is disabled gracefully.

### Deep linking

See [`deep_linking/README.md`](deep_linking/README.md). Host `assetlinks.json` and `apple-app-site-association` under `https://app.bitzlatoview.com/.well-known/`.

## Project structure

```
lib/
├── main.dart / app.dart
├── config/          # constants, theme
├── models/          # JS bridge event models
├── providers/       # auth, webview, notifications
├── screens/         # splash, webview, offline, settings
├── widgets/         # loading + error UI
├── services/        # cookies, JS bridge, FCM, deep links
└── utils/           # validators, helpers
```

## JavaScript bridge

The web platform can call native features:

```javascript
window.BitzlatoviewBridge.postMessage(JSON.stringify({
  action: 'pickFile',          // or takePhoto, getLocation, shareContent,
                               // copyToClipboard, requestNotificationPermission,
                               // getDeviceInfo, biometricAuthenticate, openSettings
  params: { accept: 'image/*' },
  requestId: 'optional-id'
}));

window.onBitzlatoviewBridgeResult = (payload) => {
  console.log(payload);
};
```

Push payloads are forwarded via `window.handlePushNotification(data)`.

## Build commands

```bash
# Analyze
flutter analyze

# Unit + widget tests
flutter test

# Android release (AAB for Play Store)
flutter build appbundle --release

# Android APK
flutter build apk --release

# iOS (macOS + Xcode required)
flutter build ipa --release
```

Configure release signing in `android/app/build.gradle.kts` and Xcode before store submission.

## Store compliance notes

- Highlight native features in store listings (notifications, biometrics, file/camera KYC, deep links, offline support) — not “a website in a WebView”.
- Privacy policy / terms / risk disclosure are linked from the native Settings screen.
- HTTPS-only traffic; encrypted cookie storage; no sensitive values in debug logs.
- See `store_assets/README.md` for icon, screenshot, and listing checklist.

## License

Proprietary — © Bitzlatoview. All rights reserved.
