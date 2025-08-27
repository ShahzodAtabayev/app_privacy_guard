# App Privacy Guard

A Flutter plugin to protect sensitive information when your app goes into the background or is displayed in the iOS App Switcher.

This plugin provides:

- **Blur Mode (iOS & Android)** – Adds a system blur layer over your app window when it is backgrounded.
- **Secure Mode (Android only)** – Prevents screenshots and screen recording.
- **Dynamic Island Watermark (iOS only)** – Displays a small watermark logo centered below the Dynamic Island, always above blur overlays.

---

## Features

- 🚫 Hide sensitive data in the app switcher with a blur overlay.
- 🔒 Prevent screenshots & screen recordings on Android.
- 🌊 Always-visible watermark on iOS (e.g., your app logo below Dynamic Island).
- ⚡ Simple Dart API with manual and automatic lifecycle integration.

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  app_privacy_guard:
    git:
      url: https://github.com/your-org/app_privacy_guard.git
```

Run:

```bash
flutter pub get
```

---

## Usage

### Import

```dart
import 'package:app_privacy_guard/app_privacy_guard.dart';
```

### Manual Blur/Secure Control

```dart
// Enable blur overlay
await AppPrivacyGuard.instance.enableBlur();

// Disable blur overlay
await AppPrivacyGuard.instance.disableBlur();

// Enable secure mode (Android only)
await AppPrivacyGuard.instance.enableSecure();

// Disable secure mode
await AppPrivacyGuard.instance.disableSecure();
```

### Auto Mode (Lifecycle-aware)

```dart
@override
void initState() {
  super.initState();
  // Automatically enable blur when app goes to background
  AppPrivacyGuard.instance.startAuto(mode: PrivacyMode.blur);
}

@override
void dispose() {
  AppPrivacyGuard.instance.stopAuto();
  super.dispose();
}
```

### Dynamic Island Watermark (iOS only)

```dart
// Show watermark
await AppPrivacyGuard.instance.showWatermark(
  assetName: 'watermark_icon', // iOS Assets.xcassets
  size: 22,
  offsetY: 6,
  alpha: 0.9,
);

// Update watermark position or size
await AppPrivacyGuard.instance.updateWatermark(size: 20, offsetY: 8, alpha: 0.85);

// Hide watermark
await AppPrivacyGuard.instance.hideWatermark();
```

> **Tip:** Add your watermark icon to `ios/Runner/Assets.xcassets`.

---

## iOS Notes

- Blur is implemented using `UIVisualEffectView`.
- Watermark is shown in a separate `UIWindow` with high `windowLevel`, so it stays visible above blur overlays.
- Secure mode calls are **no-op** on iOS (screenshots cannot be blocked globally).

---

## Android Notes

- Blur is implemented using a simple overlay view.
- Secure mode sets `FLAG_SECURE` on the activity window.

---

## Example

See the `/example` folder for a complete usage sample.

---

## License

MIT © SHAHZOD ATABAEV
