# Bitzlatoview Mobile – Downloads

## Latest Play Console release (v1.0.6)

**Download page:** https://github.com/ecozeentech/-Bitzlatoview-App/releases/tag/v1.0.6-play

On that page, expand **Assets** and download:

| File | Use |
|------|-----|
| `bitzlatoview-mobile-v1.0.6.aab` | Upload to Google Play Console (versionCode 7) |
| `bitzlatoview-release.keystore` | Keep safe — required for future updates |
| `PLAY_CONSOLE_SIGNING.txt` | Keystore passwords and certificate fingerprints |

### Direct download links

- [AAB (Play Console)](https://github.com/ecozeentech/-Bitzlatoview-App/releases/download/v1.0.6-play/bitzlatoview-mobile-v1.0.6.aab)

### Previous release

- [v1.0.5-play](https://github.com/ecozeentech/-Bitzlatoview-App/releases/tag/v1.0.5-play) (versionCode 6 — superseded)

## Play Console upload

1. Go to [play.google.com/console](https://play.google.com/console)
2. **Release → Production** (or Internal testing) → **Create new release**
3. Upload `bitzlatoview-mobile-v1.0.6.aab`

## Advertising ID note

This build includes `com.google.android.gms.permission.AD_ID` to match a Play Console declaration of **Yes**. The app does not show ads or use AdMob. If you prefer, you can set the Play Console Advertising ID declaration to **No** instead (future builds can omit this permission).
