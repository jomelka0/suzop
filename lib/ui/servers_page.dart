import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models.dart';
import '../state.dart';
import '../theme.dart';

/// Раздел «Серверы»: кнопка (просто зеленеет — без анимаций), поиск, список.
/// Кнопка уезжает вверх при скролле вниз и возвращается при скролле вверх.
class ServersPage extends StatefulWidget {
  const ServersPage({super.key});
  @override
  State<ServersPage> createState() => _ServersPageState();
}

class _ServersPageState extends State<ServersPage> {
  final _scroll = ScrollController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final hide = _scroll.offset > 120;
      final show = _scroll.offset < 40;
      final st = context.read<AppState>();
      if (hide != st.heroHidden && (hide || show)) {
        st.setHeroHidden(hide);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshPing();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final list = st.servers
        .where((s) => s.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(children: [
      AnimatedSlide(
        offset: st.heroHidden ? const Offset(0, -2) : Offset.zero,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: st.heroHidden ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          child: Column(children: [
            Text(
              st.state == 2
                  ? 'Защищено · ${st.activeName}'
                  : st.state == 1
                      ? 'Подключение…'
                      : 'Нажми кнопку, чтобы подключиться',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: st.state == 2 ? SuzopColors.green : SuzopColors.muted),
            ),
            const SizedBox(height: 10),
            _ConnectButton(state: st.state, onTap: () => st.state == 2
                ? st.disconnect()
                : st.tryConnect()),
            const SizedBox(height: 10),
            if (st.state == 2)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _MiniChip('⏱ ${st.timeLabel}', SuzopColors.blue),
                const SizedBox(width: 7),
                _MiniChip(
                    '⚡ ${st.speedMbps.toStringAsFixed(1)} Мбит/с',
                    SuzopColors.green),
                const SizedBox(width: 7),
                _MiniChip('⇅ ${st.totalMb.toStringAsFixed(0)} МБ',
                    SuzopColors.amber),
              ]),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
        child: GlassCard(
          radius: 15,
          padding: EdgeInsets.zero,
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Поиск страны или города…',
              hintStyle: TextStyle(color: Color(0xFF8FA9C6), fontSize: 13),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
          ),
        ),
      ),
      Expanded(
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final s = list[i];
            final isSel = st.servers.indexOf(s) == st.selected;
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _ServerCard(
                server: s,
                selected: isSel,
                onTap: () => st.select(s),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _ConnectButton extends StatelessWidget {
  final int state;
  final VoidCallback onTap;
  const _ConnectButton({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 92, height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: const Alignment(-.8, -.8),
          end: const Alignment(.8, .8),
          colors: state == 2
              ? [Color(0xFF8FEFC0), Color(0xFF1FBF6B)]
              : [Colors.white70, Colors.white24],
        ),
        border: Border.all(
            color: state == 2 ? SuzopColors.green : Colors.white70, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (state == 2 ? SuzopColors.green : SuzopColors.blue)
                .withValues(alpha: .35),
            blurRadius: 30, offset: const Offset(0, 12)),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.power_settings_new,
          size: 40,
          color: state == 2 ? Colors.white : SuzopColors.blue,
        ),
      ),
    ),
  );
}

class _MiniChip extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniChip(this.text, this.color);

  @override
  Widget build(BuildContext context) => GlassCard(
    radius: 14,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    child: Text(text,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w800, color: color)),
  );
}

class _ServerCard extends StatelessWidget {
  final VpnServer server;
  final bool selected;
  final VoidCallback onTap;
  const _ServerCard(
      {required this.server, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: GlassCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Text(server.flag, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(server.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: SuzopColors.ink)),
              Text('${server.protocol} · 1 Гбит/с',
                  style: const TextStyle(
                      fontSize: 11, color: SuzopColors.muted)),
            ],
          ),
        ),
        Column(children: [
          SizedBox(
            width: 34, height: 4,
            child: LinearProgressIndicator(
              value: server.pingMs == null
                  ? 0
                  : (1 - (server.pingMs!.clamp(0, 400) / 400)).clamp(0, 1),
              backgroundColor: Colors.white60,
              valueColor: AlwaysStoppedAnimation(server.pingColor),
            ),
          ),
          Text(server.pingLabel,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: server.pingColor)),
        ]),
        const SizedBox(width: 12),
        Container(
          width: 18, height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: selected ? SuzopColors.green : SuzopColors.blue,
                width: 2),
            color: selected ? SuzopColors.green : Colors.transparent,
          ),
          child: selected
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : null,
        ),
      ]),
    ),
  );
}
