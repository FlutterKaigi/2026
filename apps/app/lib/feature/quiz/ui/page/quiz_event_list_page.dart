import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/auth/ui/widget/centered_sign_in_card.dart';
import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/ui/component/quiz_motion.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// クイズイベントの一覧ページ。
///
/// 前半戦・後半戦などのイベントを状態チップつきで並べる。参加できるか
/// どうか（開催準備中 / 参加受付中 / 参加受付終了 / 進行中 / 結果発表）は
/// イベント側の status に連動し、行をタップすると各イベントのページで
/// 状態に応じた画面が出る。
class QuizEventListPage extends ConsumerWidget {
  const QuizEventListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final user = ref.watch(quizUserProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.quiz.title)),
      // 入口はサインイン後の会場イベントの画面にあるが、ディープリンクや途中での
      // サインアウトでも未ログインのまま開かれうるので、この画面でサインインできるようにする。
      body: switch (user) {
        AsyncError() => Center(child: Text(t.quiz.errors.signInFailed)),
        AsyncLoading() => const Center(child: CircularProgressIndicator.adaptive()),
        AsyncData(:final value) when value == null => CenteredSignInCard(
          title: t.auth.signIn.required,
          description: t.quiz.signInRequired.inPage,
        ),
        AsyncData() =>
          ref
              .watch(quizEventsProvider)
              .when(
                loading: () => const Center(child: CircularProgressIndicator.adaptive()),
                error: (_, _) => Center(child: Text(t.quiz.list.error)),
                data: (events) => events.isEmpty
                    ? Center(child: Text(t.quiz.list.empty))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: events.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return Entrance(
                            delay: Duration(milliseconds: index * 60),
                            child: _QuizEventTile(event: event),
                          );
                        },
                      ),
              ),
      },
    );
  }
}

class _QuizEventTile extends StatelessWidget {
  const _QuizEventTile({required this.event});

  final QuizEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);

    return Card.filled(
      color: theme.colorScheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: const Icon(Icons.quiz_outlined),
        ),
        title: Text(
          event.title.resolve(locale),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _StatusChip(status: event.status),
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => QuizRoute(event.id).push<void>(context),
      ),
    );
  }
}

/// 参加者向けの状態チップ。運営用語ではなく参加可否が伝わる表現にする。
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final QuizEventStatus status;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      // draft は watchPublished で除外されるため一覧には現れないが、
      // 分岐としては準備中と同じ見せ方にしておく。
      QuizEventStatus.draft || QuizEventStatus.published => (
        t.quiz.list.status.preparing,
        scheme.onSurfaceVariant,
      ),
      QuizEventStatus.registration => (t.quiz.list.status.registration, scheme.primary),
      // 受付終了はエラーではなく、進行中（secondary）とも見分けられるよう中立の灰色にする。
      QuizEventStatus.entryClosed => (t.quiz.list.status.entryClosed, scheme.outline),
      QuizEventStatus.inProgress => (t.quiz.list.status.inProgress, scheme.secondary),
      QuizEventStatus.finished => (t.quiz.list.status.finished, scheme.tertiary),
    };
    // outline は文字には薄い（ライトテーマで約3.6:1）ため、受付終了は文字だけ onSurfaceVariant にする。
    final textColor = status == QuizEventStatus.entryClosed ? scheme.onSurfaceVariant : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
