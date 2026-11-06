import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models.dart';
import '../state.dart';

/// Раздел «Серверы»: список, кнопки «Пинг всех» и «Лучший сервер»,
/// цветная индикация пинга, подсказки при долгом нажатии.
class ServersPage extends StatelessWidget {
  const ServersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Кнопки действий ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: _ActionChip(
                  label: app.isPinging ? 'Пинг…' : '⟳ Пинг всех',
                  hint: 'Проверяет ВСЕ серверы одновременно (быстро, ~2 сек).\n'
                      'У каждого сервера появится его пинг в миллисекундах.\n'
                      'Если сервер не ответил — покажет «н/д» (не доступен).\n\n'
                      'Пример: после нажатия список станет:\n'
                      '🇳🇱 Амстердам — 32 мс (зелёный)\n'
                      '🇺🇸 Нью-Йорк — 210 мс (жёлтый)\n'
                      '🇯🇵 Токио — н/д (красный)',
                  onTap: app.isPinging ? null : () => app.refreshPing(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionChip(
                  label: '⚡ Лучший',
                  hint: 'Находит сервер с САМЫМ НИЗКИМ пингом и сразу выбирает его.\n'
                      'Пингует все серверы параллельно и берёт лучший.\n\n'
                      'Пример: был выбран Токио (164 мс), нажал «⚡ Лучший» —\n'
                      'приложение выбрало Амстердам (32 мс) и он подсветился.',
                  onTap: app.isPinging
                      ? null
                      : () async {
                          final best = await app.findBestServer();
                          if (!context.mounted) return;
                          final msg = best == null
                              ? 'Ни один сервер не ответил'
                              : 'Выбран лучший: ${best.flag} ${best.name} — ${best.pingMs} мс';
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(content: Text(msg)));
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
                    'Нет серверов.\nДобавь ключ или подписку\nво вкладке «Подписка».',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.black54),
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

/// Стеклянная карточка (жидкое стекло) — определена прямо здесь,
/// чтобы не зависеть от theme.dart.
BoxDecoration _glass(BuildContext context, {bool highlight = false}) {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: highlight ? 0.78 : 0.55),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: highlight
          ? const Color(0xFF0A5FA8)
          : Colors.white.withValues(alpha: 0.6),
      width: highlight ? 1.8 : 1,
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF3B82C4).withValues(alpha: 0.10),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

/// Стеклянная кнопка-чип с подсказкой при долгом нажатии.
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
        decoration: _glass(context),
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

/// Карточка одного сервера с цветным пингом и подсказкой при долгом нажатии.
class _ServerTile extends StatelessWidget {
  final VpnServer server;
  final bool selected;
  const _ServerTile({required this.server, required this.selected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pingColor = server.pingColor;
    return GestureDetector(
      // Долгое нажатие → подробная подсказка «что делает».
      onLongPress: () => _showHint(
        context,
        '${server.flag} ${server.name}\n'
        'Протокол: ${server.protocol}\n'
        'Адрес: ${server.host}:${server.port}\n\n'
        'Пинг ${server.pingLabel} — это время отклика сервера.\n'
        'Зелёный < 200 мс — отлично, игры и звонки без лагов.\n'
        'Жёлтый > 200 мс — заметные задержки, страницы грузятся дольше.\n'
        'Красный «н/д» — сервер не отвечает, подключение не получится.\n\n'
        'Одиночное нажатие — выбрать этот сервер для подключения.',
      ),
      onTap: () {
        final app = context.read<AppState>();
        app.select(server);
        app.goToPage(0);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: _glass(context, highlight: selected),
        child: Row(
          children: [
            Text(server.flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    server.protocol,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.black45),
                  ),
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

/// Всплывающая стеклянная плашка-подсказка: полностью понятное
/// описание функции + примеры. Закрывается тапом.
Future<void> _showHint(BuildContext context, String text) async {
  showDialog(
    context: context,
    barrierColor: Colors.black26,
    builder: (ctx) => GestureDetector(
      onTap: () => Navigator.of(ctx).pop(),
      child: AlertDialog(
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Text(
          text,
          style: const TextStyle(
              fontSize: 14.5, height: 1.5, color: Color(0xFF12303F)),
        ),
      ),
    ),
  );
}
