import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/core/env.dart';
import 'package:dashboard/core/event_environment/event_admin_client.dart';
import 'package:dashboard/core/event_environment/event_environment.dart';
import 'package:dashboard/core/router/router.dart';
import 'package:dashboard/feature/auth/data/provider/auth_repository.dart';
import 'package:data/data.dart';
import 'package:data/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Harness copied from apps/dashboard/test/core/event_environment/event_admin_page_test.dart:
// real router, EventAdminPage, EventAdminClient, admin repositories and pages;
// only the eventAdministration callable is replaced.
void main() {
  final serverNow = DateTime.utc(2026, 11, 13, 6, 45);
  late _Auth auth;
  late List<String> actions;
  Completer<void>? clockGate;
  Completer<Map<String, dynamic>>? operationGate;
  var failNextRead = false;
  var failEveryRead = false;
  Map<String, dynamic>? eventOverride;

  setUp(() {
    auth = _Auth();
    actions = [];
    clockGate = null;
    operationGate = null;
    failNextRead = false;
    failEveryRead = false;
    eventOverride = null;
  });
  tearDown(() => auth.changes.close());

  const event = {
    'id': 'ev',
    'title': {'ja': '本番クイズ', 'en': 'Quiz'},
    'status': 'inProgress',
    'teamSelectionStatus': 'closed',
    'isPublic': true,
    'currentQuestionId': 'q1',
    'createdAt': '2026-11-01T00:00:00Z',
    'updatedAt': '2026-11-01T00:00:00Z',
  };
  final question = {
    'id': 'q1',
    'sponsorId': 'sponsor',
    'order': 1,
    'title': {'ja': '第1問の本文', 'en': 'Question 1'},
    'options': [
      {'ja': 'Dart', 'en': 'Dart'},
      {'ja': 'Kotlin', 'en': 'Kotlin'},
    ],
    'durationSeconds': 90,
    'status': 'open',
    'closesAt': serverNow.add(const Duration(seconds: 90)).toIso8601String(),
  };
  const teams = [
    {
      'id': 'A',
      'tableNumber': 1,
      'name': 'A',
      'memberUids': ['u1'],
      'members': [
        {'uid': 'u1', 'displayName': '参加者1'},
      ],
      'score': 0,
    },
  ];

  Future<Map<String, dynamic>> request(Map<String, dynamic> value) async {
    final action = value['action'] as String;
    actions.add(action);
    switch (action) {
      case 'read':
        if (failNextRead || failEveryRead) {
          failNextRead = false;
          throw FirebaseFunctionsException(code: 'unavailable', message: 'one lost poll');
        }
        return switch ((value['payload'] as Map)['view']) {
          'quizProjection' => {
            'event': eventOverride ?? event,
            'teams': teams,
            'participants': [],
            'question': question,
            'checkInCode': null,
          },
          _ => {
            'event': eventOverride ?? event,
            'teams': teams,
            'participants': [],
            'questions': [question],
            'answers': [],
            'sponsors': [],
            'checkInCode': null,
          },
        };
      case 'clock':
        if (clockGate case final gate?) {
          clockGate = null;
          await gate.future;
        }
        return {'serverNowMs': serverNow.millisecondsSinceEpoch};
      case 'withdrawQuizPromotion':
      case 'quizOperation':
        return operationGate!.future;
      default:
        return {};
    }
  }

  Future<void> show(WidgetTester tester, String location) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(
      overrides: [
        dashboardFlavorProvider.overrideWithValue(Flavor.stg),
        authRepositoryProvider.overrideWithValue(auth),
        eventAdminRequestProvider.overrideWithValue(request),
      ],
    );
    final router = container.read(routerProvider)..go(location);
    addTearDown(() {
      router.dispose();
      container.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(builder: (_, ref, _) => MaterialApp.router(routerConfig: ref.watch(routerProvider))),
      ),
    );
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump();
    }
  }

  Future<void> startClose(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(OutlinedButton, '締切'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '実行'));
    await tester.pump();
    expect(find.text('締切 を実行中…'), findsOneWidget);
  }

  testWidgets('control: an unconfirmed close shows the ambiguous-result banner', (tester) async {
    await show(tester, '/quiz/ev?environment=prod');
    operationGate = Completer<Map<String, dynamic>>();
    await startClose(tester);
    operationGate!.completeError(FirebaseFunctionsException(code: 'deadline-exceeded', message: 'timeout'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('締切 の完了を確認できませんでした'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a failed poll preserves the pending operation and its later failure warning', (tester) async {
    await show(tester, '/quiz/ev?environment=prod');
    operationGate = Completer<Map<String, dynamic>>();
    await startClose(tester);

    failNextRead = true;
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('第1問の本文'), findsNothing, reason: 'console body is replaced while the poll error is pending');
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('第1問の本文'), findsOneWidget);
    expect(find.text('締切 を実行中…'), findsOneWidget, reason: 'operation is still in flight');
    expect(
      tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '締切')).onPressed,
      isNull,
      reason: 'controls stay locked while the first close is unresolved',
    );

    operationGate!.completeError(FirebaseFunctionsException(code: 'deadline-exceeded', message: 'timeout'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('の完了を確認できませんでした'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('operation progress and failure remain visible while reads keep failing', (tester) async {
    await show(tester, '/quiz/ev?environment=prod');
    operationGate = Completer<Map<String, dynamic>>();
    await startClose(tester);
    failEveryRead = true;
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('第1問の本文'), findsNothing);
    expect(find.text('締切 を実行中…'), findsOneWidget);
    operationGate!.completeError(FirebaseFunctionsException(code: 'deadline-exceeded', message: 'timeout'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('締切 の完了を確認できませんでした'), findsOneWidget);
    expect(find.text('第1問の本文'), findsNothing, reason: 'failed reads must not restore the console body');
    failEveryRead = false;
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.textContaining('締切 の完了を確認できませんでした'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('promotion withdrawal survives a polling failure and shares the operation lock', (tester) async {
    eventOverride = {
      ...event,
      'status': 'published',
      'currentQuestionId': null,
      'promotion': {'sourceEventId': 'source'},
    };
    await show(tester, '/quiz/ev?environment=prod');
    operationGate = Completer<Map<String, dynamic>>();
    await tester.tap(find.widgetWithText(OutlinedButton, '反映を取り消す'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '反映を取り消す'));
    await tester.pump();
    failNextRead = true;
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('反映取消 を実行中…'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '反映を取り消す')).onPressed, isNull);
    operationGate!.completeError(FirebaseFunctionsException(code: 'deadline-exceeded', message: 'timeout'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('反映取消 の完了を確認できませんでした'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

class _Auth extends Fake implements AuthRepository {
  User? user = _User();
  final changes = StreamController<User?>.broadcast();
  @override
  Stream<User?> authStateChanges() async* {
    yield user;
    yield* changes.stream;
  }
}

class _User extends Fake implements User {
  @override
  String get uid => 'same-admin';
  @override
  String get email => 'admin@flutterkaigi.jp';
  @override
  String? get photoURL => null;
}
