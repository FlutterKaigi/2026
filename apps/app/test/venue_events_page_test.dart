import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/log/talker.dart';
import 'package:app/core/provider/clock.dart';
import 'package:app/core/remote_config/remote_config_provider.dart';
import 'package:app/core/router/router.dart' as app_router;
import 'package:app/core/ui/widget/brand_header_card.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository.dart';
import 'package:app/feature/profile/data/provider/user_profile_repository.dart';
import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
import 'package:app/feature/quiz/ui/page/quiz_event_list_page.dart';
import 'package:app/feature/sns_post/data/sns_post_provider.dart';
import 'package:app/feature/stamp_rally/data/stamp_rally_provider.dart';
import 'package:app/feature/support_lt/data/provider/support_lt_provider.dart';
import 'package:app/feature/venue_events/ui/page/venue_events_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'fake_auth_repository.dart';
import 'fake_profile_exchange_repository.dart';
import 'fake_remote_config_repository.dart';
import 'fake_sns_post_repository.dart';
import 'fake_stamp_rally_repository.dart';
import 'fake_support_lt_repository.dart';
import 'fake_user_profile_repository.dart';
import 'test_profiles.dart';

const _rowTitles = ['クイズ大会', 'スタンプラリー', 'プロフィール交換', '応援LT参加', 'SNS投稿登録'];

