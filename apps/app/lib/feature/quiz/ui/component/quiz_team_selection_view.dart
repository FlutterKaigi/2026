import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class QuizTeamSelectionView extends HookConsumerWidget {
  const QuizTeamSelectionView({required this.event, required this.participant, super.key});
  final QuizEvent event;
  final QuizParticipant participant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context).quiz.selection;
    final choice = useState(participant.teamId);
    final submitting = useState(false);
    final error = useState<String?>(null);
    final participants = ref.watch(quizParticipantsProvider);
    final isOpen = event.teamSelectionStatus == QuizTeamSelectionStatus.open;
    useEffect(() {
      choice.value = participant.teamId;
      return null;
    }, [participant.teamId]);

    Future<void> select() async {
      final teamId = choice.value;
      if (teamId == null || submitting.value || !isOpen) {
        return;
      }
      submitting.value = true;
      error.value = null;
      try {
        await ref
            .read(quizParticipantRepositoryProvider)
            .selectTeam(
              event.id,
              teamId,
              expectedTeamId: participant.teamId,
            );
      } on FirebaseFunctionsException catch (failure) {
        if (!context.mounted) {
          return;
        }
        final details = failure.details;
        error.value = details is Map && details['reason'] == 'team-changed' ? t.changed : t.failed;
      } on Exception {
        if (context.mounted) {
          error.value = t.failed;
        }
      } finally {
        if (context.mounted) {
          submitting.value = false;
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(t.instructions),
          const SizedBox(height: 16),
          Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                participant.teamId == null ? t.unselected : t.current(team: participant.teamId!),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isOpen) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final teamId in quizTeamIds)
                  ChoiceChip(
                    label: Text(
                      participants.value == null
                          ? teamId
                          : t.option(
                              team: teamId,
                              count: '${participants.value!.where((person) => person.teamId == teamId).length}',
                            ),
                    ),
                    selected: choice.value == teamId,
                    onSelected: submitting.value ? null : (_) => choice.value = teamId,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: submitting.value || choice.value == null || choice.value == participant.teamId ? null : select,
              child: Text(submitting.value ? t.sending : t.confirm),
            ),
            Text(t.changeHint),
          ] else
            Text(participant.teamId == null ? t.closedUnselected : t.closed),
          if (error.value != null) ...[
            const SizedBox(height: 12),
            Text(error.value!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}
