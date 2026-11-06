import 'dart:io';
import 'models.dart';

/// Реальный TCP-ping: приложение само открывает TCP-соединение к host:port
/// каждого сервера и измеряет время установления (аналог того, как делают
/// Happ / Shadowrocket — «TCP handshake ping»).
Future<int?> tcpPing(String host, int port,
    {Duration timeout = const Duration(seconds: 3)}) async {
  final sw = Stopwatch()..start();
  Socket? s;
  try {
    s = await Socket.connect(host, port, timeout: timeout);
    sw.stop();
    return sw.elapsed.inMilliseconds;
  } catch (_) {
    return null;
  } finally {
    await s?.close();
  }
}

/// Пингует все серверы параллельно, результат отдаёт по мере готовности.
Future<void> pingAllServers(
  List<VpnServer> list, {
  void Function(VpnServer s, int? ms)? onResult,
}) async {
  await Future.wait(list.map((s) async {
    final ms = await tcpPing(s.host, s.port);
    s.pingMs = ms;
    onResult?.call(s, ms);
  }));
}
