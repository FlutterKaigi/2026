import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/core/attendee_app_origin.dart';
import 'package:dashboard/core/env.dart';
import 'package:dashboard/core/event_environment/event_admin_client.dart';
import 'package:dashboard/core/event_environment/event_environment.dart';
import 'package:dashboard/core/router/router.dart';
import 'package:dashboard/feature/auth/data/provider/auth_repository.dart';
import 'package:dashboard/feature/support_lt/ui/widget/support_lt_code_card.dart';
import 'package:data/data.dart';
import 'package:data/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  late List<Map<String, dynamic>> requests;
  late _Auth auth;

  setUp(() {
    requests = [];
    auth = _Auth();
  });
  tearDown(() => auth.changes.close());

  Map<String, dynamic> snapshot(Map<String, dynamic> request) {
    final environment = request['environment'];
    final payload = request['payload'] as Map<String, dynamic>;
    final event = {
      'id': 'same-id',
      'title': {'ja': '$environment のクイズ', 'en': 'Quiz'},
      'status': 'draft',
      'createdAt': '2026-09-22T00:00:00Z',
      'updatedAt': '2026-09-22T00:00:00Z',
    };
    return switch (payload['view']) {
      'supportLt' => {
        'code': {'code': environment == 'prod' ? '654321' : '123456', 'issuedAt': '2026-09-22T00:00:00Z'},
        'registrations': [
          {'id': 'person', 'displayName': '$environment の参加者', 'registeredAt': '2026-09-22T00:00:00Z'},
        ],
      },
      'quizEvents' => {
        'events': [event],
        'sponsors': [],
      },
      'quizConsole' => {
        'event': event,
        'participants': [],
        'teams': [],
        'questions': [],
        'answers': [],
        'sponsors': [],
        'entryCode': '123456',
      },
      'quizProjection' => {'event': event, 'teams': [], 'question': null},
      'quizQuestion' => {'event': event, 'sponsors': [], 'question': null, 'secret': null},
      _ => {},
    };
  }

  Future<(ProviderContainer, GoRouter)> show(
    WidgetTester tester,
    String location, {
    EventAdminRequest? request,
    bool settle = true,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(
      overrides: [
        dashboardFlavorProvider.overrideWithValue(Flavor.stg),
        authRepositoryProvider.overrideWithValue(auth),
        eventAdminRequestProvider.overrideWithValue(
          request ??
              (value) async {
                requests.add(value);
                return switch (value['action']) {
                  'read' => snapshot(value),
                  'quizOperation' => {'code': '112233'},
                  _ => {},
                };
              },
        ),
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
        child: Consumer(
          builder: (_, ref, _) => MaterialApp.router(routerConfig: ref.watch(routerProvider)),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump();
    }
    return (container, router);
  }

  testWidgets('switches reads and writes without signing in again and discards old data', (tester) async {
    final (_, router) = await show(tester, '/support-lt?environment=stg');
    // The QR code must open the attendee app of the operated environment, not
    // of the environment this dashboard build signs in to.
    String? qrOrigin() =>
        ProviderScope.containerOf(tester.element(find.byType(SupportLtCodeCard))).read(attendeeAppOriginProvider);
    expect(find.text('stg の参加者'), findsOneWidget);
    expect(find.text('123456'), findsOneWidget);
    expect(qrOrigin(), stagingAppOrigin);
    await tester.tap(find.byKey(const Key('event-environment-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('本番').last);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.queryParameters['environment'], 'prod');
    expect(find.text('stg の参加者'), findsNothing);
    expect(find.text('prod の参加者'), findsOneWidget);
    expect(find.text('123456'), findsNothing);
    expect(find.text('654321'), findsOneWidget);
    expect(qrOrigin(), productionAppOrigin);
    await tester.tap(find.text('コードを再発行'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('再発行する'));
    await tester.pumpAndSettle();
    expect(requests.where((value) => value['action'] == 'issueSupportLtCode').single['environment'], 'prod');
    expect(auth.signIns, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('quiz navigation and projection retain the chosen environment', (tester) async {
    final (_, router) = await show(tester, '/quiz?environment=prod');
    await tester.tap(find.text('prod のクイズ'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.toString(), '/quiz/same-id?environment=prod');
    await tester.tap(find.text('投影画面'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.toString(), '/quiz/same-id/project?environment=prod');
    expect(find.text('表示環境: 本番'), findsOneWidget);
    expect(
      requests.where((request) => (request['payload'] as Map)['view'] == 'quizProjection').single['environment'],
      'prod',
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('event creation dialog uses the selected environment repositories', (tester) async {
    await show(tester, '/quiz?environment=prod');
    await tester.tap(find.byTooltip('クイズイベントを新規作成'));
    await tester.pumpAndSettle();
    expect(find.text('クイズイベント新規作成'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.widgetWithText(TextFormField, 'タイトル（日本語）*'), '本番の大会');
    await tester.enterText(find.widgetWithText(TextFormField, 'タイトル（英語）*'), 'Production quiz');
    await tester.tap(find.widgetWithText(FilledButton, '作成'));
    await tester.pumpAndSettle();
    expect(requests.where((request) => request['action'] == 'saveEvent').single['environment'], 'prod');
    expect(requests.where((request) => request['action'] == 'quizOperation'), isEmpty);
    // Reading and saving in the dialog must not initialize the default Firestore.
    expect(requests.every((request) => request['environment'] == 'prod'), isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cancelling event deletion leaves the selected event unchanged', (tester) async {
    await show(tester, '/quiz?environment=prod');
    await tester.tap(find.byKey(const ValueKey('delete-quiz-event-same-id')));
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    expect(find.text('イベントを削除'), findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.textContaining('本番')), findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.textContaining('prod のクイズ')), findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.textContaining('問題')), findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.textContaining('元に戻せません')), findsOneWidget);
    expect(requests.where((request) => request['action'] == 'deleteEvent'), isEmpty);
    await tester.tap(find.widgetWithText(TextButton, 'キャンセル'));
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    expect(find.text('prod のクイズ'), findsOneWidget);
    expect(requests.where((request) => request['action'] == 'deleteEvent'), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('confirmed event deletion uses the selected environment and refreshes the list', (tester) async {
    var deleted = false;
    await show(
      tester,
      '/quiz?environment=prod',
      request: (request) async {
        requests.add(request);
        if (request['action'] == 'deleteEvent') {
          deleted = true;
          return {};
        }
        final data = snapshot(request);
        if (deleted) data['events'] = [];
        return data;
      },
    );
    await tester.tap(find.byTooltip('イベントを削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '削除する'));
    await tester.pumpAndSettle();
    final deletion = requests.singleWhere((request) => request['action'] == 'deleteEvent');
    expect(deletion['environment'], 'prod');
    expect(deletion['payload'], {'eventId': 'same-id'});
    expect(requests.every((request) => request['environment'] == 'prod'), isTrue);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('prod のクイズ'), findsNothing);
    expect(find.text('クイズイベントがありません'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('private events expose deletion regardless of lifecycle or registration history', (tester) async {
    await show(
      tester,
      '/quiz?environment=stg',
      request: (request) async {
        requests.add(request);
        final data = snapshot(request);
        final event = (data['events'] as List).single as Map<String, dynamic>;
        data['events'] = [
          for (final status in QuizEventStatus.values) {...event, 'id': status.name, 'status': status.name},
          {...event, 'id': 'public-draft', 'isPublic': true},
          {...event, 'id': 'registration-preserved-draft', 'admissionSlotsReady': true},
        ];
        return data;
      },
    );
    expect(find.byKey(const ValueKey('delete-quiz-event-draft')), findsOneWidget);
    expect(find.byTooltip('イベントを削除'), findsNWidgets(QuizEventStatus.values.length + 1));
    for (final status in QuizEventStatus.values) {
      expect(find.byKey(ValueKey('delete-quiz-event-${status.name}')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('delete-quiz-event-public-draft')), findsNothing);
    expect(find.byKey(const ValueKey('delete-quiz-event-registration-preserved-draft')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('failed deletion stays retryable even when the refreshed event is absent', (tester) async {
    var attempts = 0;
    await show(
      tester,
      '/quiz?environment=prod',
      request: (request) async {
        requests.add(request);
        if (request['action'] == 'deleteEvent') {
          if (attempts++ == 0) throw FirebaseFunctionsException(code: 'unavailable', message: 'network error');
          return {};
        }
        final data = snapshot(request);
        if (attempts > 0) data['events'] = [];
        return data;
      },
    );
    await tester.tap(find.byTooltip('イベントを削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '削除する'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('削除できませんでした:'), findsOneWidget);
    expect(find.textContaining('network error'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, '削除する')).onPressed, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, '削除する'));
    await tester.pumpAndSettle();
    final deletions = requests.where((request) => request['action'] == 'deleteEvent').toList();
    expect(deletions, hasLength(2));
    expect(deletions.first, deletions.last);
    expect(deletions.last['environment'], 'prod');
    expect(deletions.last['payload'], {'eventId': 'same-id'});
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('クイズイベントがありません'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('pending deletion disables confirmation, cancellation, and other deletion buttons', (tester) async {
    final pending = Completer<Map<String, dynamic>>();
    var deleted = false;
    await show(
      tester,
      '/quiz?environment=prod',
      request: (request) async {
        requests.add(request);
        if (request['action'] == 'deleteEvent') {
          final result = await pending.future;
          deleted = true;
          return result;
        }
        final data = snapshot(request);
        final event = (data['events'] as List).single as Map<String, dynamic>;
        data['events'] = [
          if (!deleted) event,
          {...event, 'id': 'another-draft'},
        ];
        return data;
      },
    );
    await tester.tap(find.byKey(const ValueKey('delete-quiz-event-same-id')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '削除する'));
    await tester.pump();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, '削除中…')).onPressed, isNull);
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'キャンセル')).onPressed, isNull);
    expect(
      tester.widget<IconButton>(find.byKey(const ValueKey('delete-quiz-event-another-draft'))).onPressed,
      isNull,
    );
    await tester.tap(find.widgetWithText(FilledButton, '削除中…'));
    await tester.pump();
    expect(requests.where((request) => request['action'] == 'deleteEvent'), hasLength(1));
    pending.complete({});
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byKey(const ValueKey('delete-quiz-event-same-id')), findsNothing);
    expect(
      tester.widget<IconButton>(find.byKey(const ValueKey('delete-quiz-event-another-draft'))).onPressed,
      isNotNull,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an incomplete deletion can be retried after reloading the event list', (tester) async {
    var deleted = false;
    final (_, router) = await show(
      tester,
      '/quiz?environment=prod',
      request: (request) async {
        requests.add(request);
        if (request['action'] == 'deleteEvent') {
          deleted = true;
          return {};
        }
        final data = snapshot(request);
        final event = (data['events'] as List).single as Map<String, dynamic>;
        data['events'] = [
          if (!deleted) {...event, 'deletionPending': true},
        ];
        return data;
      },
    );
    expect(find.text('削除が完了していません。削除を再試行してください。'), findsOneWidget);
    await tester.tap(find.text('prod のクイズ'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.toString(), '/quiz?environment=prod');
    await tester.tap(find.byKey(const ValueKey('delete-quiz-event-same-id')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '削除する'));
    await tester.pumpAndSettle();
    final deletion = requests.singleWhere((request) => request['action'] == 'deleteEvent');
    expect(deletion['environment'], 'prod');
    expect(deletion['payload'], {'eventId': 'same-id'});
    expect(find.text('削除が完了していません。削除を再試行してください。'), findsNothing);
    expect(find.text('クイズイベントがありません'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  for (final initialStatus in ['registration', 'entryClosed']) {
    testWidgets('hiding $initialStatus in production preserves attendees and requires reopening registration', (
      tester,
    ) async {
      var status = initialStatus;
      await show(
        tester,
        '/quiz/same-id?environment=prod',
        request: (request) async {
          requests.add(request);
          if (request['action'] == 'quizOperation') {
            status = switch ((request['payload'] as Map)['operation']) {
              'unpublish' => 'draft',
              'publish' => 'published',
              _ => status,
            };
            return {};
          }
          final data = snapshot(request);
          data['event'] = {...data['event'] as Map<String, dynamic>, 'status': status, 'isPublic': status != 'draft'};
          data['participants'] = [
            {'id': 'registered-person', 'displayName': '登録済みの参加者', 'registeredAt': '2026-09-22T00:00:00Z'},
          ];
          return data;
        },
      );
      await tester.tap(find.widgetWithText(OutlinedButton, '受付を停止して非公開'));
      await tester.pumpAndSettle();
      expect(requests.where((request) => request['action'] == 'quizOperation'), isEmpty);
      await tester.tap(find.widgetWithText(FilledButton, '実行'));
      await tester.pumpAndSettle();
      expect(find.text('参加者数: 1 / 80 人'), findsOneWidget);
      expect(find.text('受付を停止して非公開'), findsNothing);
      expect(find.text('参加登録を開始'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, '公開する'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '実行'));
      await tester.pumpAndSettle();
      expect(find.text('参加者数: 1 / 80 人'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '参加登録を開始'), findsOneWidget);
      expect(find.text('受付を停止して非公開'), findsNothing);
      final operations = requests.where((request) => request['action'] == 'quizOperation').toList();
      expect(operations.map((request) => (request['payload'] as Map)['operation']), ['unpublish', 'publish']);
      expect(operations.every((request) => request['environment'] == 'prod'), isTrue);
      expect(operations.every((request) => (request['payload'] as Map)['eventId'] == 'same-id'), isTrue);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('admin participant details identify attendees without displaying raw IDs', (tester) async {
    await show(
      tester,
      '/quiz/same-id?environment=prod',
      request: (request) async {
        requests.add(request);
        if (request['action'] != 'read') return {};
        final data = snapshot(request);
        data['event'] = {...data['event'] as Map<String, dynamic>, 'status': 'registration', 'isPublic': true};
        data['participants'] = [
          for (final (id, displayName) in [
            ('resolved-account-uid', null),
            ('nickname-uid', 'ニックネーム'),
            ('email-only-uid', ''),
            ('unknown-uid', 123),
          ])
            {'id': id, 'displayName': ?displayName, 'registeredAt': '2026-09-22T00:00:00Z'},
        ];
        data['participantAccounts'] = [
          {
            'id': 'resolved-account-uid',
            'displayName': '鈴木 太郎',
            'accountName': 'Google 鈴木',
            'email': 'taro@example.test',
          },
          {
            'id': 'nickname-uid',
            'displayName': 'ニックネーム',
            'accountName': '花子',
            'email': 'hanako@example.test',
          },
          {'id': 'email-only-uid', 'displayName': '参加者', 'accountName': null, 'email': 'email@example.test'},
        ];
        return data;
      },
    );
    final roster = find.text('参加者の確認・取消（4 人）');
    await tester.ensureVisible(roster);
    await tester.tap(roster);
    await tester.pumpAndSettle();
    expect(find.text('鈴木 太郎'), findsOneWidget);
    expect(find.text('ニックネーム'), findsOneWidget);
    expect(find.text('email@example.test'), findsOneWidget);
    expect(find.text('名前未登録'), findsOneWidget);
    expect(find.textContaining('アカウント: Google 鈴木'), findsOneWidget);
    expect(find.textContaining('taro@example.test'), findsOneWidget);
    expect(find.textContaining('アカウント: 花子'), findsOneWidget);
    expect(find.textContaining('hanako@example.test'), findsOneWidget);
    expect(find.textContaining('-uid'), findsNothing);
    expect(find.byTooltip('参加者ID: resolved-account-uid'), findsOneWidget);
    final row = find.ancestor(of: find.text('鈴木 太郎'), matching: find.byType(ListTile));
    final cancel = find.descendant(of: row, matching: find.widgetWithText(TextButton, '取消'));
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    expect(find.descendant(of: dialog, matching: find.textContaining('鈴木 太郎')), findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.textContaining('taro@example.test')), findsOneWidget);
    expect(requests.where((request) => request['action'] == 'quizOperation'), isEmpty);
    await tester.tap(find.widgetWithText(FilledButton, '実行'));
    await tester.pumpAndSettle();
    final cancellation = requests.singleWhere((request) => request['action'] == 'quizOperation');
    expect(cancellation['environment'], 'prod');
    expect(cancellation['payload'], containsPair('operation', 'removeParticipant'));
    expect(cancellation['payload'], containsPair('eventId', 'same-id'));
    expect(cancellation['payload'], containsPair('uid', 'resolved-account-uid'));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('console deletion can be cancelled and excludes other operations while confirming', (tester) async {
    final (_, router) = await show(tester, '/quiz/same-id?environment=prod');
    final deletion = find.byKey(const ValueKey('delete-quiz-event-same-id'));
    await tester.tap(deletion);
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    expect(find.descendant(of: dialog, matching: find.text('イベントを削除')), findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.textContaining('本番')), findsOneWidget);
    for (final relatedData in ['参加者', 'チーム', '問題', '正解', '回答', '元に戻せません']) {
      expect(find.descendant(of: dialog, matching: find.textContaining(relatedData)), findsOneWidget);
    }
    expect(tester.widget<OutlinedButton>(deletion).onPressed, isNull);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, '公開する')).onPressed, isNull);
    expect(requests.where((request) => request['action'] != 'read'), isEmpty);
    await tester.tap(find.widgetWithText(TextButton, 'キャンセル'));
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    expect(tester.widget<OutlinedButton>(deletion).onPressed, isNotNull);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, '公開する')).onPressed, isNotNull);
    expect(requests.where((request) => request['action'] == 'deleteEvent'), isEmpty);
    expect(router.routeInformationProvider.value.uri.toString(), '/quiz/same-id?environment=prod');
    await tester.pumpWidget(const SizedBox());
  });

  for (final (environment, status) in [('stg', 'finished'), ('prod', 'inProgress')]) {
    testWidgets('console deletes a private $status event with attendees and returns to $environment', (tester) async {
      var deleted = false;
      final (_, router) = await show(
        tester,
        '/quiz/same-id?environment=$environment',
        request: (request) async {
          requests.add(request);
          if (request['action'] == 'deleteEvent') {
            deleted = true;
            return {};
          }
          final data = snapshot(request);
          if (data.containsKey('events')) data['events'] = [];
          if (data.containsKey('event')) {
            data['event'] = deleted
                ? null
                : {
                    ...data['event'] as Map<String, dynamic>,
                    'status': status,
                    'isPublic': false,
                    'admissionSlotsReady': true,
                    'currentQuestionId': 'asked-question',
                  };
            data['participants'] = [
              {'id': 'registered-person', 'displayName': '参加登録済み', 'registeredAt': '2026-09-22T00:00:00Z'},
            ];
            data['questions'] = [
              {
                'id': 'asked-question',
                'sponsorId': 'sponsor',
                'order': 1,
                'title': {'ja': '出題済みの問題', 'en': 'Asked question'},
                'options': [
                  {'ja': '正解', 'en': 'Correct'},
                  {'ja': '不正解', 'en': 'Wrong'},
                ],
                'status': 'revealed',
              },
            ];
          }
          return data;
        },
      );
      expect(find.text('参加者数: 1 / 80 人'), findsOneWidget);
      expect(find.text('出題済みの問題'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('delete-quiz-event-same-id')));
      await tester.pumpAndSettle();
      expect(requests.where((request) => request['action'] == 'deleteEvent'), isEmpty);
      await tester.tap(find.widgetWithText(FilledButton, '削除する'));
      await tester.pumpAndSettle();
      final deletion = requests.singleWhere((request) => request['action'] == 'deleteEvent');
      expect(deletion['environment'], environment);
      expect(deletion['payload'], {'eventId': 'same-id'});
      expect(router.routeInformationProvider.value.uri.toString(), '/quiz?environment=$environment');
      expect(find.text('クイズイベントがありません'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('console deletion is unavailable until the event is loaded and while it is public', (tester) async {
    final pending = Completer<Map<String, dynamic>>();
    await show(
      tester,
      '/quiz/same-id?environment=prod',
      settle: false,
      request: (request) async {
        requests.add(request);
        return pending.future;
      },
    );
    final deletion = find.byKey(const ValueKey('delete-quiz-event-same-id'));
    expect(deletion, findsNothing);
    pending.complete({
      ...snapshot({
        'environment': 'prod',
        'payload': {'view': 'quizConsole'},
      }),
      'event': {
        'id': 'same-id',
        'title': {'ja': '公開中のクイズ', 'en': 'Public quiz'},
        'status': 'draft',
        'isPublic': true,
        'createdAt': '2026-09-22T00:00:00Z',
        'updatedAt': '2026-09-22T00:00:00Z',
      },
    });
    await tester.pumpAndSettle();
    expect(tester.widget<OutlinedButton>(deletion).onPressed, isNull);
    expect(find.text('削除するには非公開にしてください'), findsOneWidget);
    expect(requests.where((request) => request['action'] == 'deleteEvent'), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('console deletion retries the same event after its parent disappears', (tester) async {
    var attempts = 0;
    final (_, router) = await show(
      tester,
      '/quiz/same-id?environment=stg',
      request: (request) async {
        requests.add(request);
        if (request['action'] == 'deleteEvent') {
          if (attempts++ == 0) throw FirebaseFunctionsException(code: 'unavailable', message: 'network error');
          return {};
        }
        final data = snapshot(request);
        if (attempts > 0) {
          data['event'] = null;
          data['events'] = [];
        }
        return data;
      },
    );
    await tester.tap(find.byKey(const ValueKey('delete-quiz-event-same-id')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '削除する'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('削除できませんでした:'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.toString(), '/quiz/same-id?environment=stg');
    await tester.tap(find.widgetWithText(FilledButton, '削除する'));
    await tester.pumpAndSettle();
    final deletions = requests.where((request) => request['action'] == 'deleteEvent').toList();
    expect(deletions, hasLength(2));
    expect(deletions.first, deletions.last);
    expect(deletions.last['environment'], 'stg');
    expect(deletions.last['payload'], {'eventId': 'same-id'});
    expect(router.routeInformationProvider.value.uri.toString(), '/quiz?environment=stg');
    expect(find.text('クイズイベントがありません'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an existing console operation blocks deletion until it completes', (tester) async {
    final pending = Completer<Map<String, dynamic>>();
    await show(
      tester,
      '/quiz/same-id?environment=prod',
      request: (request) async {
        requests.add(request);
        return request['action'] == 'quizOperation' ? pending.future : snapshot(request);
      },
    );
    await tester.tap(find.widgetWithText(FilledButton, '公開する'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '実行'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final deletion = find.byKey(const ValueKey('delete-quiz-event-same-id'));
    expect(tester.widget<OutlinedButton>(deletion).onPressed, isNull);
    await tester.tap(deletion);
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
    expect(requests.where((request) => request['action'] == 'deleteEvent'), isEmpty);
    pending.complete({});
    await tester.pumpAndSettle();
    expect(tester.widget<OutlinedButton>(deletion).onPressed, isNotNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a late response from the previous environment cannot restore its participants', (tester) async {
    final pending = Completer<Map<String, dynamic>>();
    final (_, router) = await show(
      tester,
      '/support-lt?environment=stg',
      settle: false,
      request: (request) async {
        requests.add(request);
        return request['environment'] == 'stg' ? pending.future : snapshot(request);
      },
    );
    // The initial response is still pending; switching is available while loading.
    router.go('/support-lt?environment=prod');
    await tester.pumpAndSettle();
    pending.complete(
      snapshot({
        'environment': 'stg',
        'payload': {'view': 'supportLt'},
      }),
    );
    await tester.pumpAndSettle();
    expect(find.text('stg の参加者'), findsNothing);
    expect(find.text('prod の参加者'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reviews one STG event, retries the same promotion, and withdraws its production copy', (tester) async {
    var attempts = 0;
    final (_, router) = await show(
      tester,
      '/quiz/same-id?environment=stg',
      request: (request) async {
        requests.add(request);
        switch (request['action']) {
          case 'previewQuizPromotion':
            return {
              'revision': 'reviewed-version',
              'title': {'ja': '反映する大会'},
              'capacity': 80,
              'questionCount': 1,
              'sponsorCount': 1,
              'questions': [
                {
                  'order': 1,
                  'title': {'ja': '動作確認済みの問題'},
                },
              ],
              'missingSponsorIds': [],
              'existingEventId': null,
            };
          case 'promoteQuizEvent':
            if (attempts++ == 0) throw FirebaseFunctionsException(code: 'unavailable', message: 'network error');
            return {'eventId': 'production-copy'};
          case 'read':
            final data = snapshot(request);
            if (request['environment'] == 'prod' && data['event'] != null) {
              data['event'] = {
                ...Map<String, dynamic>.from(data['event'] as Map),
                'id': 'production-copy',
                'promotion': {'sourceEventId': 'same-id'},
              };
            }
            return data;
          default:
            return {};
        }
      },
    );
    await tester.tap(find.text('本番へ反映'));
    await tester.pumpAndSettle();
    expect(find.text('1. 動作確認済みの問題'), findsOneWidget);
    expect(requests.where((r) => r['action'] == 'promoteQuizEvent'), isEmpty);
    await tester.tap(find.text('本番に下書きを作成'));
    await tester.pumpAndSettle();
    expect(find.textContaining('反映の完了を確認できませんでした'), findsOneWidget);
    await tester.tap(find.text('本番に下書きを作成'));
    await tester.pumpAndSettle();
    final promotions = requests.where((r) => r['action'] == 'promoteQuizEvent').toList();
    expect(promotions, hasLength(2));
    expect(promotions[0], promotions[1]);
    expect(promotions.first['environment'], 'stg');
    expect((promotions.first['payload'] as Map)['eventId'], 'same-id');
    expect((promotions.first['payload'] as Map)['revision'], 'reviewed-version');
    expect(router.routeInformationProvider.value.uri.toString(), '/quiz/production-copy?environment=prod');
    await tester.tap(find.text('反映を取り消す'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '反映を取り消す'));
    await tester.pumpAndSettle();
    final withdrawal = requests.singleWhere((r) => r['action'] == 'withdrawQuizPromotion');
    expect(withdrawal['environment'], 'prod');
    expect((withdrawal['payload'] as Map)['eventId'], 'production-copy');
    expect(router.routeInformationProvider.value.uri.toString(), '/quiz?environment=prod');
    expect(auth.signIns, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a missing production sponsor prevents promotion from the preview', (tester) async {
    await show(
      tester,
      '/quiz/same-id?environment=stg',
      request: (request) async {
        requests.add(request);
        return request['action'] == 'read'
            ? snapshot(request)
            : {
                'revision': 'reviewed-version',
                'title': {'ja': '大会'},
                'capacity': 80,
                'questionCount': 1,
                'sponsorCount': 1,
                'questions': [],
                'missingSponsorIds': ['missing-sponsor'],
                'existingEventId': null,
              };
      },
    );
    await tester.tap(find.text('本番へ反映'));
    await tester.pumpAndSettle();
    expect(find.textContaining('missing-sponsor'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, '本番に下書きを作成')).onPressed, isNull);
    expect(requests.where((r) => r['action'] == 'promoteQuizEvent'), isEmpty);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('invalid environments never reach the gateway', (tester) async {
    await show(tester, '/support-lt?environment=other-project');
    expect(find.textContaining('操作環境が不正'), findsOneWidget);
    expect(requests, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('signing out removes participant data and login restores the environment URL', (tester) async {
    final (_, router) = await show(tester, '/support-lt?environment=prod');
    await auth.signOut();
    await tester.pumpAndSettle();
    expect(find.text('prod の参加者'), findsNothing);
    expect(router.routeInformationProvider.value.uri.path, '/login');
    auth.user = _User();
    auth.changes.add(auth.user);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.toString(), '/support-lt?environment=prod');
    expect(find.text('prod の参加者'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

class _Auth extends Fake implements AuthRepository {
  User? user = _User();
  int signIns = 0;
  final changes = StreamController<User?>.broadcast();
  @override
  Stream<User?> authStateChanges() async* {
    yield user;
    yield* changes.stream;
  }

  @override
  Future<void> signOut() async {
    user = null;
    changes.add(null);
  }

  @override
  Future<void> signInWithGoogle() async {
    signIns++;
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
