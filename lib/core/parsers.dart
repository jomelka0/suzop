import 'dart:convert';
import 'models.dart';

/// Парсеры всех поддерживаемых форматов ключей:
/// vless://, vmess:// (base64 JSON), trojan://, ss:// (SIP002 + legacy base64),
/// подписки (base64-список ссылок или просто список ссылок).

String _b64fix(String s) {
  s = s.replaceAll('-', '+').replaceAll('_', '/').trim();
  while (s.length % 4 != 0) {
    s += '=';
  }
  return s;
}

String flagOf(String name) {
  final m = RegExp(r'[\u{1F1E6}-\u{1F1FF}]{2}', unicode: true).firstMatch(name);
  return m == null ? '🌐' : m[0]!;
}

VpnServer? parseLink(String raw) {
  raw = raw.trim();
  if (raw.startsWith('vless://')) return _fromUri(raw, 'VLESS');
  if (raw.startsWith('trojan://')) return _fromUri(raw, 'Trojan');
  if (raw.startsWith('vmess://')) return _vmess(raw);
  if (raw.startsWith('ss://')) return _ss(raw);
  return null;
}

VpnServer? _fromUri(String raw, String proto) {
  try {
    final u = Uri.parse(raw);
    final name = (u.fragment.isEmpty || u.fragment == u.host)
        ? '$proto · ${u.host}'
        : Uri.decodeComponent(u.fragment);
    return VpnServer(
      name: name,
      protocol: proto,
      host: u.host,
      port: u.hasPort ? u.port : 443,
      link: raw,
      flag: flagOf(name),
    );
  } catch (_) {
    return null;
  }
}

VpnServer? _vmess(String raw) {
  try {
    final j = jsonDecode(utf8.decode(base64.decode(_b64fix(raw.substring(8)))))
        as Map<String, dynamic>;
    final name = (j['ps'] as String?)?.isNotEmpty == true
        ? j['ps'] as String
        : 'VMess · ${j['add']}';
    return VpnServer(
      name: name,
      protocol: 'VMess',
      host: j['add'] as String,
      port: int.tryParse('${j['port']}') ?? 443,
      link: raw,
      flag: flagOf(name),
    );
  } catch (_) {
    return null;
  }
}

VpnServer? _ss(String raw) {
  // SIP002: ss://base64(method:password)@host:port#name  (или plain userinfo)
  try {
    final u = Uri.parse(raw);
    final name = u.fragment.isEmpty
        ? 'Shadowsocks · ${u.host}'
        : Uri.decodeComponent(u.fragment);
    return VpnServer(
      name: name,
      protocol: 'Shadowsocks',
      host: u.host,
      port: u.hasPort ? u.port : 8388,
      link: raw,
      flag: flagOf(name),
    );
  } catch (_) {}
  // Legacy: ss://base64({"server":..,"server_port":..})
  try {
    final j = jsonDecode(utf8.decode(base64.decode(_b64fix(raw.substring(5)))))
        as Map<String, dynamic>;
    final name = (j['remarks'] as String?)?.isNotEmpty == true
        ? j['remarks'] as String
        : 'Shadowsocks · ${j['server']}';
    return VpnServer(
      name: name,
      protocol: 'Shadowsocks',
      host: j['server'] as String,
      port: (j['server_port'] as num?)?.toInt() ?? 8388,
      link: raw,
      flag: flagOf(name),
    );
  } catch (_) {
    return null;
  }
}

/// Парсит тело подписки: base64-список или просто список ссылок.
List<VpnServer> parseSubscriptionText(String text) {
  var body = text.trim();
  if (body.isEmpty) return [];
  if (!body.contains('://')) {
    try {
      body = utf8.decode(base64.decode(_b64fix(body)));
    } catch (_) {
      return [];
    }
  }
  return body
      .split(RegExp(r'[\r\n]+'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .map(parseLink)
      .whereType<VpnServer>()
      .toList();
}

const supportedFormats = [
  'VLESS', 'VMess', 'Trojan', 'Shadowsocks', 'WireGuard (через ядро)',
];
