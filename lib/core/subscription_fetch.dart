import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';
import 'parsers.dart';

/// Загружает подписку по URL и парсит её в список серверов.
Future<List<VpnServer>> fetchSubscription(String url) async {
  final r = await http.get(Uri.parse(url));
  if (r.statusCode != 200) {
    throw Exception('HTTP ${r.statusCode}');
  }
  return parseSubscriptionText(r.body);
}

/// Обновляет все подписки; результат отдаётся по мере готовности.
Future<void> refetchSubscriptions(
  List<String> urls, {
  void Function(List<VpnServer> list)? onServers,
  void Function(String url, String error)? onError,
}) async {
  for (final u in urls) {
    try {
      final list = await fetchSubscription(u);
      onServers?.call(list);
    } catch (e) {
      onError?.call(u, e.toString());
    }
  }
}

/// Кодирует список ссылок в base64 (формат подписки на экспорт).
String encodeSubscription(List<String> links) =>
    base64.encode(utf8.encode(links.join('\n')));
