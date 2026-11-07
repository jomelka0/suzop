import 'package:flutter/material.dart';

import '../i18n.dart';
import '../theme.dart';

/// Плашка ошибки в стиле приложения: скруглённое стекло в цвете темы,
/// красный восклицательный знак, текст, кнопка «?» (что случилось и как
/// починить) и крестик закрытия. Не исчезает сама.
class ErrorBanner extends StatelessWidget {
  final String text;
  final String? help;
  final VoidCallback onClose;
  const ErrorBanner({super.key, required this.text, this.help, required this.onClose});

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L.t('Что случилось и как исправить', 'What happened and how to fix it')),
        content: SingleChildScrollView(
          child: Text(help ?? L.t('Подсказки для этой ошибки нет.',
              'No hint available for this error.')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(L.t('Понятно', 'Got it')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      child: Row(children: [
        // Красный круг с восклицательным знаком
        Container(
          width: 26, height: 26,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Color(0xFFF07A70), Color(0xFFE2574C)]),
          ),
          child: const Icon(Icons.priority_high,
              size: 18, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: SuzopColors.ink)),
        ),
        if (help != null)
          IconButton(
            tooltip: L.t('Что это значит?', 'What does this mean?'),
            visualDensity: VisualDensity.compact,
            onPressed: () => _showHelp(context),
            icon: Icon(Icons.help_outline, size: 20, color: SuzopColors.red),
          ),
        IconButton(
          tooltip: L.t('Закрыть', 'Close'),
          visualDensity: VisualDensity.compact,
          onPressed: onClose,
          icon: Icon(Icons.close, size: 19, color: SuzopColors.muted),
        ),
      ]),
    );
  }
}
