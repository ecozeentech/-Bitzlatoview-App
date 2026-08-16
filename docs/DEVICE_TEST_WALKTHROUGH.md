# Device Test Walkthrough (Your Machine)

Follow this checklist on a physical device or emulator. Estimated time: **45–60 minutes**.

## Prerequisites

```bash
# 1. Clone the repo
git clone https://github.com/ecozeentech/bitzlatoview-mobile.git
cd bitzlatoview-mobile

# 2. Install dependencies
flutter doctor          # Fix any ✗ items
flutter pub get

# 3. Firebase (required for push notifications)
./scripts/setup_firebase.sh
flutterfire configure   # Select your Firebase project

# 4. Deep links (optional for first run; required before store)
# Upload config/deep-linking/* to app.bitzlatoview.com – see config/deep-linking/README.md
```

---

## Android – Emulator or physical device

### Setup emulator (if no physical device)

1. Open **Android Studio** → **Device Manager**
2. Create device: **Pixel 7**, API **34** (Android 14)
3. Start the emulator

### Run the app

```bash
flutter devices                    # Confirm device is listed
flutter run -d <device-id>       # e.g. emulator-5554
```

### Test checklist – Android

| # | Test | Steps | Pass? |
|---|------|-------|-------|
| 1 | Splash screen | Launch app | ☐ Logo + loading spinner |
| 2 | WebView load | Wait 3–5 sec | ☐ Homepage loads |
| 3 | Login | Use test account | ☐ Dashboard appears |
| 4 | Session persist | Force-stop app, reopen | ☐ Still logged in |
| 5 | Pull to refresh | Pull down on WebView | ☐ Page reloads |
| 6 | Offline mode | Enable airplane mode | ☐ Offline screen shows |
| 7 | Reconnect | Disable airplane, tap Retry | ☐ Content reloads |
| 8 | Settings | Tap gear icon | ☐ Settings screen opens |
| 9 | Privacy / Terms | Tap each legal link | ☐ Opens in browser |
| 10 | Logout | Settings → Logout → confirm | ☐ Returns to login |
| 11 | Feature nav | Tap Spot, P2P, Wallet tabs | ☐ Pages load |
| 12 | File picker | Trigger KYC upload on web | ☐ Native picker opens |
| 13 | Notifications | Allow when prompted | ☐ Permission granted |
| 14 | Deep link | `adb shell am start -a android.intent.action.VIEW -d "https://app.bitzlatoview.com/spot/BTC-USDT"` | ☐ Opens in app |

### Android deep link test command

```bash
adb shell am start -a android.intent.action.VIEW \
  -d "https://app.bitzlatoview.com/spot/BTC-USDT" \
  com.bitzlatoview.bitzlatoview_mobile
```

### Capture logs if something fails

```bash
flutter run -d <device-id> -v
# Or:
adb logcat | grep -i flutter
```

---

## iOS – Simulator or physical device

### Setup simulator (macOS only)

1. Open **Xcode** → **Window → Devices and Simulators**
2. Add **iPhone 15 Pro**, iOS **17+**
3. Boot simulator

### Run the app

```bash
cd ios && pod install && cd ..
flutter run -d <device-id>       # e.g. iPhone 15 Pro
```

For a **physical iPhone**:

1. Connect via USB
2. Xcode → Runner → Signing → select your Team
3. Trust developer certificate on device: **Settings → General → VPN & Device Management**

### Test checklist – iOS

| # | Test | Steps | Pass? |
|---|------|-------|-------|
| 1 | Splash screen | Launch app | ☐ |
| 2 | WebView load | Wait 3–5 sec | ☐ |
| 3 | Login | Test account | ☐ |
| 4 | Session persist | Kill app, reopen | ☐ |
| 5 | Pull to refresh | Pull down | ☐ |
| 6 | Offline mode | Airplane mode | ☐ |
| 7 | Reconnect | Retry button | ☐ |
| 8 | Settings + legal links | Open each | ☐ |
| 9 | Logout | Settings → Logout | ☐ |
| 10 | Face ID / Touch ID | If web triggers biometric | ☐ |
| 11 | Camera / KYC | Trigger selfie upload | ☐ |
| 12 | Push permission | Allow notifications | ☐ |
| 13 | Universal link | Safari: open `https://app.bitzlatoview.com/spot/BTC-USDT` | ☐ Opens in app |

### iOS universal link test

1. Host `apple-app-site-association` on production (see `config/deep-linking/README.md`)
2. Install app on device (not simulator for best results)
3. Open link in **Notes** or **Messages**, long-press → should offer "Open in Bitzlatoview"

---

## Report results

Fill in `docs/TEST_REPORT.md` or send:

- Device model + OS version
- Pass/fail per row above
- Screenshots of any failures
- `flutter doctor -v` output if build issues

```bash
./scripts/run_tests.sh   # Automated tests before manual pass
```
