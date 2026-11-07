import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';
import 'parsers.dart';

/// Панель подписки отклонила запрос («ваш VPN-клиент не поддерживается»).
/// Отдельный класс, чтобы UI показал внятное пояснение, а не «нет серверов».
class SubscriptionRejectedException implements Exception {
  final String ru;
  final String en;
  SubscriptionRejectedException(this.ru, this.en);
}

/// Результат загрузки подписки: серверы + реальный трафик из заголовка
/// subscription-userinfo (его отдают Marzban, 3x-ui, Remnawave и др.).
class SubscriptionInfo {
  final List<VpnServer> servers;
  final int uploadBytes;
  final int downloadBytes;
  final int? totalBytes;
  const SubscriptionInfo({
    required this.servers,
    this.uploadBytes = 0,
    this.downloadBytes = 0,
    this.totalBytes,
  });
}

/// Представляемся известным панели клиентом: иначе многие панели вместо
/// списка серверов отдают страницу «ваш клиент не поддерживается».
const _userAgent = 'Suzop/0.1 v2rayNG/1.8.23';

/// Загружает подписку по URL и парсит её в список серверов + трафик.
Future<SubscriptionInfo> fetchSubscription(String url) async {
  final r = await http.get(Uri.parse(url), headers: {'User-Agent': _userAgent});
  if (r.statusCode != 200) {
    throw Exception('HTTP ${r.statusCode}');
  }
  final body = r.body;
  if (_looksLikeRejection(body)) {
    throw SubscriptionRejectedException(
      'Панель подписки отклонила запрос: она не отдала список серверов для suzop.',
      'The subscription panel rejected the request: it did not return a server list for suzop.',
    );
  }
  final list = parseSubscriptionText(body);
  final (up, down, total) = _parseUserinfo(r.headers['subscription-userinfo']);
  return SubscriptionInfo(
      servers: list, uploadBytes: up, downloadBytes: down, totalBytes: total);
}

/// Похоже ли тело ответа на страницу-заглушку «клиент не поддерживается».
bool _looksLikeRejection(String body) {
  // Есть настоящие ссылки — это не заглушка.
  if (RegExp(r'(vless|vmess|trojan|ss|https?)://').hasMatch(body)) {
    return false;
  }
  final b = body.toLowerCase();
  const markers = [
    'not supported',
    'unsupported',
    'does not support',
    "doesn't support",
    '不支持',
    'поддерживается',
    'клиент не',
  ];
  return markers.any(b.contains);
}

/// Парсит заголовок subscription-userinfo: upload=..; download=..; total=..
(int, int, int?) _parseUserinfo(String? header) {
  if (header == null || header.isEmpty) return (0, 0, null);
  int up = 0, down = 0;
  int? total;
  for (final part in header.split(';')) {
    final kv = part.trim().split('=');
    if (kv.length != 2) continue;
    final v = int.tryParse(kv[1].trim());
    if (v == null) continue;
    final k = kv[0].trim().toLowerCase();
    if (k == 'upload') {
      up = v;
    } else if (k == 'download') {
      down = v;
    } else if (k == 'total') {
      total = v;
    }
  }
  return (up, down, total);
}

/// Кодирует список ссылок в base64 (формат подписки на экспорт).
String encodeSubscription(List<String> links) =>
    base64.encode(utf8.encode(links.join('\n')));
