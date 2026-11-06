import 'package:flutter/material.dart';

import '../theme.dart';

/// Раздел «Настройки»: тумблеры и строки.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
        children: [
          _section('Подключение'),
          GlassCard(
            child: Column(children: [
              _row('📡', 'Протокол', 'Авто (VLESS / VMess / Trojan / SS / WG)'),
              const Divider(height: 1, color: Color(0x1E2E7CF6)),
              _switch('🛡', 'Kill Switch',
                  'Блокировать интернет без VPN', true),
              const Divider(height: 1, color: Color(0x1E2E7CF6)),
              _switch('🚀', 'Автозапуск',
                  'Подключаться при старте системы', true),
              const Divider(height: 1, color: Color(0x1E2E7CF6)),
              _switch('🎯', 'Автовыбор сервера',
                  'Самый быстрый по пингу', false),
              const Divider(height: 1, color: Color(0x1E2E7CF6)),
              _switch('🔀', 'Разделение трафика',
                  'Приложения вне VPN', false),
            ]),
          ),
          _section('Приложение'),
          GlassCard(
            child: Column(children: [
              _row('🎨', 'Тема', 'Небесная · светлая'),
              const Divider(height: 1, color: Color(0x1E2E7CF6)),
              _row('🌐', 'Язык', 'Русский'),
              const Divider(height:1, color: Color(0x1E2E7CF6)),
              _row('ℹ️', 'О приложении', 'suzop v0.1'),
            ]),
          ),
        ],
      );

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 0, 4),
        child: Text(t,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: SuzopColors.ink)),
      );

  Widget _row(String ico, String title, String sub) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Text(ico, style: const TextStyle(fontSize: 19)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: SuzopColors.ink)),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 11, color: SuzopColors.muted)),
                ]),
          ),
          const Text('›',
              style: TextStyle(
                  color: Color(0xFF7FA0C4),
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _switch(String ico, String title, String sub, bool initial) {
    bool v = initial;
    return StatefulBuilder(
      builder: (_, set) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Text(ico, style: const TextStyle(fontSize: 19)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: SuzopColors.ink)),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 11, color: SuzopColors.muted)),
                ]),
          ),
          GestureDetector(
            onTap: () => set(() => v = !v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 46, height: 27,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: v
                    ? const LinearGradient(colors: [
                        Color(0xFF4FD895),
                        Color(0xFF1FBF6B)
                      ])
                    : null,
                color: v ? null : Colors.white60,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                alignment: v ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Colors.white),
                  width: 21, height: 21,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
