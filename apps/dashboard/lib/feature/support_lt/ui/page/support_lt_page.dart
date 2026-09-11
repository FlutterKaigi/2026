import 'package:dashboard/core/extension/date_time_extension.dart';
import 'package:dashboard/feature/auth/data/provider/auth_state.dart';
import 'package:dashboard/feature/support_lt/data/provider/support_lt_state.dart';
import 'package:dashboard/feature/support_lt/ui/widget/support_lt_code_card.dart';
import 'package:dashboard/feature/support_lt/ui/widget/support_lt_load_error.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SupportLtPage extends ConsumerWidget {
  const SupportLtPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    if (auth.isLoading) return const Center(child: CircularProgressIndicator());
    final uid = auth.asData?.value?.uid;
    if (uid == null) return const Center(child: Text('参加登録の管理にはサインインが必要です。'));

    return ListView(
      key: ValueKey(uid),
      padding: const EdgeInsets.all(24),
      children: [
        Text('応援LT', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('参加者に登録コードを案内し、アプリのアカウントページから参加登録してもらってください。'),
        const SizedBox(height: 24),
        const SupportLtCodeCard(),
        const SizedBox(height: 16),
        const _RegistrationsCard(),
      ],
    );
  }
}

class _RegistrationsCard extends ConsumerWidget {
  const _RegistrationsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrations = ref.watch(supportLtRegistrationsProvider);
    final count = registrations.hasValue && !registrations.isLoading ? registrations.requireValue.length : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(count == null ? '参加者' : '参加者 $count人', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('参加人数と一覧は登録状況に合わせて自動更新されます。'),
            const SizedBox(height: 16),
            registrations.when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SupportLtLoadError(
                message: supportLtErrorMessage(error, fallback: '参加者を読み込めませんでした。通信状況を確認して再試行してください。'),
                retryKey: const Key('retry-support-lt-registrations'),
                onRetry: () => ref.invalidate(supportLtRegistrationsProvider),
              ),
              data: (items) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (items.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('まだ参加登録はありません'))
                  else
                    for (final item in items) ...[
                      const Divider(height: 1),
                      _RegistrationItem(registration: item),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationItem extends StatelessWidget {
  const _RegistrationItem({required this.registration});

  final SupportLtRegistration registration;

  @override
  Widget build(BuildContext context) {
    final displayName = registration.displayName.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(displayName.isEmpty ? '表示名未設定' : displayName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          SelectableText('UID: ${registration.uid}'),
          const SizedBox(height: 4),
          Text('登録日時: ${registration.registeredAt.toLocal().formatDateTime()}'),
        ],
      ),
    );
  }
}
