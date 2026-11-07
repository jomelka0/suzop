import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/models.dart';
import 'core/parsers.dart';
import 'core/ping.dart';
import 'core/vpn_bridge.dart';
import 'core/subscription_fetch.dart';
import 'i18n.dart';
import 'theme.dart';

/// Единое состояние приложения: серверы, подписки, пинг, подключение,
/// тема, язык, автообновление, трафик подписки и плашка ошибки.
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
  bool dark = false;       // тёмная тема
  String language = 'ru';  // 'ru' | 'en'

  /// Автообновление подписки в минутах. 0 = выключено.
  int autoRefreshMinutes = 60;
  DateTime? lastAutoRefresh;

  /// Реальный трафик из заголовка подписки (subscription-userinfo).
  int trafficUsedBytes = 0;
  int? trafficLimitBytes;

  /// Плашка ошибки: текст + подсказка «почему и как починить».
  String? errorText;
  String? errorHelp;

  Timer? _timer;
  Timer? _autoTimer;
  StreamSubscription? _stats;
  bool _pinging = false;
  bool _autoRefreshing = false;

  void addServers(List<VpnServer> s) {
    servers.addAll(s);
    _save();
    notifyListeners();
  }

  void addSub(String url, [int? count]) {
    if (!subUrls.contains(url)) subUrls.add(url);
    _save();
    _restartAutoTimer();
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

  /// Записывает реальный трафик, отданный панелью подписки.
  void setTrafficInfo(SubscriptionInfo info) {
    trafficUsedBytes = info.uploadBytes + info.downloadBytes;
    trafficLimitBytes = info.totalBytes;
    notifyListeners();
  }

  /// Показывает красивую плашку ошибки внизу экрана.
  void showError(String text, [String? help]) {
    errorText = text;
    errorHelp = help;
    notifyListeners();
  }

  /// Закрывает плашку ошибки (крестик).
  void clearError() {
    errorText = null;
    errorHelp = null;
    notifyListeners();
  }

  /// Быстрый параллельный пинг всех серверов.
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

  /// Включение/выключение тёмной темы (сохраняется).
  Future<void> setDark(bool value) async {
    dark = value;
    SuzopTheme.dark = value;
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark_theme', value);
    notifyListeners();
  }

  /// Смена языка интерфейса: 'ru' или 'en' (сохраняется).
  Future<void> setLanguage(String value) async {
    if (value != 'ru' && value != 'en') return;
    language = value;
    L.lang = value;
    final p = await SharedPreferences.getInstance();
    await p.setString('language', value);
    notifyListeners();
  }

  /// Выбор интервала автообновления подписки (сохраняется и применяется).
  Future<void> setAutoRefreshMinutes(int minutes) async {
    autoRefreshMinutes = minutes;
    final p = await SharedPreferences.getInstance();
    await p.setInt('auto_refresh_min', minutes);
    _restartAutoTimer();
    notifyListeners();
  }

  /// Перезапускает таймер автообновления по текущему интервалу.
  /// Работает, пока приложение открыто; фоновое обновление «всегда»
  /// появится вместе с foreground-сервисом VPN-ядра.
  void _restartAutoTimer() {
    _autoTimer?.cancel();
    if (autoRefreshMinutes <= 0 || subUrls.isEmpty) return;
    _autoTimer = Timer.periodic(Duration(minutes: autoRefreshMinutes),
        (_) => autoRefreshSubscriptions());
  }

  /// Тихо обновляет все подписки (для автообновления и запуска).
  Future<void> autoRefreshSubscriptions() async {
    if (_autoRefreshing || subUrls.isEmpty) return;
    _autoRefreshing = true;
    try {
      for (final u in List<String>.of(subUrls)) {
        try {
          final info = await fetchSubscription(u);
          if (info.servers.isNotEmpty) replaceServers(info.servers);
          setTrafficInfo(info);
        } catch (_) {
          // Сеть недоступна — попробуем в следующий раз.
        }
      }
      lastAutoRefresh = DateTime.now();
      notifyListeners();
    } finally {
      _autoRefreshing = false;
    }
  }

  /// Подключение через нативное ядро. Пока ядро не интегрировано —
  /// честно возвращает false, UI это корректно показывает.
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

  /// Загружает сохранённые подписки, тему, язык и интервал.
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final urls = (p.getStringList('sub_urls') ?? []);
    final links = (p.getStringList('server_links') ?? []);
    subUrls.addAll(urls);
    servers.addAll(links.map(parseLink).whereType<VpnServer>());
    dark = p.getBool('dark_theme') ?? false;
    language = p.getString('language') ?? 'ru';
    autoRefreshMinutes = p.getInt('auto_refresh_min') ?? 60;
    SuzopTheme.dark = dark;
    L.lang = language;
    _restartAutoTimer();
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('sub_urls', subUrls);
    await p.setStringList(
        'server_links', servers.map((s) => s.link).toList());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoTimer?.cancel();
    _stats?.cancel();
    super.dispose();
  }

  String? get lastRefreshLabel {
    final t = lastAutoRefresh;
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  String get timeLabel {
    final h = (secs ~/ 3600).toString().padLeft(2, '0');
    final m = ((secs ~/ 60) % 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
