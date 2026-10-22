# Bitzlatoview Mobile – Test Report

**Date:** 2026-08-16  
**App version:** 1.0.0+1  
**Target URL:** https://bitzlatoview.org  
**Branch:** `cursor/bitzlatoview-mobile-app-6cf7`

## Test environment

| Item | Value |
|------|-------|
| CI environment | Linux cloud agent |
| Flutter | 3.29.0 (Dart 3.7.0) |
| Network | Wi-Fi / datacenter |
| Android SDK | Not available in CI (manual build required) |
| iOS/Xcode | Not available in CI (manual build on macOS required) |
| Physical devices | Not available in CI |

## Automated test results

| Suite | Result | Details |
|-------|--------|---------|
| `flutter analyze` | **PASS** | No issues found |
| Unit tests (bridge, validators) | **PASS** | 4/4 |
| Widget tests (splash, offline, settings) | **PASS** | 3/3 |
| Default widget test | **PASS** | 1/1 |
| **Total automated** | **PASS** | **8/8** |

## Live website verification

| Check | Result | Notes |
|-------|--------|-------|
| Homepage HTTPS reachable | **PASS** | HTTP 200, valid HTML content |
| Session cookies issued | **PASS** | `bitzlatoview-session` + `XSRF-TOKEN` over secure cookies |
| Risk disclosure visible | **PASS** | "No guaranteed returns" on landing page |
| `/.well-known/assetlinks.json` | **FAIL** | HTTP 404 – required for Android App Links |
| `/.well-known/apple-app-site-association` | **FAIL** | HTTP 404 – required for iOS Universal Links |

## Manual test matrix (requires device/emulator)

### A. Core navigation & authentication

| Test case | Status | Notes |
|-----------|--------|-------|
| Branded splash screen on launch | **PENDING** | Widget test covers UI; device verification needed |
| WebView loads homepage in 3–5s | **PENDING** | Website reachable; WebView load not tested on device |
| User registration | **PENDING** | Requires test account on live site |
| Login with credentials | **PENDING** | Requires test account |
| Session persists after restart | **PENDING** | Cookie service implemented; device test needed |
| Logout clears session | **PENDING** | Settings logout implemented; device test needed |

### B. Feature functionality

| Feature | Status | Notes |
|---------|--------|-------|
| Dashboard | **PENDING** | Depends on authenticated session |
| Feature bar navigation | **PENDING** | Web-driven; test on device |
| Deposit / Withdraw | **PENDING** | Web flows |
| Spot / P2P / Wallet / Cards | **PENDING** | Web flows |
| KYC upload | **PENDING** | Requires JS bridge + file picker on device |

### C. JavaScript bridge

| Test case | Status | Notes |
|-----------|--------|-------|
| File picker | **PENDING** | `JsBridgeService.pickFile` implemented |
| Camera | **PENDING** | `takePhoto` implemented |
| Clipboard | **PENDING** | `copyToClipboard` implemented |
| Share | **PENDING** | `shareContent` implemented |
| Biometrics | **PENDING** | `biometricAuthenticate` implemented |

### D. Push notifications

| Test case | Status | Notes |
|-----------|--------|-------|
| Permission prompt | **PENDING** | Requires Firebase + physical device |
| Foreground notification | **PENDING** | Placeholder Firebase config |
| Background notification | **PENDING** | Requires production FCM |
| Deep link from notification | **PENDING** | Handler implemented |

### E. Offline & performance

| Test case | Status | Notes |
|-----------|--------|-------|
| Offline screen | **PASS** | Widget test + `connectivity_plus` integration |
| Reconnect retry | **PENDING** | Logic implemented; device test needed |
| Heavy page performance | **PENDING** | Device profiling required |
| Memory stability (10+ min) | **PENDING** | Device profiling required |

### F. Deep linking

| Test case | Status | Notes |
|-----------|--------|-------|
| Universal link `bitzlatoview.org/...` | **BLOCKED** | Server files return 404 |
| Custom scheme `bitzlatoview://` | **PENDING** | Intent filters configured; device test needed |

### G. UI consistency

| Test case | Status | Notes |
|-----------|--------|-------|
| Dark theme | **PASS** | Native shell uses dark + gold theme |
| Web fonts/spacing | **PENDING** | Inherited from website in WebView |
| Button tap targets | **PENDING** | Device UX review needed |

## Summary

| Category | Pass | Fail | Pending | Blocked |
|----------|------|------|---------|---------|
| Automated | 8 | 0 | 0 | 0 |
| Infrastructure | 3 | 2 | 0 | 0 |
| Manual (device) | 0 | 0 | 22 | 1 |

## Recommendations

1. **Host deep link files** – Deploy `config/deep-linking/assetlinks.json` and `apple-app-site-association` to `https://bitzlatoview.org/.well-known/`.
2. **Replace Firebase placeholders** – Run `flutterfire configure` and copy real `google-services.json` / `GoogleService-Info.plist`.
3. **Device test pass** – Run `flutter run` on Pixel emulator (API 34) and iPhone 15 simulator; complete the pending matrix above.
4. **Release signing** – Create release keystore and `android/key.properties` before Play Store upload.
5. **Web bridge integration** – Ensure the website calls `window.BitzlatoviewBridge.postMessage` for KYC/camera flows.
6. **Crashlytics** – Firebase Crashlytics wired in `main.dart`; verify after production Firebase setup.

## How to re-run tests

```bash
./scripts/run_tests.sh
flutter run                    # Device/emulator manual testing
```
