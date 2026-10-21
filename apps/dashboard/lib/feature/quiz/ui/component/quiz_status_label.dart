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
  QuizQuestionStatus.reading => '読み上げ中',
  QuizQuestionStatus.open => '回答受付中',
  QuizQuestionStatus.closed => '締切',
  QuizQuestionStatus.revealed => '発表済み',
};

/// 投影画面の状態ピルの文言（出題していない間と結果発表）。管理画面のラベルとは分け、会場向けの言い方にする。
String quizProjectionEventStatusLabel(QuizEvent event) {
  if (event.status == QuizEventStatus.finished) return '結果発表';
  final beforeStart = event.status == QuizEventStatus.registration || event.status == QuizEventStatus.entryClosed;
  if (beforeStart && event.teamSelectionStatus == QuizTeamSelectionStatus.open) return 'チェックイン受付中';
  if (event.teamSelectionStatus == QuizTeamSelectionStatus.closed) return 'まもなく出題';
  return switch (event.status) {
    QuizEventStatus.draft || QuizEventStatus.published => '参加受付前',
    QuizEventStatus.registration => '参加受付中',
    QuizEventStatus.entryClosed => '参加受付終了',
    QuizEventStatus.inProgress => 'まもなく出題',
    QuizEventStatus.finished => '結果発表',
  };
}

/// 投影画面の出題中の状態ピルの文言。[expired] は回答受付中のまま締切を過ぎたかどうか。
String quizProjectionQuestionStatusLabel(QuizQuestionStatus status, {bool expired = false}) => switch (status) {
  // 投影画面は下書きの問題を表示しない。
  QuizQuestionStatus.draft => 'まもなく出題',
  QuizQuestionStatus.reading => '読み上げ中',
  QuizQuestionStatus.open => expired ? '回答締切' : '回答受付中',
  QuizQuestionStatus.closed => '回答締切',
  QuizQuestionStatus.revealed => '正解発表',
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
    QuizQuestionStatus.reading => scheme.secondary,
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
