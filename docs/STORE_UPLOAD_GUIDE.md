# Store Upload Guide – Google Play & Apple App Store

Step-by-step to upload **Bitzlatoview Mobile v1.0.0** to both stores.

---

## Before you start (both stores)

| Item | Status |
|------|--------|
| Google Play Developer account ($25) | ☐ |
| Apple Developer account ($99/yr) | ☐ |
| Firebase project configured (`flutterfire configure`) | ☐ |
| Deep link files live on `app.bitzlatoview.com` | ☐ |
| Privacy policy URL live | ☐ |
| Test account for reviewers | ☐ |
| App icon + screenshots ready | ☐ |

Copy for listings: `docs/STORE_LISTING.md`

---

# Part A: Google Play Store (Android)

## A1. Create release keystore (one-time)

```bash
keytool -genkey -v \
  -keystore ~/bitzlatoview-release.keystore \
  -alias bitzlatoview \
  -keyalg RSA -keysize 2048 -validity 10000
```

**Back up this file securely.** Losing it prevents app updates.

## A2. Configure signing

```bash
cp android/key.properties.example android/key.properties
```

Edit `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=bitzlatoview
storeFile=/Users/YOU/bitzlatoview-release.keystore
```

## A3. Update Android App Links fingerprint

```bash
keytool -list -v -keystore ~/bitzlatoview-release.keystore -alias bitzlatoview | grep SHA256
```

Put the SHA-256 value in `config/deep-linking/assetlinks.json` and upload to your server.

## A4. Build the release AAB

```bash
./scripts/setup_firebase.sh
flutterfire configure
./scripts/deploy_android.sh
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## A5. Google Play Console – create app

1. Go to [play.google.com/console](https://play.google.com/console)
2. **Create app**
   - Name: **Bitzlatoview**
   - Default language: English (US)
   - App / Free
3. Complete **Dashboard** setup tasks:

### Store listing
- Short description: from `docs/STORE_LISTING.md`
- Full description: from `docs/STORE_LISTING.md`
- App icon: 512×512 PNG
- Feature graphic: 1024×500 PNG
- Screenshots: minimum 8 (phone)
- Category: **Finance**
- Contact email: support@bitzlatoview.com
- Privacy policy: `https://app.bitzlatoview.com/privacy`

### App content
- Privacy policy
- Ads: No
- Content rating: complete questionnaire → likely **Mature 17+**
- Target audience: 18+
- News app: No
- COVID / health: No
- Data safety: declare data collected (account, device ID for push, etc.)

### Release

1. **Testing → Internal testing → Create new release**
2. Upload `app-release.aab`
3. Release name: `1.0.0`
4. Release notes: *Initial release of Bitzlatoview mobile app*
5. **Review release → Start rollout to Internal testing**
6. Add testers (email list or Google Group)
7. After 1–2 weeks of testing → promote to **Production**

### App signing
- Enroll in **Google Play App Signing** (recommended)
- Upload your upload key / let Google manage

---

# Part B: Apple App Store (iOS)

## B1. Apple Developer setup

1. [developer.apple.com](https://developer.apple.com) → enroll if needed
2. **Certificates, Identifiers & Profiles**
3. **Identifiers → +** → App IDs → `com.bitzlatoview.bitzlatoviewMobile`
4. Enable capabilities:
   - Push Notifications
   - Associated Domains (`applinks:app.bitzlatoview.com`)

## B2. Update Universal Links

Replace `TEAM_ID` in `config/deep-linking/apple-app-site-association` with your Apple Team ID, then upload to server.

## B3. Configure Xcode (macOS required)

```bash
./scripts/setup_firebase.sh
flutterfire configure
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

In Xcode:

| Setting | Value |
|---------|-------|
| Bundle Identifier | `com.bitzlatoview.bitzlatoviewMobile` |
| Version | `1.0.0` |
| Build | `1` |
| Signing | Your Team, Automatic |
| Capabilities | Push Notifications, Associated Domains, Background Modes → Remote notifications |

## B4. Archive and upload

1. Select **Any iOS Device (arm64)** as destination (not simulator)
2. **Product → Archive**
3. When Organizer opens → **Distribute App**
4. **App Store Connect** → **Upload**
5. Options: include bitcode off, upload symbols **on**
6. Wait for processing (10–30 min)

Or via Fastlane:

```bash
cd fastlane
# Edit Appfile with your apple_id
fastlane ios deploy
```

## B5. App Store Connect – create app

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. **My Apps → +** → New App
   - Platform: iOS
   - Name: **Bitzlatoview**
   - Primary language: English (US)
   - Bundle ID: `com.bitzlatoview.bitzlatoviewMobile`
   - SKU: `bitzlatoview-001`

### App Information
- Category: **Finance**
- Content rights: as applicable
- Age rating: complete questionnaire → **17+**

### Pricing and Availability
- Price: **Free**
- Availability: countries of your choice

### Prepare for Submission

| Field | Value |
|-------|-------|
| Description | `docs/STORE_LISTING.md` |
| Keywords | crypto, trading, forex, stocks, nft |
| Support URL | https://app.bitzlatoview.com/support |
| Marketing URL | https://app.bitzlatoview.com |
| Privacy Policy URL | https://app.bitzlatoview.com/privacy |

### Screenshots (required)
- iPhone 6.7" (1290×2796): min 3 screenshots
- Optional: iPad Pro 12.9"

### Build
- Select the uploaded build (appears after processing)
- Export compliance: **No** (unless using custom encryption)

### App Review Information
- Contact: your name, phone, email
- Demo account:
  - Username: `demo@bitzlatoview.com`
  - Password: *(provide a working test password)*
- Notes:
  > Native Flutter client for Bitzlatoview. Includes push notifications, biometric auth, native file/camera for KYC, offline handling, and native settings. Financial operations occur on our servers.

### Submit
1. **TestFlight** tab → add internal testers first
2. After TestFlight validation → **Submit for Review**
3. Typical review: 24–48 hours

---

# Part C: Post-upload checklist

## Google Play
- ☐ Internal testers can install from Play Store
- ☐ Deep links verified with [Digital Asset Links tool](https://developers.google.com/digital-asset-links/tools/generator)
- ☐ Push notifications tested via Firebase Console
- ☐ Promote internal → closed → open → production

## Apple
- ☐ TestFlight build installs on physical device
- ☐ Universal Links validated with [Apple tool](https://search.developer.apple.com/appsearch-validation-tool)
- ☐ Push notifications work on physical device (not simulator)
- ☐ App status: **Ready for Sale**

## Both
- ☐ Firebase Crashlytics receiving events
- ☐ Monitor reviews and crash reports
- ☐ Tag release: `git tag -a v1.0.0 -m "Production release"` (already done if pushed)

---

# Quick command reference

```bash
# Android release
./scripts/deploy_android.sh
# → Upload build/app/outputs/bundle/release/app-release.aab to Play Console

# iOS release (macOS)
./scripts/deploy_ios.sh
# → Archive in Xcode → Distribute to App Store Connect

# Verify deep links
curl -sI https://app.bitzlatoview.com/.well-known/assetlinks.json
curl -sI https://app.bitzlatoview.com/.well-known/apple-app-site-association
```
