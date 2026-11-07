import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models.dart';
import '../i18n.dart';
import '../state.dart';
import '../theme.dart';

/// Раздел «Серверы»: список, «Пинг всех», «Лучший сервер»,
/// цветная индикация пинга, подсказки при долгом нажатии.
/// Ошибки показываются стеклянной плашкой внизу (не SnackBar).
class ServersPage extends StatelessWidget {
  const ServersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final dark = SuzopTheme.dark;

    return Column(
      children: [
        // ── Кнопки действий ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: _ActionChip(
                  label: app.isPinging
                      ? L.t('Пинг…', 'Pinging…')
                      : L.t('⟳ Пинг всех', '⟳ Ping all'),
                  hint: L.t(
                      'Проверяет ВСЕ серверы одновременно (быстро, ~2 сек).\n'
                      'У каждого сервера появится его пинг в миллисекундах.\n'
                      'Если сервер не ответил — покажет «н/д» (не доступен).\n\n'
                      'Пример: после нажатия список станет:\n'
                      '🇳🇱 Амстердам — 32 мс (зелёный)\n'
                      '🇺🇸 Нью-Йорк — 210 мс (жёлтый)\n'
                      '🇯🇵 Токио — н/д (красный)',
                      'Checks ALL servers at once (fast, ~2 sec).\n'
                      'Each server gets its ping in milliseconds.\n'
                      'If a server did not answer — it shows "n/a".\n\n'
                      'Example: after the check the list becomes:\n'
                      '🇳🇱 Amsterdam — 32 ms (green)\n'
                      '🇺🇸 New York — 210 ms (yellow)\n'
                      '🇯🇵 Tokyo — n/a (red)'),
                  onTap: app.isPinging ? null : () => app.refreshPing(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionChip(
                  label: L.t('⚡ Лучший', '⚡ Best'),
                  hint: L.t(
                      'Находит сервер с САМЫМ НИЗКИМ пингом и сразу выбирает его.\n'
                      'Пингует все серверы параллельно и берёт лучший.\n\n'
                      'Пример: был выбран Токио (164 мс), нажал «⚡ Лучший» —\n'
                      'приложение выбрало Амстердам (32 мс) и он подсветился.',
                      'Finds the server with the LOWEST ping and selects it.\n'
                      'Pings all servers in parallel and picks the best one.\n\n'
                      'Example: Tokyo was selected (164 ms), tap "⚡ Best" —\n'
                      'the app selected Amsterdam (32 ms) and highlighted it.'),
                  onTap: app.isPinging
                      ? null
                      : () async {
                          final best = await app.findBestServer();
                          if (best == null) {
                            app.showError(
                                L.t('Ни один сервер не ответил',
                                    'No server responded'),
                                Help.bestNone);
                          } else {
                            app.clearError();
                          }
                        },
                ),
              ),
            ],
          ),
        ),

        // ── Список серверов ──────────────────────────────────────────
        Expanded(
          child: app.servers.isEmpty
              ? Center(
                  child: Text(
                    L.t('Нет серверов.\nДобавь ключ или подписку\nво вкладке «Подписка».',
                        'No servers.\nAdd a key or subscription\non the "Subscription" tab.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: SuzopColors.muted, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  itemCount: app.servers.length,
                  itemBuilder: (context, i) {
                    final s = app.servers[i];
                    final isSel = i == app.selected;
                    return _ServerTile(server: s, selected: isSel);
                  },
                ),
        ),
      ],
    );
  }
}

/// Стеклянная декорация (в цвете темы) — определена прямо здесь.
BoxDecoration _glass({bool highlight = false}) {
  final dark = SuzopTheme.dark;
  return BoxDecoration(
    color: dark
        ? Colors.white.withValues(alpha: highlight ? 0.20 : 0.08)
        : Colors.white.withValues(alpha: highlight ? 0.78 : 0.55),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: highlight
          ? const Color(0xFF0A5FA8)
          : (dark
              ? Colors.white.withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: 0.6)),
      width: highlight ? 1.8 : 1,
    ),
    boxShadow: [
      BoxShadow(
        color: (dark ? Colors.black : const Color(0xFF3B82C4))
            .withValues(alpha: dark ? 0.35 : 0.10),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

/// Кнопка-чип с подсказкой при долгом нажатии.
class _ActionChip extends StatelessWidget {
  final String label;
  final String hint;
  final VoidCallback? onTap;
  const _ActionChip({required this.label, required this.hint, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showHint(context, hint),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: _glass(),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0A5FA8),
          ),
        ),
      ),
    );
  }
}

/// Карточка сервера с цветным пингом и подсказкой при долгом нажатии.
class _ServerTile extends StatelessWidget {
  final VpnServer server;
  final bool selected;
  const _ServerTile({required this.server, required this.selected});

  @override
  Widget build(BuildContext context) {
    final pingColor = server.pingColor;
    return GestureDetector(
      onLongPress: () => _showHint(
        context,
        '${server.flag} ${server.name}\n'
            '${L.t('Протокол', 'Protocol')}: ${server.protocol}\n'
            '${L.t('Адрес', 'Address')}: ${server.host}:${server.port}\n\n'
            '${L.t('Пинг', 'Ping')} ${server.pingLabel} — ${L.t('время отклика сервера', 'server response time')}\n'
            '${L.t('Зелёный < 200 мс — отлично.', 'Green < 200 ms — excellent.')}\n'
            '${L.t('Жёлтый > 200 мс — заметные задержки.', 'Yellow > 200 ms — noticeable delay.')}\n'
            '${L.t('Красный «н/д» — сервер не отвечает.', 'Red "n/a" — server not responding.')}\n\n'
            '${L.t('Одиночное нажатие — выбрать этот сервер.', 'Single tap — select this server.')}',
      ),
      onTap: () {
        final app = context.read<AppState>();
        app.select(server);
        app.goToPage(0);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: _glass(highlight: selected),
        child: Row(
          children: [
            Text(server.flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(server.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: SuzopColors.ink)),
                  Text(server.protocol,
                      style: TextStyle(
                          fontSize: 12, color: SuzopColors.muted)),
                ],
              ),
            ),
            // Пинг в цветной «пилюле»
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: pingColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: pingColor, width: 1.4),
              ),
              child: Text(
                server.pingLabel,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: pingColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Всплывающая стеклянная плашка-подсказка.
Future<void> _showHint(BuildContext context, String text) async {
  final dark = SuzopTheme.dark;
  showDialog(
    context: context,
    barrierColor: Colors.black26,
    builder: (ctx) => GestureDetector(
      onTap: () => Navigator.of(ctx).pop(),
      child: AlertDialog(
        backgroundColor: dark
            ? const Color(0xFF16294A).withValues(alpha: 0.97)
            : Colors.white.withValues(alpha: 0.96),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Text(
          text,
          style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: dark ? const Color(0xFFEAF4FF) : const Color(0xFF12303F)),
        ),
      ),
    ),
  );
}
