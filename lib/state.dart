import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/models.dart';
import 'core/parsers.dart';
import 'core/ping.dart';
import 'core/vpn_bridge.dart';
import 'core/subscription_fetch.dart';

/// Единое состояние приложения: серверы, подписки, пинг, подключение.
class AppState extends ChangeNotifier {
  final List<VpnServer> servers = [];
  final List<String> subUrls = [];
  int selected = 0;
  int state = 0; // 0 нет, 1 подключение, 2 защищено
  int secs = 0;
  double speedMbps = 0;
  double totalMb = 0;
  String? activeName;
  int page = 0;
  bool heroHidden = false;
  bool isPinging = false;
  Timer? _timer;
  StreamSubscription? _stats;
  bool _pinging = false;

  void addServers(List<VpnServer> s) {
    servers.addAll(s);
    _save();
    notifyListeners();
  }

  void addSub(String url, [int? count]) {
    subUrls.add(url);
    _save();
    notifyListeners();
  }

  void replaceServers(List<VpnServer> s) {
    servers
      ..clear()
      ..addAll(s);
    if (selected >= servers.length) selected = 0;
    _save();
    notifyListeners();
  }

  void select(VpnServer s) {
    selected = servers.indexOf(s);
    notifyListeners();
  }

  /// Быстрый параллельный пинг всех серверов (кнопка в разделе «Серверы»).
  /// Недоступные получают «н/д», UI раскрашивает пинги по цветам.
  Future<void> refreshPing() async {
    if (_pinging || servers.isEmpty) return;
    _pinging = true;
    isPinging = true;
    notifyListeners();
    try {
      await pingAllServers(servers, onResult: (_, __) => notifyListeners());
    } finally {
      _pinging = false;
      isPinging = false;
      notifyListeners();
    }
  }

  /// Мгновенный подбор лучшего сервера по пингу.
  /// Пингует все серверы параллельно и выбирает сервер с минимальным пингом.
  /// Возвращает лучший сервер или null, если ни один не ответил.
  Future<VpnServer?> findBestServer() async {
    if (servers.isEmpty) return null;
    await refreshPing();
    VpnServer? best;
    for (final s in servers) {
      if (s.pingMs != null && (best == null || s.pingMs! < best.pingMs!)) {
        best = s;
      }
    }
    if (best != null) {
      selected = servers.indexOf(best);
      notifyListeners();
    }
    return best;
  }

  void setHeroHidden(bool v) {
    heroHidden = v;
    notifyListeners();
  }

  void goToPage(int p) {
    page = p.clamp(0, 2);
    notifyListeners();
  }

  /// Подключение через нативное ядро. Если ядро ещё не подключено,
  /// честно возвращает false — UI корректно это показывает.
  Future<bool> tryConnect() async {
    if (servers.isEmpty) return false;
    state = 1;
    notifyListeners();
    final ok = await VpnBridge.connect(servers[selected]);
    if (!ok) {
      state = 0;
      notifyListeners();
      return false;
    }
    state = 2;
    activeName = servers[selected].name;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      secs++;
      notifyListeners();
    });
    _stats = VpnBridge.stats().listen((data) {
      speedMbps = (data['speedMbps'] as num?)?.toDouble() ?? 0;
      totalMb = (data['totalMb'] as num?)?.toDouble() ?? 0;
      notifyListeners();
    });
    return true;
  }

  Future<void> disconnect() async {
    await VpnBridge.disconnect();
    state = 0;
    secs = 0;
    speedMbps = 0;
    totalMb = 0;
    activeName = null;
    _timer?.cancel();
    _stats?.cancel();
    notifyListeners();
  }

  /// Загружает сохранённые подписки и парсит их (при наличии сети).
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final urls = (p.getStringList('sub_urls') ?? []);
    final links = (p.getStringList('server_links') ?? []);
    subUrls.addAll(urls);
    servers.addAll(links.map(parseLink).whereType<VpnServer>());
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('sub_urls', subUrls);
    await p.setStringList(
        'server_links', servers.map((s) => s.link).toList());
  }

  String get timeLabel {
    final h = (secs ~/ 3600).toString().padLeft(2, '0');
    final m = ((secs ~/ 60) % 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
