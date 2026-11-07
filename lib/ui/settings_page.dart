import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n.dart';
import '../state.dart';
import '../theme.dart';

/// Настройки: строки без эмодзи, подсказки по ⓘ и долгому нажатию,
/// тёмная тема, язык, интервал автообновления подписки,
/// честные статусы функций VPN.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _intervals = [0, 15, 30, 60, 180, 720]; // 0 = выкл

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final ru = app.language == 'ru';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _section(ru ? 'Внешний вид' : 'Appearance'),
        GlassCard(
          child: Column(children: [
            _settingRow(
              context,
              title: ru ? 'Тёмная тема' : 'Dark theme',
              subtitle: app.dark
                  ? (ru ? 'Включена' : 'On')
                  : (ru ? 'Выключена' : 'Off'),
              explanation: ru
                  ? 'Переключает приложение между светлым небесным оформлением и тёмной темой. Выбор сохраняется на устройстве.'
                  : 'Switches between the light sky appearance and dark theme. Your choice is saved on this device.',
              trailing: Switch.adaptive(value: app.dark, onChanged: app.setDark),
              onTap: () => app.setDark(!app.dark),
            ),
            _divider(),
            _settingRow(
              context,
              title: ru ? 'Язык' : 'Language',
              subtitle: ru ? 'Русский' : 'English',
              explanation: ru
                  ? 'Выбери язык интерфейса. Сейчас переводятся настройки, навигация, подписка и сообщения об ошибках.'
                  : 'Choose the interface language. Settings, navigation, subscription and error messages are translated.',
              onTap: () =>
                  _chooseLanguage(context, app.language, app.setLanguage),
            ),
          ]),
        ),
        _section(ru ? 'Подписка' : 'Subscription'),
        GlassCard(
          child: Column(children: [
            _settingRow(
              context,
              title: ru ? 'Автообновление подписки' : 'Subscription auto-refresh',
              subtitle: _intervalLabel(app.autoRefreshMinutes, ru),
              explanation: ru
                  ? 'Как часто приложение автоматически скачивает свежий список серверов по ссылкам ваших подписок. Обновление происходит, пока приложение открыто. Выбор сохраняется.'
                  : 'How often the app automatically re-downloads the server list from your subscription URLs. Refresh runs while the app is open. Your choice is saved.',
              onTap: () => _chooseInterval(
                  context, app.autoRefreshMinutes, ru, app.setAutoRefreshMinutes),
            ),
            _divider(),
            _settingRow(
              context,
              title: ru ? 'Импорт серверов' : 'Server import',
              subtitle: ru ? 'Доступно' : 'Available',
              explanation: ru
                  ? 'Можно добавлять поддерживаемые ключи и ссылки подписок. Поддерживаемые форматы — по кнопке «?» на экране «Подписка».'
                  : 'Supported server links and subscription URLs can be imported. Supported formats are shown by the "?" button on the Subscription screen.',
            ),
          ]),
        ),
        _section(ru ? 'Состояние функций' : 'Feature status'),
        GlassCard(
          child: Column(children: [
            _settingRow(
              context,
              title: ru ? 'Проверка задержки' : 'Latency check',
              subtitle: ru ? 'TCP-проверка серверов' : 'TCP server checks',
              explanation: ru
                  ? 'Проверяет TCP-доступность и время ответа сервера. Это не проверка скорости VPN-туннеля: полноценное подключение зависит от VPN-ядра.'
                  : 'Checks TCP reachability and response time. This does not measure VPN tunnel speed; a working tunnel requires a VPN engine.',
            ),
            _divider(),
            _settingRow(
              context,
              title: 'Kill Switch',
              subtitle: ru ? 'Требуется интеграция VPN-ядра' : 'Requires VPN engine integration',
              explanation: ru
                  ? 'Эта функция должна блокировать трафик, если VPN отключился. В текущем проекте она не реализована; включать фиктивный переключатель было бы небезопасно.'
                  : 'This should block traffic if the VPN disconnects. It is not implemented in this project; showing a fake toggle would be unsafe.',
            ),
            _divider(),
            _settingRow(
              context,
              title: ru ? 'Разделение трафика' : 'Split tunneling',
              subtitle: ru ? 'Требуется VPN-ядро и выбор приложений' : 'Requires VPN engine and app selection',
              explanation: ru
                  ? 'Позволяет направлять выбранные приложения мимо VPN или через VPN. Нужны Android VpnService API и интегрированное ядро; сейчас функции нет.'
                  : 'Routes selected apps outside or through the VPN. This needs Android VpnService integration and a VPN engine; it is not available yet.',
            ),
            _divider(),
            _settingRow(
              context,
              title: ru ? 'Автоподключение и переподключение' : 'Auto-connect and reconnect',
              subtitle: ru ? 'Требуется системная интеграция' : 'Requires system integration',
              explanation: ru
                  ? 'Для надёжной работы нужны обработка состояния сети, разрешение VPN и фоновый сервис. В текущей версии не включено.'
                  : 'Reliable operation needs network-state handling, VPN permission flow, and a foreground service. Not enabled in this version.',
            ),
            _divider(),
            _settingRow(
              context,
              title: ru ? 'Фильтрация рекламы и DNS' : 'Ad filtering and DNS',
              subtitle: ru ? 'Требуется DNS/фильтрующий модуль' : 'Requires DNS/filter engine',
              explanation: ru
                  ? 'Нужен поддерживаемый DNS-фильтр или правила ядра. Пока это не реализовано и не должно отображаться как работающий переключатель.'
                  : 'Requires a supported DNS filter or engine rules. This is not implemented and should not be presented as a working toggle.',
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
          child: Text(
            ru
                ? 'Долгое нажатие на пункт или кнопка ⓘ открывают пояснение.'
                : 'Long-press an item or tap ⓘ to read its explanation.',
            style: TextStyle(color: SuzopColors.muted, fontSize: 12),
          ),
        ),
      ],
    );
  }

  static String _intervalLabel(int minutes, bool ru) {
    switch (minutes) {
      case 0:
        return ru ? 'Выключено' : 'Off';
      case 15:
        return ru ? 'Каждые 15 минут' : 'Every 15 minutes';
      case 30:
        return ru ? 'Каждые 30 минут' : 'Every 30 minutes';
      case 60:
        return ru ? 'Каждый час' : 'Every hour';
      case 180:
        return ru ? 'Каждые 3 часа' : 'Every 3 hours';
      case 720:
        return ru ? 'Каждые 12 часов' : 'Every 12 hours';
      default:
        return ru ? 'Каждые $minutes мин' : 'Every $minutes min';
    }
  }

  static Widget _section(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 0, 6),
        child: Text(text, style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: SuzopColors.ink,
        )),
      );

  static Widget _divider() => Divider(
        height: 1,
        color: SuzopTheme.dark
            ? Colors.white.withValues(alpha: .10)
            : const Color(0x1E2E7CF6),
      );

  static Widget _settingRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String explanation,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    void explain() => _showExplanation(context, title, explanation);
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      onLongPress: explain,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: explain,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: SuzopColors.ink,
                )),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(
                  fontSize: 11.5,
                  color: SuzopColors.muted,
                )),
              ],
            )),
            IconButton(
              tooltip: L.t('Подробнее', 'More information'),
              visualDensity: VisualDensity.compact,
              onPressed: explain,
              icon: Icon(Icons.info_outline, size: 20, color: SuzopColors.muted),
            ),
            if (trailing != null) trailing,
          ]),
        ),
      ),
    );
  }

  static Future<void> _showExplanation(
          BuildContext context, String title, String body) =>
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(body)),
          actions: [TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(L.t('Понятно', 'Got it')),
          )],
        ),
      );

  static Future<void> _chooseLanguage(BuildContext context, String current,
      ValueChanged<String> setLanguage) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Русский'),
            trailing: current == 'ru' ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(ctx, 'ru'),
          ),
          ListTile(
            title: const Text('English'),
            trailing: current == 'en' ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(ctx, 'en'),
          ),
        ],
      )),
    );
    if (selected != null) setLanguage(selected);
  }

  static Future<void> _chooseInterval(BuildContext context, int current,
      bool ru, ValueChanged<int> setMinutes) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(ru ? 'Как часто обновлять подписку' : 'How often to refresh',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
            for (final m in _intervals)
              ListTile(
                dense: true,
                title: Text(_intervalLabel(m, ru)),
                trailing: current == m ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, m),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null) setMinutes(selected);
  }
}
