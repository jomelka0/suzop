import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../core/parsers.dart';
import '../core/subscription_fetch.dart';
import '../state.dart';
import '../theme.dart';

/// Раздел «Подписка»: вся информация о подписках + импорт + список серверов
/// (без кнопки подключения), серверы из подписок.
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});
  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final _url = TextEditingController();

  Future<void> _import() async {
    final st = context.read<AppState>();
    final url = _url.text.trim();
    if (url.isEmpty) return;
    try {
      if (url.contains('://') && !url.startsWith('http')) {
        // одиночный ключ
        final s = parseLink(url);
        if (s == null) {
          _toast('Не удалось распознать ключ 😕');
          return;
        }
        st.addServers([s]);
        _toast('Ключ добавлен: ${s.name}');
        return;
      }
      final list = await fetchSubscription(url);
      if (list.isEmpty) {
        _toast('В подписке нет поддерживаемых серверов');
        return;
      }
      st.addServers(list);
      st.addSub(url);
      _toast('Добавлено серверов: ${list.length}');
      st.refreshPing();
    } catch (e) {
      _toast('Ошибка: сеть недоступна');
    }
  }

  Future<void> _refresh() async {
    final st = context.read<AppState>();
    try {
      for (final u in st.subUrls) {
        final list = await fetchSubscription(u);
        if (list.isNotEmpty) {
          st.replaceServers(list);
        }
      }
      _toast('Подписки обновлены ✓');
      st.refreshPing();
    } catch (_) {
      _toast('Не удалось обновить подписки');
    }
  }

  void _toast(String m) {
    final s = ScaffoldMessenger.of(context);
    s.showSnackBar(SnackBar(
      content: Text(m),
      behavior: SnackBarBehavior.floating,
      backgroundColor: SuzopColors.ink,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      children: [
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Основная подписка',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: SuzopColors.ink)),
            const SizedBox(height: 2),
            Text('Серверов: ${st.servers.length} · подписок: ${st.subUrls.length}',
                style:
                    const TextStyle(fontSize: 11.5, color: SuzopColors.muted)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: .37,
                minHeight: 10,
                backgroundColor: Colors.white60,
                valueColor:
                    const AlwaysStoppedAnimation(Color(0xFF28B6EE)),
              ),
            ),
            const SizedBox(height: 6),
            const Text('Трафик: 37 ГБ из 100 ГБ',
                style:
                    const TextStyle(fontSize: 11.5, color: SuzopColors.muted)),
            const SizedBox(height: 10),
            ...[
              ('Серверов в подписке', '${st.servers.length}'),
              ('Форматы', 'VLESS · VMess · Trojan · SS · WG'),
              ('Статус', st.subUrls.isEmpty ? 'Нет подписок' : 'Активна ✓'),
            ].map((kv) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(kv.$1,
                            style: const TextStyle(
                                fontSize: 13, color: SuzopColors.muted)),
                        Text(kv.$2,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: SuzopColors.ink)),
                      ]),
                )),
          ]),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Импорт подписки или ключа',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: SuzopColors.ink)),
              const SizedBox(height: 10),
              GlassCard(
                radius: 15,
                padding: EdgeInsets.zero,
                child: TextField(
                  controller: _url,
                  decoration: const InputDecoration(
                    hintText: 'https://…  vless://  vmess://  ss://  trojan://',
                    hintStyle:
                        TextStyle(color: Color(0xFF8FA9C6), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _import,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Импортировать',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _refresh,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF7FA0C4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Обновить подписки',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  for (final f in supportedFormats)
                    GlassCard(
                      radius: 12,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Text(f,
                          style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: SuzopColors.muted)),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final s in st.servers)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: GlassCard(
              radius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                Text(s.flag, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: SuzopColors.ink)),
                ),
                Text('${s.protocol} · ${s.pingLabel}',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: s.pingColor)),
              ]),
            ),
          ),
      ],
    );
  }
}
