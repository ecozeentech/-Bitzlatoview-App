# Bitzlatoview JavaScript Bridge

The mobile WebView injects a bootstrap script and exposes `window.BitzlatoviewBridge`.

## Call native features

```javascript
window.BitzlatoviewBridge.postMessage(JSON.stringify({
  action: 'biometricAuthenticate',
  params: { reason: 'Confirm withdrawal' },
  requestId: crypto.randomUUID()
}));
```

Or via the helper injected by the app:

```javascript
window.BitzlatoviewNative.call('getDeviceInfo', {}, 'req-1');
```

## Receive results

```javascript
window.onBitzlatoviewBridgeResult = (payload) => {
  if (!payload.success) {
    console.warn(payload.error);
    return;
  }
  console.log(payload.data);
};
```

## Actions

| Action | Params | Notes |
|--------|--------|-------|
| `pickFile` | `{ accept?: string }` | Native file picker |
| `takePhoto` | `{}` | Camera capture for KYC |
| `getLocation` | `{}` | Lat/lng when permitted |
| `shareContent` | `{ text: string }` | System share sheet |
| `copyToClipboard` | `{ text: string }` | Clipboard |
| `requestNotificationPermission` | `{}` | Push permission |
| `getDeviceInfo` | `{}` | Model / OS / app version |
| `biometricAuthenticate` | `{ reason?: string }` | Face ID / fingerprint |
| `openSettings` | `{}` | Signals native settings |

## Push notifications

```javascript
window.handlePushNotification = (data) => {
  // Navigate based on data.url / data.link
};
```
