/// Модель VPN-сервера (профиль из ключа/подписки).
class VpnServer {
  final String name;     // отображаемое имя (обычно содержит флаг страны)
  final String protocol; // VLESS / VMess / Trojan / Shadowsocks / WireGuard
  final String host;
  final int port;
  final String link;     // оригинальная ссылка — её получает нативное ядро
  final String flag;
  int? pingMs;           // реальный TCP-ping из приложения

  VpnServer({
    required this.name,
    required this.protocol,
    required this.host,
    required this.port,
    required this.link,
    this.flag = '🌐',
  });

  /// Конфиг, передаваемый нативному VPN-ядру через MethodChannel.
  Map<String, dynamic> toEngine() => {
    'name': name,
    'protocol': protocol,
    'host': host,
    'port': port,
    'link': link,
  };

  String get pingLabel =>
      pingMs == null ? '— мс' : (pingMs! > 999 ? '999+' : '$pingMs') + ' мс';

  Color get pingColor => pingMs == null
      ? const Color(0xFF9DB4CC)
      : pingMs! < 80
          ? const Color(0xFF1FBF6B)
          : pingMs! < 200
              ? const Color(0xFFE8A23C)
              : const Color(0xFFE2574C);
}
