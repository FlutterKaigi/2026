import 'package:data/data.dart';
import 'package:data/user.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'providers.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({required this.user, super.key});

  final User user;

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ログアウトに失敗しました。再試行してください。')));
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('FlutterKaigi 2026', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      leading: Padding(padding: const EdgeInsets.all(12), child: Image.asset('assets/shuriken-logo.png')),
      actions: [
        TextButton.icon(
          onPressed: _signingOut ? null : _signOut,
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('ログアウト'),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: _HistoryBody(uid: widget.user.uid, account: widget.user.email ?? widget.user.displayName ?? 'ログイン中'),
        ),
      ),
    ),
  );
}

class _HistoryBody extends ConsumerWidget {
  const _HistoryBody({required this.uid, required this.account});

  final String uid;
  final String account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(cardProvider(uid));
    final settings = ref.watch(settingsProvider);
    final sponsorIds = ref.watch(sponsorIdsProvider);
    final sponsors = ref.watch(sponsorsProvider);

    void retry() {
      ref
        ..invalidate(cardProvider(uid))
        ..invalidate(settingsProvider)
        ..invalidate(sponsorIdsProvider)
        ..invalidate(sponsorsProvider);
    }

    final values = [card, settings, sponsorIds, sponsors];
    if (values.any((value) => value.hasError)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 40),
              const SizedBox(height: 16),
              const Text('履歴を読み込めませんでした。通信環境を確認して再試行してください。'),
              const SizedBox(height: 16),
              FilledButton(onPressed: retry, child: const Text('再読み込み')),
            ],
          ),
        ),
      );
    }
    if (values.any((value) => !value.hasValue)) {
      return const Center(child: CircularProgressIndicator(semanticsLabel: '履歴を読み込み中'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Summary(card: card.requireValue, account: account),
          const SizedBox(height: 24),
          _SponsorHistory(
            card: card.requireValue,
            sponsorIds: sponsorIds.requireValue,
            sponsors: sponsors.requireValue,
          ),
          const SizedBox(height: 24),
          _RewardHistory(card: card.requireValue, settings: settings.requireValue),
          const SizedBox(height: 24),
          Text(
            '公式アプリの記録を自動で反映します。日時は日本時間（JST）です。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.card, required this.account});

  final StampRallyCard card;
  final String account;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(colors: [Color(0xFF075663), Color(0xFF17375E)]),
    ),
    child: DefaultTextStyle.merge(
      style: const TextStyle(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MY STAMP RALLY', style: TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('スタンプラリーの状況確認', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(account),
          const SizedBox(height: 24),
          Wrap(
            spacing: 32,
            runSpacing: 16,
            children: [
              _SummaryValue(value: '${card.stampCount}', label: '獲得スタンプ'),
              _SummaryValue(value: '${card.rewardsRedeemedAt.length}', label: '交換済み景品'),
              _SummaryValue(value: card.thanksCardRedeemedAt == null ? '未交換' : '交換済み', label: 'サンクスカード'),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}

class _SponsorHistory extends StatefulWidget {
  const _SponsorHistory({required this.card, required this.sponsorIds, required this.sponsors});

  final StampRallyCard card;
  final Set<String> sponsorIds;
  final List<Sponsor> sponsors;

  @override
  State<_SponsorHistory> createState() => _SponsorHistoryState();
}

class _SponsorHistoryState extends State<_SponsorHistory> {
  bool _showAcquired = true;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final byId = {for (final sponsor in widget.sponsors) sponsor.id: sponsor};
    final pending = widget.sponsorIds.difference(card.stamps.keys.toSet());
    final ids = (_showAcquired ? card.stamps.keys : pending).toList()
      ..sort((a, b) {
        if (_showAcquired) {
          final order = card.stamps[b]!.compareTo(card.stamps[a]!);
          if (order != 0) return order;
        }
        return (byId[a]?.name.ja ?? a).compareTo(byId[b]?.name.ja ?? b);
      });
    return _Section(
      title: 'スポンサーのスタンプ',
      icon: Icons.approval_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text('獲得済み ${card.stampCount}'),
                selected: _showAcquired,
                onSelected: (_) => setState(() => _showAcquired = true),
              ),
              ChoiceChip(
                label: Text('未獲得 ${pending.length}'),
                selected: !_showAcquired,
                onSelected: (_) => setState(() => _showAcquired = false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (ids.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                _showAcquired ? 'まだスタンプを獲得していません。\n公式アプリでスポンサーの QR コードを読み取ると、ここに表示されます。' : '未獲得のスポンサーはありません。',
                textAlign: TextAlign.center,
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final id in ids)
                    SizedBox(
                      width: constraints.maxWidth >= 660 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
                      child: _SponsorTile(id: id, sponsor: byId[id], acquiredAt: card.stamps[id]),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SponsorTile extends StatelessWidget {
  const _SponsorTile({required this.id, required this.sponsor, required this.acquiredAt});

  final String id;
  final Sponsor? sponsor;
  final DateTime? acquiredAt;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final logo = sponsor?.primaryLogoUrl;
    const fallback = Icon(Icons.business_outlined, size: 28);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: logo == null || logo.isEmpty
                ? fallback
                : Image.network(
                    logo,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) => fallback,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sponsor?.name.ja ?? 'スポンサー情報なし（$id）', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  acquiredAt == null ? '未獲得' : '獲得済み · ${formatHistoryTime(acquiredAt!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            acquiredAt == null ? Icons.circle_outlined : Icons.check_circle,
            color: acquiredAt == null ? colors.outline : colors.primary,
            semanticLabel: acquiredAt == null ? '未獲得' : '獲得済み',
          ),
        ],
      ),
    );
  }
}

class _RewardHistory extends StatelessWidget {
  const _RewardHistory({required this.card, required this.settings});

  final StampRallyCard card;
  final StampRallySettings settings;

  @override
  Widget build(BuildContext context) {
    // Keep past redemptions visible even after checkpoint settings change.
    final numbers = {for (var i = 1; i <= settings.checkpoints.length; i++) i, ...card.rewardsRedeemedAt.keys}.toList()
      ..sort();
    return _Section(
      title: '景品・サンクスカードの交換',
      icon: Icons.redeem_outlined,
      child: Column(
        children: [
          for (final number in numbers) ...[
            _RewardTile(
              title: '景品 #$number',
              requirement: number > 0 && number <= settings.checkpoints.length
                  ? 'スタンプ ${settings.checkpoints[number - 1]} 個'
                  : '過去の交換記録',
              redeemedAt: card.rewardsRedeemedAt[number],
              available:
                  number > 0 &&
                  number <= settings.checkpoints.length &&
                  card.stampCount >= settings.checkpoints[number - 1],
            ),
            const Divider(height: 24),
          ],
          _RewardTile(
            title: 'サンクスカード',
            requirement: '公式アプリに記録された交換状況',
            redeemedAt: card.thanksCardRedeemedAt,
          ),
        ],
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({required this.title, required this.requirement, required this.redeemedAt, this.available = false});

  final String title;
  final String requirement;
  final DateTime? redeemedAt;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final time = redeemedAt;
    final status = time != null
        ? '交換済み'
        : available
        ? '交換可能・未交換'
        : '未交換';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          time == null ? Icons.redeem_outlined : Icons.check_circle,
          color: time == null ? colors.outline : colors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(requirement, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                time == null ? status : '$status · ${formatHistoryTime(time)}',
                style: TextStyle(color: colors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card.outlined(
    margin: EdgeInsets.zero,
    color: Theme.of(context).colorScheme.surface,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    ),
  );
}

String formatHistoryTime(DateTime value) =>
    DateFormat('yyyy/MM/dd HH:mm').format(value.toUtc().add(const Duration(hours: 9)));
