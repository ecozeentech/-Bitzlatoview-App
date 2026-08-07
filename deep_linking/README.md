# Deep Linking Setup

Host these files on the web platform so OS verification succeeds:

| File | Public URL |
|------|------------|
| `assetlinks.json` | `https://app.bitzlatoview.com/.well-known/assetlinks.json` |
| `apple-app-site-association` | `https://app.bitzlatoview.com/.well-known/apple-app-site-association` |

## Android

1. Generate the SHA-256 fingerprint of your upload / App Signing key:
   ```bash
   keytool -list -v -keystore upload-keystore.jks -alias upload
   ```
2. Replace `REPLACE_WITH_YOUR_UPLOAD_KEYSTORE_SHA256_FINGERPRINT` in `assetlinks.json`.
3. Serve the file with `Content-Type: application/json`.

## iOS

1. Replace `TEAMID` with your Apple Developer Team ID.
2. Ensure the bundle ID matches Xcode (`com.bitzlatoview.bitzlatoviewMobile`).
3. Serve `apple-app-site-association` with `Content-Type: application/json` and **no** `.json` extension.
4. Enable **Associated Domains** and **Push Notifications** capabilities in Xcode.

## Custom scheme

The app also accepts `bitzlatoview://path` links (e.g. `bitzlatoview://trade/123`), which are normalized to `https://app.bitzlatoview.com/trade/123`.
