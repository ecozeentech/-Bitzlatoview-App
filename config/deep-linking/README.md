# Deep Link Files – Hosting on app.bitzlatoview.com

These files must be publicly accessible **without redirects** at:

| Platform | URL |
|----------|-----|
| Android App Links | `https://app.bitzlatoview.com/.well-known/assetlinks.json` |
| iOS Universal Links | `https://app.bitzlatoview.com/.well-known/apple-app-site-association` |

## 1. Get your signing credentials

### Android SHA-256 fingerprint

After creating your release keystore:

```bash
keytool -list -v \
  -keystore ~/bitzlatoview-release.keystore \
  -alias bitzlatoview \
  | grep "SHA256"
```

Copy the fingerprint (colon-separated) into `assetlinks.json`.

For **debug builds** during testing, also add your debug keystore fingerprint:

```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android -keypass android \
  | grep "SHA256"
```

### Apple Team ID

1. Go to [Apple Developer → Membership](https://developer.apple.com/account)
2. Copy your **Team ID** (10 characters, e.g. `AB12CD34EF`)
3. Replace `TEAM_ID` in `apple-app-site-association` with: `TEAM_ID.com.bitzlatoview.bitzlatoviewMobile`

## 2. Update the config files

Edit before uploading:

- `assetlinks.json` – replace `YOUR_RELEASE_SHA256_FINGERPRINT`
- `apple-app-site-association` – replace `TEAM_ID`

## 3. Deploy to Hostinger (Laravel / PHP)

Your site runs on Hostinger with Laravel. Upload files to the **public web root**:

```
public/
  .well-known/
    assetlinks.json
    apple-app-site-association
    .htaccess          # copy from this folder
```

### Via Hostinger File Manager

1. Log in to [hpanel.hostinger.com](https://hpanel.hostinger.com)
2. Open **File Manager** for `app.bitzlatoview.com`
3. Navigate to `public_html` (or `public/` if Laravel is configured)
4. Create folder `.well-known`
5. Upload `assetlinks.json`, `apple-app-site-association`, and `.htaccess`

### Via FTP/SFTP

```bash
sftp your-user@your-hostinger-host
cd public_html/.well-known
put config/deep-linking/assetlinks.json
put config/deep-linking/apple-app-site-association
put config/deep-linking/.htaccess
```

### Laravel route fallback (if static files are blocked)

Add to `routes/web.php` **before** catch-all routes:

```php
Route::get('/.well-known/assetlinks.json', function () {
    return response()->file(public_path('.well-known/assetlinks.json'), [
        'Content-Type' => 'application/json',
    ]);
});

Route::get('/.well-known/apple-app-site-association', function () {
    return response()->file(public_path('.well-known/apple-app-site-association'), [
        'Content-Type' => 'application/json',
    ]);
});
```

Then run `php artisan route:clear`.

## 4. Verify deployment

```bash
curl -sI https://app.bitzlatoview.com/.well-known/assetlinks.json | head -5
curl -sI https://app.bitzlatoview.com/.well-known/apple-app-site-association | head -5
curl -s https://app.bitzlatoview.com/.well-known/assetlinks.json | jq .
```

Expected: **HTTP 200**, `Content-Type: application/json`, valid JSON body.

## 5. Validate with platform tools

- **Android:** [Statement List Generator and Tester](https://developers.google.com/digital-asset-links/tools/generator)
- **iOS:** [Apple App Search Validation Tool](https://search.developer.apple.com/appsearch-validation-tool)
