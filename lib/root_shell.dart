import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'i18n.dart';
import 'state.dart';
import 'theme.dart';
import 'ui/error_banner.dart';
import 'ui/servers_page.dart';
import 'ui/subscription_page.dart';
import 'ui/settings_page.dart';

/// Три раздела со свайпами. Внизу — стеклянная панель с плавающим
/// овалом-подсветкой, который перекатывается между пунктами и едет
/// вместе со свайпом. Над панелью — плашка ошибки (если есть).
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  late final PageController _pc;
  double _page = 0; // дробная позиция свайпа для плавающего овала

  @override
  void initState() {
    super.initState();
    final st = context.read<AppState>();
    _page = st.page.toDouble();
    _pc = PageController(initialPage: st.page)
      ..addListener(() => _page = _pc.hasClients ? _pc.page ?? _page : _page);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _to(int p) {
    _pc.animateToPage(p,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final dark = SuzopTheme.dark;

    final labels = [
      L.t('Серверы', 'Servers'),
      L.t('Подписка', 'Subscription'),
      L.t('Настройки', 'Settings'),
    ];

    return Scaffold(
      body: Stack(children: [
        const SkyBackground(),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(children: [
                const Text('suzop',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                        color: SuzopColors.ink)),
                const Spacer(),
                GlassCard(
                  radius: 20,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                  child: Row(children: [
                    Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: st.state == 2
                            ? SuzopColors.green
                            : SuzopColors.red,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                        st.state == 2
                            ? L.t('Защищено', 'Protected')
                            : L.t('Не защищено', 'Unprotected'),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: SuzopColors.muted)),
                  ]),
                ),
              ]),
            ),
            Expanded(
              child: PageView(
                controller: _pc,
                onPageChanged: (p) => context.read<AppState>().goToPage(p),
                children: const [
                  ServersPage(),
                  SubscriptionPage(),
                  SettingsPage(),
                ],
              ),
            ),
          ]),
        ),
      ]),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Плашка ошибки над нижней панелью
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: st.errorText != null
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: ErrorBanner(
                      text: st.errorText!,
                      help: st.errorHelp,
                      onClose: st.clearError,
                    ),
                  )
                : const SizedBox(height: 0, width: double.infinity),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: GlassCard(
              radius: 24,
              padding: const EdgeInsets.all(5),
              child: LayoutBuilder(builder: (context, c) {
                final w = c.maxWidth / 3;
                return SizedBox(
                  height: 42,
                  child: Stack(children: [
                    // Плавающий овал: едет при свайпе и тапе.
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment(-1 + 2 * (_page.clamp(0, 2) / 2), 0),
                      child: FractionallySizedBox(
                        widthFactor: 1 / 3,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(19),
                            color: dark
                                ? Colors.white.withValues(alpha: .16)
                                : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    // Подписи поверх овала
                    Row(children: [
                      for (final (i, label) in labels.indexed)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _to(i),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: (st.page == i)
                                    ? SuzopColors.blue
                                    : SuzopColors.muted,
                              ),
                              child: Text(label,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ),
                    ]),
                  ]),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
