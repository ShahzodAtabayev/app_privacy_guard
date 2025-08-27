import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

enum PrivacyMode { blur, secure }

class AppPrivacyGuard with WidgetsBindingObserver {
  AppPrivacyGuard._();

  static final AppPrivacyGuard instance = AppPrivacyGuard._();

  static const _channel = MethodChannel('app_privacy_guard');

  /// --- Manual controls (blur/secure) ---
  Future<void> enableBlur() => _channel.invokeMethod('enableBlur');

  Future<void> disableBlur() => _channel.invokeMethod('disableBlur');

  /// Android only (iOS no-op)
  Future<void> enableSecure() => _channel.invokeMethod('enableSecure');

  Future<void> disableSecure() => _channel.invokeMethod('disableSecure');

  /// --- Watermark controls (iOS) ---
  Future<void> showWatermark({
    String? assetName,
    String? base64Png,
    double size = 22,
    double offsetY = 6,
    double alpha = 0.9,
  }) async {
    await _channel.invokeMethod('showWatermark', {
      'assetName': assetName,
      'base64': base64Png,
      'size': size,
      'offsetY': offsetY,
      'alpha': alpha,
    });
  }

  Future<void> hideWatermark() => _channel.invokeMethod('hideWatermark');

  Future<void> updateWatermark({double? size, double? offsetY, double? alpha}) async {
    await _channel.invokeMethod('updateWatermark', {
      if (size != null) 'size': size,
      if (offsetY != null) 'offsetY': offsetY,
      if (alpha != null) 'alpha': alpha,
    });
  }

  /// Kichik helper: assetdan PNG’ni base64 ga o‘girib yuborish (agar iOS asset ishlatmasangiz)
  static Future<String> loadAssetPngAsBase64(String assetPath, AssetBundle? bundle) async {
    final b = bundle ?? rootBundle;
    final bytes = await b.load(assetPath);
    return base64Encode(bytes.buffer.asUint8List());
  }

  /// --- Auto mode (With dart lifecycle) ---
  bool _auto = false;
  PrivacyMode _mode = PrivacyMode.blur;

  void startAuto({PrivacyMode mode = PrivacyMode.blur}) {
    if (_auto) return;
    _auto = true;
    _mode = mode;
    WidgetsBinding.instance.addObserver(this);
  }

  void stopAuto() {
    if (!_auto) return;
    _auto = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_auto) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        if (_mode == PrivacyMode.blur) {
          enableBlur();
        } else {
          enableSecure();
        }
        break;
      case AppLifecycleState.resumed:
        if (_mode == PrivacyMode.blur) {
          disableBlur();
        } else {
          disableSecure();
        }
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }
}
