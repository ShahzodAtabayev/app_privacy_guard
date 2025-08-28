import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum PrivacyMode { blur, secure }

class AppPrivacyGuard with WidgetsBindingObserver {
  AppPrivacyGuard._();

  static final AppPrivacyGuard instance = AppPrivacyGuard._();

  static const _channel = MethodChannel('app_privacy_guard');

  // ---- Manual controls ----
  Future<void> enableBlur() => _channel.invokeMethod('enableBlur');

  Future<void> disableBlur() => _channel.invokeMethod('disableBlur');

  Future<void> enableSecure() => _channel.invokeMethod('enableSecure');

  Future<void> disableSecure() => _channel.invokeMethod('disableSecure');

  // ---- Watermark (iOS only) ----
  Future<void> showWatermark({
    String? assetName,
    String? base64Png,
    double size = 22,
    double offsetY = 6,
    double alpha = 0.9,
  }) async {
    if (!Platform.isIOS) return;
    await _channel.invokeMethod('showWatermark', {
      'assetName': assetName,
      'base64': base64Png,
      'size': size,
      'offsetY': offsetY,
      'alpha': alpha,
    });
  }

  Future<void> hideWatermark() async {
    if (!Platform.isIOS) return;
    await _channel.invokeMethod('hideWatermark');
  }

  Future<void> updateWatermark({double? size, double? offsetY, double? alpha}) async {
    if (!Platform.isIOS) return;
    await _channel.invokeMethod('updateWatermark', {
      if (size != null) 'size': size,
      if (offsetY != null) 'offsetY': offsetY,
      if (alpha != null) 'alpha': alpha,
    });
  }

  static Future<String> loadAssetPngAsBase64(String assetPath, [AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final bytes = await b.load(assetPath);
    return base64Encode(bytes.buffer.asUint8List());
  }

  // ---- Auto mode ----
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
    _inactiveTimer?.cancel();
    _inactiveTimer = null;
  }

  // System dialoglar vaqtida vaqtincha o‘chirib turish flag’i
  bool _suspended = false;

  void suspendAuto() {
    _suspended = true;
    _inactiveTimer?.cancel();
    _inactiveTimer = null;
  }

  void resumeAuto() {
    _suspended = false;
  }

  Future<T> executeWithoutBlur<T>(Future<T> Function() action) async {
    final was = _suspended;
    suspendAuto();
    try {
      return await action();
    } finally {
      if (!was) resumeAuto();
    }
  }

  Timer? _inactiveTimer;
  int inactiveDelayMs = 600;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_auto || _suspended) return;

    void apply(bool enable) {
      if (_mode == PrivacyMode.blur) {
        enable ? enableBlur() : disableBlur();
      } else {
        enable ? enableSecure() : disableSecure();
      }
    }

    switch (state) {
      case AppLifecycleState.inactive:
        // Hech narsa qilmaymiz; faqat kechiktirilgan tekshiruv.
        _inactiveTimer?.cancel();
        _inactiveTimer = Timer(Duration(milliseconds: inactiveDelayMs), () {
          // Agar shu vaqt ichida `paused` kelmagan bo‘lsa — bu system dialog bo‘lgan,
          // blur yoqmaymiz. `paused` case'da baribir timer cancel bo‘ladi.
        });
        break;

      case AppLifecycleState.paused:
        // Haqiqiy background: blur/secure yoqiladi
        _inactiveTimer?.cancel();
        _inactiveTimer = null;
        apply(true);
        break;

      case AppLifecycleState.resumed:
        // Foreground: blur/secure o‘chadi
        _inactiveTimer?.cancel();
        _inactiveTimer = null;
        apply(false);
        break;

      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // ignore
        break;
    }
  }
}
