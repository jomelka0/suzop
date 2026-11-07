import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/parsers.dart';
import '../core/subscription_fetch.dart';
import '../i18n.dart';
import '../state.dart';
import '../theme.dart';

/// Раздел «Подписка».
/// Плашка «Основная подписка» показывается ТОЛЬКО когда подписка
/// добавлена. Трафик — только реальный, из заголовка подписки.
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final _url = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final st = context.read<AppState>();
    final url = _url.text.trim();
    if (url.isEmpty) {
      st.showError(L.t('Поле пустое — вставь ссылку или ключ',
          'The field is empty — paste a link or key'), Help.clipboardEmpty);
      return;
    }
    try {
      if (url.contains('://') && !url.startsWith('http')) {
        // одиночный ключ
        final s = parseLink(url);
        if (s == null) {
          st.showError(L.t('Не удалось распознать ключ', 'Could not parse the key'), Help.key);
          return;
        }
        st.addServers([s]);
        st.clearError();
        return;
      }
      final info = await fetchSubscription(url);
      if (info.servers.isEmpty) {
        st.showError(L.t('В подписке нет поддерживаемых серверов',
            'No supported servers in the subscription'), Help.noServers);
        return;
      }
      st.addServers(info.servers);
      st.setTrafficInfo(info);
      st.addSub(url);
      st.clearError();
      st.refreshPing();
    } on SubscriptionRejectedException {
      st.showError(L.t('Панель подписки не поддерживает этот клиент',
          'The panel does not support this client'), Help.reject);
    } catch (e) {
      st.showError(L.t('Сеть недоступна', 'Network unavailable'), Help.net);
    }
  }

  /// Вставляет ссылку/ключ из буфера обмена и сразу импортирует.
  Future<void> _pasteAndImport() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      context.read<AppState>().showError(
          L.t('Буфер обмена пуст', 'Clipboard is empty'), Help.clipboardEmpty);
      return;
    }
    _url.text = text;
    await _import();
  }

  /// Окно со всеми поддерживаемыми форматами (кнопка «?»).
  void _showFormats() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L.t('Поддерживаемые форматы', 'Supported formats')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (name, desc) in [
                ('vless://…', L.t('VLESS-ключ (Reality, TLS, WS и др.)',
                    'VLESS key (Reality, TLS, WS, etc.)')),
                ('vmess://…', L.t('VMess-ключ, включая base64-ссылки',
                    'VMess key, including base64 links')),
                ('trojan://…', L.t('Trojan-ключ', 'Trojan key')),
                ('ss://…', L.t('Shadowsocks-ключ', 'Shadowsocks key')),
                ('https://…', L.t('Ссылка на подписку — список серверов',
                    'Subscription URL — server list')),
                ('base64', L.t('Подписка, закодированная в base64',
                    'Subscription encoded in base64')),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: SuzopColors.blue)),
                      Text(desc,
                          style: TextStyle(
                              fontSize: 12.5, color: SuzopColors.muted)),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                L.t('WireGuard-конфиги (.conf) — в разработке.',
                    'WireGuard configs (.conf) — in development.'),
                style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: SuzopColors.muted),
              ),
            ],
          ),
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

  String _autoLabel(int minutes) {
    switch (minutes) {
      case 0:
        return L.t('Выключено', 'Off');
      case 15:
        return L.t('Каждые 15 минут', 'Every 15 minutes');
      case 30:
        return L.t('Каждые 30 минут', 'Every 30 minutes');
      case 60:
        return L.t('Каждый час', 'Every hour');
      case 180:
        return L.t('Каждые 3 часа', 'Every 3 hours');
      default:
        return L.t('Каждые $minutes мин', 'Every $minutes min');
    }
  }

  String _fmtGb(int bytes) {
    final gb = bytes / (1024 * 1024 * 1024);
    return gb >= 10 ? '${gb.round()} ГБ' : '${gb.toStringAsFixed(1)} ГБ';
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final hasSub = st.subUrls.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      children: [
        // ── Основная подписка: только после добавления ──
        if (hasSub)
          GlassCard(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Основная подписка',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: SuzopColors.ink)),
                  const SizedBox(height: 2),
                  Text('Серверов: ${st.servers.length} · подписок: ${st.subUrls.length}',
                      style: const TextStyle(
                          fontSize: 11.5, color: SuzopColors.muted)),
                  const SizedBox(height: 10),
                  ...[
                    (L.t('Статус', 'Status'), L.t('Активна', 'Active')),
                    (L.t('Автообновление', 'Auto-refresh'),
                        _autoLabel(st.autoRefreshMinutes)),
                    if (st.lastRefreshLabel != null)
                      (L.t('Обновлено в', 'Updated at'), st.lastRefreshLabel!),
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
                  // Реальный трафик из заголовка подписки (если панель отдала).
                  if (st.trafficLimitBytes != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (st.trafficUsedBytes /
                                st.trafficLimitBytes!)
                            .clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: Colors.white60,
                        valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF28B6EE)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${_fmtGb(st.trafficUsedBytes)} / ${_fmtGb(st.trafficLimitBytes!)}',
                        style: const TextStyle(
                            fontSize: 11.5, color: SuzopColors.muted)),
                  ],
                ]),
          ),

        if (hasSub) const SizedBox(height: 12),

        // ── Импорт ──────────────────────────────────────
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(L.t('Импорт подписки или ключа',
                      'Import subscription or key'),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: SuzopColors.ink)),
                ),
                IconButton(
                  tooltip: L.t('Какие форматы поддерживаются',
                      'Supported formats'),
                  visualDensity: VisualDensity.compact,
                  onPressed: _showFormats,
                  icon: Icon(Icons.help_outline,
                      size: 21, color: SuzopColors.muted),
                ),
              ]),
              const SizedBox(height: 4),
              GlassCard(
                radius: 15,
                padding: EdgeInsets.zero,
                child: TextField(
                  controller: _url,
                  decoration: InputDecoration(
                    hintText: L.t('Ссылка подписки или ключ vless://…',
                        'Subscription URL or key vless://…'),
                    hintStyle: const TextStyle(
                        color: Color(0xFF8FA9C6), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pasteAndImport,
                    icon: const Icon(Icons.content_paste, size: 17),
                    label: Text(L.t('Из буфера', 'From clipboard'),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SuzopColors.blue,
                      side: const BorderSide(color: Color(0xFF7FA0C4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _import,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7CF6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(L.t('Импортировать', 'Import'),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Text(
                L.t('Подписка обновляется автоматически — интервал в настройках.',
                    'The subscription refreshes automatically — interval in Settings.'),
                style: TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: SuzopColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Список серверов ──────────────────────────────
        for (final s in st.servers)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: GlassCard(
              radius: 18,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
