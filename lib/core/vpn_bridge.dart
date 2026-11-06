import 'package:flutter/services.dart';
import 'models.dart';

/// Мост Flutter -> нативный VPN-движок (Android: Kotlin + libcore/xray/sing-box).
/// Пока нативная часть не подключена, connect() возвращает false —
/// UI корректно это показывает и остаётся рабочим.
class VpnBridge {
  static const MethodChannel _m = MethodChannel('suzop/vpn');
  static const EventChannel _e = EventChannel('suzop/stats');

  /// true — туннель поднят нативной стороной.
  static Future<bool> connect(VpnServer s) async {
    try {
      return await _m.invokeMethod('connect', s.toEngine()) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<void> disconnect() async {
    try {
      await _m.invokeMethod('disconnect');
    } catch (_) {}
  }

  /// Поток статистики от ядра: { 'speedMbps': double, 'totalMb': double }
  static Stream<Map<String, dynamic>> stats() => _e
      .receiveBroadcastStream()
      .map((d) => Map<String, dynamic>.from(d as Map));
}