void main() {
  late FakeAuthRepository auth;
  late FakeUserProfileRepository profiles;
  late FakeProfileExchangeRepository exchanges;
  late FakeSupportLtRepository lt;
  late FakeSnsPostRepository sns;
  late FakeStampRallyRepository stamps;
  late _QuizEvents quizEvents;
  late _QuizParticipants quizParticipants;
  late Talker talker;
  late FakeRemoteConfigRepository remoteConfig;
  late DateTime now;
  late GoRouter router;

  setUpAll(() async => AppLocale.en.build());

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ja);
    auth = FakeAuthRepository(initialUser: FakeUser(uid: 'me'));
    profiles = FakeUserProfileRepository(initialProfile: profile('me', 'JP'));
    exchanges = FakeProfileExchangeRepository();
    lt = FakeSupportLtRepository();
    sns = FakeSnsPostRepository();
    stamps = FakeStampRallyRepository(sponsorIds: {'s1', 's2', 's3'});
    quizEvents = _QuizEvents();
    quizParticipants = _QuizParticipants();
    talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    remoteConfig = FakeRemoteConfigRepository();
    // Two weeks before the conference.
    now = DateTime.utc(2026, 10, 15, 3);
    router = GoRouter(
      initialLocation: '/account/venue-events',
      routes: [
        GoRoute(path: '/account/venue-events', builder: (_, _) => const VenueEventsPage()),
        for (final path in ['quiz', 'quiz/:eventId', 'stamp-rally', 'exchange', 'support-lt', 'sns-post', 'missions'])
          GoRoute(
            path: '/account/$path',
            builder: (_, state) => Scaffold(body: Text('${state.uri.path} destination')),
          ),
      ],
    );
    addTearDown(auth.dispose);
    addTearDown(profiles.dispose);
    addTearDown(exchanges.dispose);
    addTearDown(lt.dispose);
    addTearDown(sns.dispose);
    addTearDown(router.dispose);
    addTearDown(remoteConfig.dispose);
  });

  Future<void> pumpHub(WidgetTester tester, {AppLocale locale = AppLocale.ja, TextScaler? textScaler}) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          retry: (_, _) => null,
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            userProfileRepositoryProvider.overrideWithValue(profiles),
            profileExchangeRepositoryProvider.overrideWithValue(exchanges),
            supportLtRepositoryProvider.overrideWithValue(lt),
            snsPostRepositoryProvider.overrideWithValue(sns),
            stampRallyRepositoryProvider.overrideWithValue(stamps),
            quizEventRepositoryProvider.overrideWithValue(quizEvents),
            quizParticipantRepositoryProvider.overrideWithValue(quizParticipants),
            appleSignInAvailabilityProvider.overrideWithValue(false),
            talkerProvider.overrideWithValue(talker),
            clockProvider.overrideWithValue(() => now),
            // The real router keeps the account page under the hub.
            remoteConfigRepositoryProvider.overrideWithValue(remoteConfig),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: locale.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: textScaler == null
                ? null
                : (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                    child: child!,
                  ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder row(String title) => find.ancestor(of: find.text(title), matching: find.byType(ListTile));

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Texts in reading order: top to bottom, then left to right.
  List<String> readingOrder(WidgetTester tester, List<String> texts) => [...texts]
    ..sort((a, b) {
      final (first, second) = (tester.getTopLeft(find.text(a)), tester.getTopLeft(find.text(b)));
      return first.dy == second.dy ? first.dx.compareTo(second.dx) : first.dy.compareTo(second.dy);
    });

  group('signed out', () {
    setUp(() async {
      await auth.signOut();
      auth.calledMethods.clear();
    });

    testWidgets('asks for sign-in above a preview of every activity', (tester) async {
      await pumpHub(tester);

      expect(find.text('サインインして参加'), findsOneWidget);
      expect(find.text('スタンプやクイズの記録はアカウントに保存されます。'), findsOneWidget);
      expect(find.byType(BrandHeaderCard), findsNothing);
      expect(tester.getSize(find.byType(SignInCard)).width, tester.getSize(find.byType(IntrinsicHeight).first).width);
      expect(find.text('サインインすると参加できます'), findsOneWidget);
      const tiles = {
        'スタンプラリー': 'スポンサーブースを巡る',
        'プロフィール交換': '参加者とQRコードで交換',
        '応援LT参加': '会場のQRコードで登録',
        'SNS投稿登録': '写真の投稿URLを登録',
        'クイズ大会': '2日目 15:30から',
        'ミッション': '応援LT・交換・SNS投稿',
      };
      for (final MapEntry(key: title, value: preview) in tiles.entries) {
        expect(find.text(title), findsOneWidget, reason: title);
        expect(find.text(preview), findsOneWidget, reason: preview);
      }
      expect(readingOrder(tester, tiles.keys.toList()), tiles.keys.toList());

      await tester.tap(find.bySemanticsLabel('Google でサインイン'));
      await tester.pumpAndSettle();
      expect(auth.calledMethods, ['signInWithGoogle']);
    });

    testWidgets('preview tiles neither look nor act like links', (tester) async {
      await pumpHub(tester);

      expect(find.byIcon(Icons.chevron_right), findsNothing);
      for (final title in ['スタンプラリー', 'プロフィール交換', '応援LT参加', 'SNS投稿登録', 'クイズ大会', 'ミッション']) {
        expect(
          find.ancestor(of: find.text(title), matching: find.byType(InkWell)),
          findsNothing,
          reason: title,
        );
        await tapVisible(tester, find.text(title));
        expect(router.canPop(), isFalse, reason: title);
        expect(find.textContaining('destination'), findsNothing, reason: title);
      }
    });

    testWidgets('does not read private activity data', (tester) async {
      await pumpHub(tester);

      expect(quizEvents.subscriptions, 0);
      expect(lt.watchedUids, isEmpty);
      expect(sns.watchedUids, isEmpty);
    });
  });

  group('signed in', () {
    testWidgets('lists the activities with what to do in each', (tester) async {
      await pumpHub(tester);

      expect(readingOrder(tester, _rowTitles), _rowTitles);
      for (final (title, action) in [
        ('クイズ大会', 'スクリーンのQRコードでチェックインしてチームを選ぶ'),
        ('スタンプラリー', 'スポンサーブースでQRコードを読み取る'),
        ('プロフィール交換', 'QRコードか6桁のコードで参加者と交換'),
        ('応援LT参加', '会場のQRコードで参加登録'),
        ('SNS投稿登録', '写真を投稿してURLを登録'),
      ]) {
        expect(
          find.descendant(of: row(title), matching: find.text(action)),
          findsOneWidget,
          reason: title,
        );
      }
      expect(find.text('サインインして参加'), findsNothing);
    });

    testWidgets('shows the attendee status of each activity', (tester) async {
      lt.setRegistration(SupportLtRegistration(uid: 'me', displayName: 'me', registeredAt: DateTime.utc(2026)));
      await sns.save(uid: 'me', url: 'https://x.com/test/status/123', companion: SnsPostCompanion.staff);
      stamps.card = StampRallyCard(stamps: {'s1': DateTime.utc(2026), 's3': DateTime.utc(2026)}, rewardsRedeemedAt: {});
      await profiles.save(profile('a', 'JP'));
      await profiles.save(profile('b', 'US'));
      exchanges = FakeProfileExchangeRepository(
        initialExchangesByUid: {
          'me': [
            for (final uid in ['a', 'b'])
              ProfileExchange(id: uid, createdAt: DateTime.utc(2026), origin: ProfileExchangeOrigin.scan),
          ],
        },
      );
      addTearDown(exchanges.dispose);
      quizEvents.events = [_quizEvent('first'), _quizEvent('second')];
      quizParticipants.byEvent['second'] = _participant();

      await pumpHub(tester);

      expect(find.descendant(of: row('クイズ大会'), matching: find.text('登録済み')), findsOneWidget);
      expect(find.descendant(of: row('スタンプラリー'), matching: find.text('2 / 3')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('3個中2個のスタンプを獲得')), findsOneWidget);
      expect(find.descendant(of: row('プロフィール交換'), matching: find.text('2人')), findsOneWidget);
      expect(find.descendant(of: row('応援LT参加'), matching: find.text('登録済み')), findsOneWidget);
      expect(find.descendant(of: row('SNS投稿登録'), matching: find.text('登録済み')), findsOneWidget);
      // Two of the three missions. The exchange mission needs a third person.
      expect(find.text('3項目中2項目を達成'), findsOneWidget);
    });

    testWidgets('shows only the stamp count before anything is done', (tester) async {
      await pumpHub(tester);

      expect(find.descendant(of: row('スタンプラリー'), matching: find.text('0 / 3')), findsOneWidget);
      expect(find.text('登録済み'), findsNothing);
      expect(find.text('0人'), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.text('3項目中0項目を達成'), findsOneWidget);
    });

    for (final (state, participant, chip) in <(String, QuizParticipant?, String?)>[
      ('has not registered', null, null),
      ('has registered', _participant(), '登録済み'),
      ('has checked in', _participant(checkedInAt: DateTime.utc(2026, 10, 30, 6)), 'チェックイン済み'),
      ('has chosen a team', _participant(checkedInAt: DateTime.utc(2026, 10, 30, 6), teamId: 'C'), 'チーム C'),
    ]) {
      testWidgets('the quiz row reflects an attendee who $state', (tester) async {
        quizEvents.events = [_quizEvent('first'), _quizEvent('second')];
        if (participant != null) {
          quizParticipants.byEvent['second'] = participant;
        }
        await pumpHub(tester);

        for (final label in ['登録済み', 'チェックイン済み', 'チーム C']) {
          expect(
            find.descendant(of: row('クイズ大会'), matching: find.text(label)),
            label == chip ? findsOneWidget : findsNothing,
            reason: label,
          );
        }
      });
    }

    for (final (state, event, participant, shows) in <(String, QuizEvent, QuizParticipant?, bool)>[
      ('check-in opens during registration', _quizEvent('second', teamSelection: _open), _participant(), true),
      (
        'check-in opens after entry closes',
        _quizEvent('second', status: _entryClosed, teamSelection: _open),
        _participant(),
        true,
      ),
      (
        'the attendee has checked in',
        _quizEvent('second', status: _entryClosed, teamSelection: _open),
        _participant(checkedInAt: DateTime.utc(2026, 10, 30, 6)),
        false,
      ),
      ('check-in has not started', _quizEvent('second', status: _entryClosed), _participant(), false),
      (
        'check-in has closed',
        _quizEvent('second', status: _entryClosed, teamSelection: QuizTeamSelectionStatus.closed),
        _participant(),
        false,
      ),
      (
        'the quiz is in progress',
        _quizEvent('second', status: QuizEventStatus.inProgress, teamSelection: _open),
        _participant(),
        false,
      ),
      ('the attendee registered for no round', _quizEvent('second', teamSelection: _open), null, false),
    ]) {
      testWidgets('${shows ? 'shows' : 'hides'} the quiz check-in notice when $state', (tester) async {
        quizEvents.events = [_quizEvent('first'), event];
        if (participant != null) {
          quizParticipants.byEvent['second'] = participant;
        }
        await pumpHub(tester);

        expect(find.text('クイズ大会のチェックインを受付中です'), shows ? findsOneWidget : findsNothing);
        expect(find.text('会場スクリーンのQRコードを読み取ってください'), shows ? findsOneWidget : findsNothing);
      });
    }

    testWidgets('the quiz check-in notice opens the attendee round', (tester) async {
      quizEvents.events = [_quizEvent('first', teamSelection: _open), _quizEvent('second', teamSelection: _open)];
      quizParticipants.byEvent['second'] = _participant();
      await pumpHub(tester);

      await tapVisible(tester, find.text('クイズ大会のチェックインを受付中です'));

      expect(find.text('/account/quiz/second destination'), findsOneWidget);
    });

    for (final (title, path) in [
      ('クイズ大会', '/account/quiz'),
      ('スタンプラリー', '/account/stamp-rally'),
      ('プロフィール交換', '/account/exchange'),
      ('応援LT参加', '/account/support-lt'),
      ('SNS投稿登録', '/account/sns-post'),
      ('ミッション', '/account/missions'),
    ]) {
      testWidgets('$title opens $path above the hub', (tester) async {
        await pumpHub(tester);

        await tapVisible(tester, find.text(title));
        expect(find.text('$path destination'), findsOneWidget);

        router.pop();
        await tester.pumpAndSettle();
        expect(find.byType(VenueEventsPage), findsOneWidget);
      });
    }

    testWidgets('logs a status that failed to load and leaves its row without one', (tester) async {
      final failure = Exception('unavailable');
      sns.watchError = failure;
      await pumpHub(tester);

      expect(find.descendant(of: row('SNS投稿登録'), matching: find.byIcon(Icons.check_circle)), findsNothing);
      expect(talker.history.map((entry) => entry.exception), contains(failure));
    });

    testWidgets('a new account never sees the previous attendee status', (tester) async {
      quizEvents.events = [_quizEvent('first'), _quizEvent('second')];
      quizParticipants.byEvent['second'] = _participant();
      lt.setRegistration(SupportLtRegistration(uid: 'me', displayName: 'me', registeredAt: DateTime.utc(2026)));
      await pumpHub(tester);
      expect(find.descendant(of: row('クイズ大会'), matching: find.text('登録済み')), findsOneWidget);
      expect(find.descendant(of: row('応援LT参加'), matching: find.text('登録済み')), findsOneWidget);

      await auth.signOut();
      await tester.pumpAndSettle();
      await auth.signInWithGoogle();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('クイズ大会'), findsOneWidget);
      expect(find.text('登録済み'), findsNothing);

      router.go('/account/stamp-rally');
      await tester.pumpAndSettle();
      router.go('/account/venue-events');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('クイズ大会'), findsOneWidget);
      expect(find.text('登録済み'), findsNothing);
    });

    testWidgets('switching accounts on the app routes never shows the previous attendee status', (tester) async {
      quizEvents.events = [_quizEvent('first'), _quizEvent('second')];
      quizParticipants.byEvent['second'] = _participant();
      lt.setRegistration(SupportLtRegistration(uid: 'me', displayName: 'me', registeredAt: DateTime.utc(2026)));
      router = GoRouter(initialLocation: '/account', routes: app_router.$appRoutes);
      addTearDown(router.dispose);
      await pumpHub(tester);

      Future<void> step(String reason, Future<void> Function() action) async {
        await action();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: reason);
      }

      await step('open the hub as account 1', () => tester.tap(find.text('会場イベントに参加')));
      expect(find.descendant(of: row('クイズ大会'), matching: find.text('登録済み')), findsOneWidget);
      expect(find.descendant(of: row('応援LT参加'), matching: find.text('登録済み')), findsOneWidget);
      // Subscribes quizEventsProvider as account 1, so the switch below fails the
      // next build if the provider outlives its screens.
      await step('open the quiz list as account 1', () => tester.tap(find.text('クイズ大会')));
      expect(find.byType(QuizEventListPage), findsOneWidget);
      await step('back to the hub', () => tester.tap(find.byType(BackButton)));
      await step('back to the account tab', () => tester.tap(find.byType(BackButton)));
      expect(find.byType(VenueEventsPage), findsNothing);

      await step('sign out', auth.signOut);
      await step('sign in as account 2', auth.signInWithGoogle);
      await step('reopen the hub as account 2', () => tester.tap(find.text('会場イベントに参加')));
      expect(find.byType(VenueEventsPage), findsOneWidget);
      expect(find.text('登録済み'), findsNothing);
      await step('reopen the quiz list as account 2', () => tester.tap(find.text('クイズ大会')));
      expect(find.byType(QuizEventListPage), findsOneWidget);
      await step('back to the hub as account 2', () => tester.tap(find.byType(BackButton)));
      expect(find.byType(VenueEventsPage), findsOneWidget);
      expect(find.text('登録済み'), findsNothing);
    });

    testWidgets('opens the quiz list through the app routes and comes back with back', (tester) async {
      quizEvents.events = [_quizEvent('first')];
      router = GoRouter(initialLocation: '/account/venue-events', routes: app_router.$appRoutes);
      addTearDown(router.dispose);
      await pumpHub(tester);

      await tapVisible(tester, find.text('クイズ大会'));
      expect(find.byType(QuizEventListPage), findsOneWidget);
      expect(find.text('first'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(QuizEventListPage), findsNothing);
      expect(find.byType(VenueEventsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final (state, arrange, summary, showsProgress) in <(String, void Function(), String, bool)>[
      ('a mission is still loading', () => profiles.emitsInitialValue = false, '確認中', false),
      ('a mission failed to load', () => sns.watchError = Exception('unavailable'), '確認できない項目があります', false),
      ('no mission is achieved yet', () {}, '3項目中0項目を達成', true),
    ]) {
      testWidgets('the mission card says so when $state', (tester) async {
        arrange();
        await pumpHub(tester);

        expect(find.text(summary), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), showsProgress ? findsOneWidget : findsNothing);
      });
    }

    testWidgets('the mission card says when every mission is achieved', (tester) async {
      lt.setRegistration(SupportLtRegistration(uid: 'me', displayName: 'me', registeredAt: DateTime.utc(2026)));
      await sns.save(uid: 'me', url: 'https://x.com/test/status/123', companion: SnsPostCompanion.staff);
      for (final (uid, country) in [('a', 'JP'), ('b', 'JP'), ('c', 'US')]) {
        await profiles.save(profile(uid, country));
      }
      exchanges = FakeProfileExchangeRepository(
        initialExchangesByUid: {
          'me': [
            for (final uid in ['a', 'b', 'c'])
              ProfileExchange(id: uid, createdAt: DateTime.utc(2026), origin: ProfileExchangeOrigin.scan),
          ],
        },
      );
      addTearDown(exchanges.dispose);
      await pumpHub(tester);

      expect(find.text('すべて達成！'), findsOneWidget);
      expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 1);
    });

    for (final locale in AppLocale.values) {
      for (final (state, participant, chip) in <(String, QuizParticipant, String)>[
        ('checked in', _participant(checkedInAt: DateTime.utc(2026, 10, 30, 6)), 'checkedIn'),
        ('in a team', _participant(checkedInAt: DateTime.utc(2026, 10, 30, 6), teamId: 'C'), 'team'),
      ]) {
        testWidgets('a long status wraps at 320 px with 2x text (${locale.languageCode}, $state)', (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          LocaleSettings.setLocaleSync(locale);
          quizEvents.events = [_quizEvent('second')];
          quizParticipants.byEvent['second'] = participant;
          stamps = FakeStampRallyRepository(
            sponsorIds: {for (var i = 0; i < 24; i++) 's$i'},
            card: StampRallyCard(
              stamps: {for (var i = 0; i < 12; i++) 's$i': DateTime.utc(2026)},
              rewardsRedeemedAt: {},
            ),
          );
          await pumpHub(tester, locale: locale, textScaler: const TextScaler.linear(2));

          expect(tester.takeException(), isNull);
          final status = locale.translations.venueEvents.status;
          expect(find.text(chip == 'team' ? status.team(team: 'C') : status.checkedIn), findsOneWidget);
          expect(find.text('12 / 24'), findsOneWidget);
        });
      }
    }

    testWidgets('counts exchanged people in English', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      await profiles.save(profile('a', 'JP'));
      exchanges = FakeProfileExchangeRepository(
        initialExchangesByUid: {
          'me': [ProfileExchange(id: 'a', createdAt: DateTime.utc(2026), origin: ProfileExchangeOrigin.scan)],
        },
      );
      addTearDown(exchanges.dispose);
      await pumpHub(tester, locale: AppLocale.en);

      expect(find.descendant(of: row('Profile Exchange'), matching: find.text('1 person')), findsOneWidget);
    });
  });

  group('event day label', () {
    testWidgets('turns to day 2 at JST midnight while the page stays open', (tester) async {
      // 10/29 23:59:30 JST.
      now = DateTime.utc(2026, 10, 29, 14, 59, 30);
      await pumpHub(tester);
      expect(find.text('10月29日(木) 1日目'), findsOneWidget);

      now = DateTime.utc(2026, 10, 29, 15, 0, 30);
      await tester.pump(const Duration(minutes: 1));
      await tester.pump();

      expect(find.text('10月30日(金) 2日目'), findsOneWidget);
      expect(find.text('10月29日(木) 1日目'), findsNothing);
    });

    for (final (instant, label) in [
      // 10/29 00:30 JST.
      (DateTime.utc(2026, 10, 28, 15, 30), '10月29日(木) 1日目'),
      // 10/30 18:00 JST.
      (DateTime.utc(2026, 10, 30, 9), '10月30日(金) 2日目'),
    ]) {
      testWidgets('names $label when signed in and signed out', (tester) async {
        now = instant;
        await pumpHub(tester);
        expect(find.text(label), findsOneWidget);

        await auth.signOut();
        await tester.pumpAndSettle();
        expect(find.text('サインインして参加'), findsOneWidget);
        expect(find.text(label), findsOneWidget);
      });
    }

    for (final instant in [
      // 10/28 23:59 JST.
      DateTime.utc(2026, 10, 28, 14, 59),
      // 10/31 00:00 JST.
      DateTime.utc(2026, 10, 30, 15),
    ]) {
      testWidgets('is hidden outside the conference days: $instant', (tester) async {
        now = instant;
        await pumpHub(tester);

        expect(find.text('10月29日(木) 1日目'), findsNothing);
        expect(find.text('10月30日(金) 2日目'), findsNothing);
      });
    }
  });

  testWidgets('large text on a narrow screen does not overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });
    now = DateTime.utc(2026, 10, 30, 2);
    quizEvents.events = [_quizEvent('second', teamSelection: _open)];
    quizParticipants.byEvent['second'] = _participant();
    lt.setRegistration(SupportLtRegistration(uid: 'me', displayName: 'me', registeredAt: DateTime.utc(2026)));

    await pumpHub(tester);
    await tester.scrollUntilVisible(find.text('ミッション'), 200);
    expect(tester.takeException(), isNull);

    await auth.signOut();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('応援LT・交換・SNS投稿'), 200);
    expect(tester.takeException(), isNull);
  });
}

