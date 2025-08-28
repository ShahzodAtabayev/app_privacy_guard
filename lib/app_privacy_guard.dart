import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
    if (Platform.isAndroid) {
      return;
    }
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

  bool _suspended = false;
  Timer? _pendingTimer;

  /// Biometric/pay dialogs vaqtida auto-blurni vaqtincha o'chirish.
  void suspendAuto() {
    _suspended = true;
    _pendingTimer?.cancel();
    _pendingTimer = null;
  }

  void resumeAuto() {
    _suspended = false;
  }

  /// Qulay wrapper: biror ishni blur'siz bajarish
  Future<T> executeWithoutBlur<T>(Future<T> Function() action) async {
    final wasSuspended = _suspended;
    suspendAuto();
    try {
      return await action();
    } finally {
      if (!wasSuspended) resumeAuto();
    }
  }

  int autoDelayMs = 350;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_auto) return;
    void apply(bool enable) {
      if (_mode == PrivacyMode.blur) {
        enable ? enableBlur() : disableBlur();
      } else {
        enable ? enableSecure() : disableSecure();
      }
    }

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        if (_suspended) return;
        _pendingTimer?.cancel();
        _pendingTimer = Timer(Duration(milliseconds: autoDelayMs), () {
          if (!_suspended) apply(true);
        });
        break;

      case AppLifecycleState.resumed:
        _pendingTimer?.cancel();
        _pendingTimer = null;
        apply(false);
        break;

      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }
}
