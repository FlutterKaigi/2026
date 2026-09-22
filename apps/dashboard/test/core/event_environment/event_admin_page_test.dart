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
    expect(find.text('stg の参加者'), findsOneWidget);
    expect(find.text('123456'), findsOneWidget);
    await tester.tap(find.byKey(const Key('event-environment-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('本番').last);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.queryParameters['environment'], 'prod');
    expect(find.text('stg の参加者'), findsNothing);
    expect(find.text('prod の参加者'), findsOneWidget);
    expect(find.text('123456'), findsNothing);
    expect(find.text('654321'), findsOneWidget);
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
    expect(requests.where((request) => request['action'] == 'quizOperation').single['environment'], 'prod');
    // Reading and saving in the dialog must not initialize the default Firestore.
    expect(requests.every((request) => request['environment'] == 'prod'), isTrue);
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
