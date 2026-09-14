import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/feature/auth/data/provider/auth_state.dart';
import 'package:dashboard/feature/support_lt/data/provider/support_lt_state.dart';
import 'package:dashboard/feature/support_lt/ui/page/support_lt_page.dart';
import 'package:data/data.dart';
import 'package:data/user.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  final issuedAt = DateTime(2099, 9, 11, 10);
  final activeCode = SupportLtCode(code: '123456', issuedAt: issuedAt);
  final nextCode = SupportLtCode(code: '654321', issuedAt: issuedAt);
  late _FakeSupportLtRepository repository;

  setUp(() => repository = _FakeSupportLtRepository(nextCode));

  tearDown(() async => repository.dispose());

  Future<void> showPage(WidgetTester tester, {Stream<User?>? authChanges}) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportLtRepositoryProvider.overrideWithValue(repository),
          authStateProvider.overrideWith((_) => authChanges ?? Stream.value(_User('admin'))),
        ],
        child: const MaterialApp(home: Scaffold(body: SupportLtPage())),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('does not fetch staff data or offer issuance while signed out', (tester) async {
    await showPage(tester, authChanges: Stream.value(null));

    expect(find.text('参加登録の管理にはサインインが必要です。'), findsOneWidget);
    expect(find.text('登録コードを発行'), findsNothing);
    expect(repository.codeWatchCount, 0);
    expect(repository.registrationsWatchCount, 0);
  });

  testWidgets('hides staff data on account change and discards the previous issuance state', (tester) async {
    final authChanges = StreamController<User?>.broadcast();
    addTearDown(authChanges.close);
    final pending = Completer<void>();
    repository.currentCode = activeCode;
    repository.registrations = [
      SupportLtRegistration(uid: 'private-attendee', displayName: '管理者限定の参加者', registeredAt: DateTime(2026)),
    ];
    repository.onIssue = (_) => pending.future;
    await showPage(tester, authChanges: authChanges.stream);
    authChanges.add(_User('admin'));
    await tester.pumpAndSettle();
    expect(find.text('123456'), findsOneWidget);
    expect(find.text('管理者限定の参加者'), findsOneWidget);

    await tester.tap(find.text('コードを再発行'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('再発行する'));
    await tester.pump();
    expect(find.text('発行中…'), findsOneWidget);

    repository.pendingReads = true;
    authChanges.add(_User('attendee'));
    await tester.pump();
    await tester.pump();

    expect(find.text('123456'), findsNothing);
    expect(find.text('管理者限定の参加者'), findsNothing);
    expect(find.text('発行中…'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
    expect(repository.codeWatchCount, 2);
    expect(repository.registrationsWatchCount, 2);

    repository.emitReadErrors(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'));
    pending.completeError(FirebaseFunctionsException(code: 'internal', message: 'private detail'));
    await tester.pumpAndSettle();

    expect(find.text('管理者権限が必要です。確認済みの flutterkaigi.jp アカウントと管理者登録を確認してください。'), findsNWidgets(2));
    expect(find.text('コードを発行できませんでした。通信状況を確認して再試行してください。'), findsNothing);
    expect(find.text('123456'), findsNothing);
    expect(find.text('管理者限定の参加者'), findsNothing);
  });

  testWidgets('shows loading while the code and registrations are pending', (tester) async {
    repository.pendingReads = true;

    await showPage(tester);

    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
    expect(find.text('登録コードを発行'), findsNothing);
    expect(find.text('参加者 0人'), findsNothing);
  });

  testWidgets('issues the first code and shows its issue time and an empty participant list', (tester) async {
    await showPage(tester);

    expect(find.text('登録コードはまだ発行されていません'), findsOneWidget);
    expect(find.text('参加者 0人'), findsOneWidget);
    expect(find.text('まだ参加登録はありません'), findsOneWidget);

    await tester.tap(find.text('登録コードを発行'));
    await tester.pumpAndSettle();

    expect(repository.issueCalls, [false]);
    expect(find.text('654321'), findsOneWidget);
    expect(find.text('発行日時: 2099/09/11 10:00'), findsOneWidget);
    expect(find.textContaining('有効期限'), findsNothing);
    expect(find.text('登録コードを発行しました'), findsOneWidget);
  });

  testWidgets('prevents duplicate issuance while the request is pending', (tester) async {
    final pending = Completer<void>();
    repository.onIssue = (_) => pending.future;
    await showPage(tester);

    await tester.tap(find.text('登録コードを発行'));
    await tester.pump();

    expect(find.text('発行中…'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    expect(repository.issueCalls, [false]);

    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('654321'), findsOneWidget);
  });

  testWidgets('requires confirmation before rotating an existing code and can cancel', (tester) async {
    repository.currentCode = activeCode;
    await showPage(tester);

    await tester.tap(find.text('コードを再発行'));
    await tester.pumpAndSettle();

    expect(find.text('登録コードを再発行しますか？'), findsOneWidget);
    expect(find.textContaining('現在のコードは使えなくなります'), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(repository.issueCalls, isEmpty);
    expect(find.text('123456'), findsOneWidget);

    await tester.tap(find.text('コードを再発行'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('再発行する'));
    await tester.pumpAndSettle();

    expect(repository.issueCalls, [true]);
    expect(find.text('654321'), findsOneWidget);
    expect(find.text('登録コードを再発行しました'), findsOneWidget);
  });

  testWidgets('copies the active six-digit code', (tester) async {
    repository.currentCode = activeCode;
    final clipboardWrites = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clipboardWrites.add(call.arguments);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await showPage(tester);

    await tester.tap(find.byTooltip('コードをコピー'));
    await tester.pumpAndSettle();

    expect(clipboardWrites, [
      <String, String>{'text': '123456'},
    ]);
    expect(find.text('コードをコピーしました'), findsOneWidget);
  });

  testWidgets('keeps an old code usable and copyable without an expiry', (tester) async {
    repository.currentCode = SupportLtCode(code: '123456', issuedAt: DateTime(2020));
    await showPage(tester);

    expect(find.textContaining('有効期限'), findsNothing);
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.copy)).onPressed, isNotNull);
    expect(find.text('コードを再発行'), findsOneWidget);
  });

  testWidgets('shows named and unnamed participants and updates the count live', (tester) async {
    repository.registrations = [
      SupportLtRegistration(uid: 'attendee-1', displayName: '参加 太郎', registeredAt: DateTime(2026, 9, 11, 12, 5)),
    ];
    await showPage(tester);

    expect(find.text('参加者 1人'), findsOneWidget);
    expect(find.text('参加 太郎'), findsOneWidget);
    expect(find.text('UID: attendee-1'), findsOneWidget);
    expect(find.text('登録日時: 2026/09/11 12:05'), findsOneWidget);

    repository.emitRegistrations([
      ...repository.registrations,
      SupportLtRegistration(uid: 'attendee-2', displayName: '', registeredAt: DateTime(2026, 9, 11, 12, 6)),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('参加者 2人'), findsOneWidget);
    expect(find.text('表示名未設定'), findsOneWidget);
    expect(find.text('UID: attendee-2'), findsOneWidget);
  });

  testWidgets('explains read permission failures and retries each stream independently', (tester) async {
    repository.codeReadError = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
    repository.registrationsReadError = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
    await showPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('管理者権限が必要です。確認済みの flutterkaigi.jp アカウントと管理者登録を確認してください。'), findsNWidgets(2));
    expect(find.text('参加者 0人'), findsNothing);
    expect(find.text('登録コードを発行'), findsNothing);

    repository.codeReadError = null;
    await tester.tap(find.byKey(const Key('retry-support-lt-code')));
    await tester.pumpAndSettle();
    expect(find.text('登録コードを発行'), findsOneWidget);
    expect(repository.codeWatchCount, 2);
    expect(repository.registrationsWatchCount, 1);

    repository.registrationsReadError = null;
    await tester.tap(find.byKey(const Key('retry-support-lt-registrations')));
    await tester.pumpAndSettle();
    expect(find.text('参加者 0人'), findsOneWidget);
    expect(repository.registrationsWatchCount, 2);
  });

  testWidgets('offers retry when reads fail without exposing backend details', (tester) async {
    repository.codeReadError = StateError('private backend detail');
    repository.registrationsReadError = StateError('private backend detail');
    await showPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('登録コードを読み込めませんでした。通信状況を確認して再試行してください。'), findsOneWidget);
    expect(find.text('参加者を読み込めませんでした。通信状況を確認して再試行してください。'), findsOneWidget);
    expect(find.textContaining('private backend detail'), findsNothing);
  });

  for (final error in [
    (code: 'permission-denied', message: '管理者権限が必要です。確認済みの flutterkaigi.jp アカウントと管理者登録を確認してください。'),
    (code: 'unauthenticated', message: 'セッションの有効期限が切れています。再度サインインしてください。'),
    (code: 'resource-exhausted', message: '操作が集中しています。少し時間をおいて再試行してください。'),
    (code: 'internal', message: 'コードを発行できませんでした。通信状況を確認して再試行してください。'),
  ]) {
    testWidgets('shows actionable ${error.code} issuance errors and permits retry', (tester) async {
      repository.onIssue = (_) => Future.error(FirebaseFunctionsException(code: error.code, message: 'private detail'));
      await showPage(tester);

      await tester.tap(find.text('登録コードを発行'));
      await tester.pumpAndSettle();

      expect(find.text(error.message), findsOneWidget);
      expect(find.textContaining('private detail'), findsNothing);
      repository.onIssue = null;
      await tester.tap(find.text('登録コードを発行'));
      await tester.pumpAndSettle();
      expect(find.text('654321'), findsOneWidget);
      expect(find.text(error.message), findsNothing);
    });
  }

  testWidgets('fits a narrow page and lets the participant list scroll', (tester) async {
    repository.currentCode = activeCode;
    repository.registrations = List.generate(
      12,
      (index) => SupportLtRegistration(
        uid: 'attendee-with-a-long-uid-$index',
        displayName: '長い表示名の参加者 $index',
        registeredAt: DateTime(2026, 9, 11, 12, index),
      ),
    );
    await showPage(tester);
    await tester.binding.setSurfaceSize(const Size(320, 700));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('UID: attendee-with-a-long-uid-11'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('長い表示名の参加者 11'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeSupportLtRepository implements SupportLtRepository {
  _FakeSupportLtRepository(this.nextCode);

  final SupportLtCode nextCode;
  SupportLtCode? currentCode;
  List<SupportLtRegistration> registrations = const [];
  List<bool> issueCalls = const [];
  Object? codeReadError;
  Object? registrationsReadError;
  bool pendingReads = false;
  int codeWatchCount = 0;
  int registrationsWatchCount = 0;
  Future<void> Function(bool rotate)? onIssue;
  final _codes = StreamController<SupportLtCode?>.broadcast();
  final _registrations = StreamController<List<SupportLtRegistration>>.broadcast();

  @override
  Stream<SupportLtCode?> watchCode() async* {
    codeWatchCount++;
    if (codeReadError case final error?) throw error;
    if (!pendingReads) yield currentCode;
    yield* _codes.stream;
  }

  @override
  Stream<List<SupportLtRegistration>> watchRegistrations() async* {
    registrationsWatchCount++;
    if (registrationsReadError case final error?) throw error;
    if (!pendingReads) yield registrations;
    yield* _registrations.stream;
  }

  @override
  Future<void> issueCode({bool rotate = false}) async {
    issueCalls = [...issueCalls, rotate];
    await onIssue?.call(rotate);
    currentCode = nextCode;
    _codes.add(nextCode);
  }

  void emitRegistrations(List<SupportLtRegistration> next) {
    registrations = List.unmodifiable(next);
    _registrations.add(registrations);
  }

  void emitReadErrors(Object error) {
    _codes.addError(error);
    _registrations.addError(error);
  }

  @override
  Future<void> register(String code) => throw UnimplementedError();

  @override
  Stream<SupportLtRegistration?> watchRegistration(String uid) => throw UnimplementedError();

  Future<void> dispose() async {
    await _codes.close();
    await _registrations.close();
  }
}

class _User implements User {
  _User(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
