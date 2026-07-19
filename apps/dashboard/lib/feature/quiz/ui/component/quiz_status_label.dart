import 'package:data/data.dart';
import 'package:flutter/material.dart';

/// クイズイベントの status を日本語ラベルにする。
String quizEventStatusLabel(QuizEventStatus status) => switch (status) {
  QuizEventStatus.draft => '非公開',
  QuizEventStatus.published => '公開（受付前）',
  QuizEventStatus.registration => '参加受付中',
  QuizEventStatus.entryClosed => '受付終了',
  QuizEventStatus.inProgress => '進行中',
  QuizEventStatus.finished => '終了',
};

/// 問題の status を日本語ラベルにする。
String quizQuestionStatusLabel(QuizQuestionStatus status) => switch (status) {
  QuizQuestionStatus.draft => '下書き',
  QuizQuestionStatus.open => '出題中',
  QuizQuestionStatus.closed => '締切',
  QuizQuestionStatus.revealed => '発表済み',
};

/// イベント status を表す色付き Chip。
class QuizEventStatusChip extends StatelessWidget {
  const QuizEventStatusChip({super.key, required this.status});

  final QuizEventStatus status;

  Color _color(ColorScheme scheme) => switch (status) {
    QuizEventStatus.draft => scheme.onSurfaceVariant,
    QuizEventStatus.published => scheme.tertiary,
    QuizEventStatus.registration => scheme.primary,
    QuizEventStatus.entryClosed => scheme.error,
    QuizEventStatus.inProgress => scheme.secondary,
    QuizEventStatus.finished => scheme.outline,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color(Theme.of(context).colorScheme);
    return Chip(
      label: Text(quizEventStatusLabel(status)),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
      side: BorderSide(color: color),
      backgroundColor: color.withValues(alpha: 0.08),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// 問題 status を表す色付き Chip。
class QuizQuestionStatusChip extends StatelessWidget {
  const QuizQuestionStatusChip({super.key, required this.status});

  final QuizQuestionStatus status;

  Color _color(ColorScheme scheme) => switch (status) {
    QuizQuestionStatus.draft => scheme.outline,
    QuizQuestionStatus.open => scheme.primary,
    QuizQuestionStatus.closed => scheme.tertiary,
    QuizQuestionStatus.revealed => scheme.secondary,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color(Theme.of(context).colorScheme);
    return Chip(
      label: Text(quizQuestionStatusLabel(status)),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
      side: BorderSide(color: color),
      backgroundColor: color.withValues(alpha: 0.08),
      visualDensity: VisualDensity.compact,
    );
  }
}
