import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state.dart';
import 'theme.dart';
import 'ui/servers_page.dart';
import 'ui/subscription_page.dart';
import 'ui/settings_page.dart';

/// Три раздела, перелистываются свайпом влево/вправо (PageView).
class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  late final PageController _pc;

  @override
  void initState() {
    super.initState();
    _pc = PageController(initialPage: context.read<AppState>().page);
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
                    Text(st.state == 2 ? 'Защищено' : 'Не защищено',
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
      bottomNavigationBar: GlassCard(
        radius: 24,
        padding: const EdgeInsets.all(5),
        child: Row(children: [
          for (final (i, label) in ['Серверы', 'Подписка', 'Настройки'].indexed)
            Expanded(
              child: GestureDetector(
                onTap: () => _to(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(19),
                    color: st.page == i ? Colors.white70 : null,
                  ),
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: st.page == i
                              ? SuzopColors.blue
                              : SuzopColors.muted)),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