const _open = QuizTeamSelectionStatus.open;
const _entryClosed = QuizEventStatus.entryClosed;

QuizEvent _quizEvent(
  String id, {
  QuizEventStatus status = QuizEventStatus.registration,
  QuizTeamSelectionStatus teamSelection = QuizTeamSelectionStatus.notStarted,
}) => QuizEvent(
  id: id,
  title: LocaleMap(ja: id, en: id),
  status: status,
  teamSelectionStatus: teamSelection,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

QuizParticipant _participant({DateTime? checkedInAt, String? teamId}) => QuizParticipant(
  id: 'me',
  displayName: 'me',
  registeredAt: DateTime.utc(2026, 10, 29),
  checkedInAt: checkedInAt,
  teamId: teamId,
);

class _QuizEvents extends Fake implements QuizEventRepository {
  List<QuizEvent> events = const [];
  int subscriptions = 0;

  @override
  Stream<List<QuizEvent>> watchPublished() {
    subscriptions++;
    return Stream.value(events);
  }
}

class _QuizParticipants extends Fake implements QuizParticipantRepository {
  /// The signed-in attendee's participant document, keyed by round.
  final byEvent = <String, QuizParticipant>{};

  @override
  Stream<QuizParticipant?> watchByUid(String eventId, String uid) =>
      Stream.value(byEvent[eventId]?.id == uid ? byEvent[eventId] : null);
}
