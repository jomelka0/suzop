import 'dart:io';

import 'models.dart';

/// Быстрый ПАРАЛЛЕЛЬНЫЙ TCP-ping всех серверов.
/// Недоступные получают pingMs = null → в UI показывается «н/д».
Future<void> pingAllServers(
  List<VpnServer> servers, {
  void Function(VpnServer server, int? ms)? onResult,
  Duration timeout = const Duration(seconds: 2),
  int concurrency = 24,
}) async {
  final queue = List<VpnServer>.from(servers);
  int taken = 0;

  VpnServer? take() {
    if (taken >= queue.length) return null;
    return queue[taken++];
  }

  Future<void> worker() async {
    while (true) {
      final s = take();
      if (s == null) return;
      final ms = await tcpPing(s.host, s.port, timeout: timeout);
      s.pingMs = ms;
      onResult?.call(s, ms);
    }
  }

  final n = concurrency.clamp(1, servers.isEmpty ? 1 : servers.length);
  await Future.wait([for (var i = 0; i < n; i++) worker()]);
}

/// Замер времени TCP-подключения к серверу (мс).
/// null = сервер не ответил за timeout → «н/д».
Future<int?> tcpPing(String host, int port,
    {Duration timeout = const Duration(seconds: 2)}) async {
  final sw = Stopwatch()..start();
  try {
    final socket = await Socket.connect(host, port, timeout: timeout);
    socket.destroy();
    return sw.elapsedMilliseconds;
  } catch (_) {
    return null;
  }
}
