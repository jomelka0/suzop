/// Локализация suzop: пары строк «русский / английский».
/// Глобальный переключатель lang синхронизируется из AppState.
class L {
  static String lang = 'ru';
  static bool get isRu => lang == 'ru';

  /// Русская строка, если выбран русский, иначе английская.
  static String t(String ru, String en) => isRu ? ru : en;
}

/// Тексты-подсказки для плашек ошибок: что случилось и как починить,
/// чтобы ошибка больше не появлялась.
class Help {
  static String get key => L.t(
      'Скопируй ключ целиком — он начинается с vless://, vmess://, '
      'trojan:// или ss://. Проверь, что при копировании не потерялись '
      'символы в начале или конце.',
      'Copy the whole key — it starts with vless://, vmess://, '
      'trojan:// or ss://. Make sure no characters were lost at the '
      'start or the end when copying.');

  static String get noServers => L.t(
      'Подписка загрузилась, но в ней нет форматов, которые suzop умеет '
      'читать (vless, vmess, trojan, ss). Иногда панель отдаёт конфиги '
      'только «знакомым» клиентам — попробуй импортировать ещё раз.',
      'The subscription loaded, but it has no formats suzop can read '
      '(vless, vmess, trojan, ss). Some panels serve configs only to '
      '"known" clients — try importing again.');

  static String get net => L.t(
      'Проверь интернет: открой любой сайт. Если сеть в порядке — '
      'возможно, панель подписки временно недоступна или ссылка устарела.',
      'Check your internet: open any website. If the network is fine, '
      'the subscription panel may be temporarily down or the link expired.');

  static String get reject => L.t(
      'Панель подписки не узнала suzop как поддерживаемый клиент. '
      'Приложение уже представляется известным клиентом, но панель отказала. '
      'Проверь, что ссылка подписки скопирована полностью и подписка активна '
      '(не истёк срок, не кончился трафик).',
      'The subscription panel did not recognize suzop as a supported '
      'client. The app already identifies itself as a known client, but '
      'the panel refused. Check that the subscription link is copied in '
      'full and the subscription is active (not expired, traffic left).');

  static String get clipboardEmpty => L.t(
      'Сначала скопируй ключ или ссылку: зажми текст в любом приложении → '
      '«Копировать». Потом вернись сюда и нажми «Из буфера».',
      'First copy the key or link: long-press the text in any app → '
      '"Copy". Then come back and tap "From clipboard".');

  static String get bestNone => L.t(
      'Ни один сервер не ответил на проверку. Проверь интернет-соединение; '
      'если оно работает — серверы подписки, скорее всего, недоступны. '
      'Попробуй позже.',
      'No server responded to the check. Check your internet connection; '
      'if it works, the subscription servers are probably down. '
      'Try again later.');
}
