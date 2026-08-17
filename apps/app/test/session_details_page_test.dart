import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/session/data/provider/session_detail_provider.dart';
import 'package:app/feature/session/data/provider/session_repository.dart';
import 'package:app/feature/session/data/provider/session_timetable_repository.dart';
import 'package:app/feature/session/ui/page/session_details_page.dart';
import 'package:app/feature/session/ui/page/session_timetable_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('builds the typed session details route location', () {
    expect(
      const SessionDetailsRoute(sessionId: 'session-a').location,
      '/sessions/session-a',
    );
  });

  testWidgets('renders current Firestore-backed session details', (tester) async {
    await _pumpSessionDetailsPage(tester, sessionId: 'session-a');
    await _pumpProviderFrames(tester);

    expect(find.text('Session A'), findsWidgets);
    expect(find.text('Description A'), findsOneWidget);
    expect(find.text('2026/10/29'), findsWidgets);
    expect(find.text('10:00-10:45'), findsWidgets);
    expect(find.text('Hall A'), findsWidgets);
    expect(find.text('EN'), findsOneWidget);
    expect(find.text('Speaker A'), findsOneWidget);
    expect(find.text('Speaker B'), findsOneWidget);
    expect(find.text('Bio A'), findsOneWidget);
    expect(find.text('Bio B'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('session-speaker-avatar-speaker-a'))),
      const Size.square(56),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('session-speaker-avatar-speaker-b'))),
      const Size.square(56),
    );
    expect(find.text('Sessionize'), findsOneWidget);
    expect(find.text('https://sessionize.com/flutterkaigi-2026/session-a'), findsOneWidget);
  });

  testWidgets('hides optional sections when session fields are absent', (tester) async {
    await _pumpSessionDetailsPage(tester, sessionId: 'session-without-optionals');
    await _pumpProviderFrames(tester);

    expect(find.text('No Optional Fields'), findsWidgets);
    expect(find.text('登壇者'), findsNothing);
    expect(find.text('概要'), findsNothing);
    expect(find.text('リンク'), findsNothing);
    expect(find.text('Sessionize'), findsNothing);
  });

  testWidgets('shows long session titles without truncation', (tester) async {
    const title = 'A very long session title that must remain fully readable on a narrow mobile screen';
    final session = _sessions.first.copyWith(
      id: 'long-title-session',
      title: const LocaleMap(ja: title, en: title),
    );

    await _pumpSessionDetailsPage(
      tester,
      sessionId: session.id,
      sessionRepository: _FakeSessionRepository([session]),
      contentWidth: 320,
    );
    await _pumpProviderFrames(tester);

    final titleTexts = tester.widgetList<Text>(find.text(title));
    expect(titleTexts, isNotEmpty);
    for (final titleText in titleTexts) {
      expect(titleText.maxLines, isNull);
      expect(titleText.overflow, isNot(TextOverflow.ellipsis));
    }
    final appBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
    final context = tester.element(find.byType(SliverAppBar));
    final contentWidth = tester.getSize(find.byType(CustomScrollView)).width;
    expect(MediaQuery.sizeOf(context).width, greaterThan(contentWidth));
    final titlePainter =
        TextPainter(
          text: TextSpan(
            text: title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(maxScaleFactor: 1.34),
        )..layout(
          maxWidth: contentWidth - 32,
        );
    final expectedExpandedHeight = kToolbarHeight + 32 + titlePainter.height;

    expect(
      appBar.expandedHeight,
      closeTo(expectedExpandedHeight, 0.01),
    );
  });

  testWidgets('keeps all speaker details readable across viewport widths', (tester) async {
    final session = _sessions.first.copyWith(
      id: 'responsive-speakers-session',
      speakerIds: _responsiveSpeakers.map((speaker) => speaker.id).toList(),
    );

    for (final viewportWidth in [
      320.0,
      390.0,
      600.0,
      839.0,
      840.0,
      1024.0,
      1440.0,
    ]) {
      await _pumpSessionDetailsPage(
        tester,
        sessionId: session.id,
        sessionRepository: _FakeSessionRepository([session]),
        speakerRepository: _FakeSpeakerRepository(_responsiveSpeakers),
        viewportSize: Size(viewportWidth, 1600),
      );
      await _pumpProviderFrames(tester);

      final contentFinder = find.byKey(
        const ValueKey('session-details-content'),
      );
      final contentRect = tester.getRect(contentFinder);
      final scrollViewRect = tester.getRect(find.byType(CustomScrollView));
      final scrollbarRect = tester.getRect(find.byType(Scrollbar));
      expect(
        contentRect.width,
        closeTo(viewportWidth, 0.01),
        reason: 'viewport width: $viewportWidth',
      );
      expect(
        scrollViewRect.width,
        closeTo(viewportWidth, 0.01),
        reason: 'viewport width: $viewportWidth',
      );
      expect(
        scrollbarRect.width,
        closeTo(viewportWidth, 0.01),
        reason: 'viewport width: $viewportWidth',
      );
      expect(
        contentRect.center.dx,
        closeTo(viewportWidth / 2, 0.01),
        reason: 'viewport width: $viewportWidth',
      );

      Rect? previousSpeakerRect;
      for (final speaker in _responsiveSpeakers) {
        final detailsFinder = find.byKey(
          ValueKey('session-speaker-details-${speaker.id}'),
        );
        final avatarFinder = find.byKey(
          ValueKey('session-speaker-avatar-${speaker.id}'),
        );
        final nameFinder = find.byKey(
          ValueKey('session-speaker-name-${speaker.id}'),
        );
        final bioFinder = find.text(speaker.bio!);

        expect(detailsFinder, findsOneWidget);
        expect(avatarFinder, findsOneWidget);
        expect(nameFinder, findsOneWidget);
        expect(bioFinder, findsOneWidget);

        final detailsRect = tester.getRect(detailsFinder);
        final avatarRect = tester.getRect(avatarFinder);
        final nameRect = tester.getRect(nameFinder);
        final bioRect = tester.getRect(bioFinder);
        final avatarClipFinder = find.descendant(
          of: avatarFinder,
          matching: find.byType(ClipOval),
        );

        expect(
          avatarRect.size,
          const Size.square(56),
          reason: 'viewport width: $viewportWidth, speaker: ${speaker.id}',
        );
        expect(avatarClipFinder, findsOneWidget);
        expect(
          tester.getSize(avatarClipFinder),
          const Size.square(56),
          reason: 'viewport width: $viewportWidth, speaker: ${speaker.id}',
        );
        expect(
          nameRect.left,
          closeTo(avatarRect.right + 12, 0.01),
          reason: 'viewport width: $viewportWidth, speaker: ${speaker.id}',
        );
        expect(
          bioRect.left,
          closeTo(nameRect.left, 0.01),
          reason: 'viewport width: $viewportWidth, speaker: ${speaker.id}',
        );
        expect(
          detailsRect.right,
          lessThanOrEqualTo(contentRect.right - 16 + 0.01),
          reason: 'viewport width: $viewportWidth, speaker: ${speaker.id}',
        );
        expect(
          nameRect.right,
          lessThanOrEqualTo(detailsRect.right + 0.01),
          reason: 'viewport width: $viewportWidth, speaker: ${speaker.id}',
        );
        expect(
          bioRect.right,
          lessThanOrEqualTo(detailsRect.right + 0.01),
          reason: 'viewport width: $viewportWidth, speaker: ${speaker.id}',
        );

        final nameText = tester.widget<Text>(nameFinder);
        final bioText = tester.widget<Text>(bioFinder);
        expect(nameText.maxLines, isNull);
        expect(nameText.overflow, isNot(TextOverflow.ellipsis));
        expect(bioText.maxLines, isNull);
        expect(bioText.overflow, isNot(TextOverflow.ellipsis));

        if (previousSpeakerRect != null) {
          expect(
            detailsRect.top,
            greaterThanOrEqualTo(previousSpeakerRect.bottom + 16 - 0.01),
            reason: 'viewport width: $viewportWidth',
          );
        }
        previousSpeakerRect = detailsRect;
      }

      expect(
        tester.takeException(),
        isNull,
        reason: 'viewport width: $viewportWidth',
      );
    }
  });

  testWidgets('hides the Sessionize link when the URL is not a hosted HTTPS URL', (tester) async {
    for (final session in [
      _sessionWithSessionizeUrl(id: 'tel-url', sessionizeUrl: 'tel:+1234567890'),
      _sessionWithSessionizeUrl(id: 'custom-url', sessionizeUrl: 'myapp://sessions/session-a'),
      _sessionWithSessionizeUrl(id: 'hostless-https-url', sessionizeUrl: 'https:///sessions/session-a'),
    ]) {
      await _pumpSessionDetailsPage(
        tester,
        sessionId: session.id,
        sessionRepository: _FakeSessionRepository([session]),
      );
      await _pumpProviderFrames(tester);

      expect(find.text('Sessionize'), findsNothing);
    }
  });

  testWidgets('shows not found when the session ID is unknown', (tester) async {
    await _pumpSessionDetailsPage(tester, sessionId: 'missing');
    await _pumpProviderFrames(tester);

    expect(find.text('セッションが見つかりませんでした'), findsOneWidget);
  });

  testWidgets('shows an error state when the details provider fails', (tester) async {
    final preferences = await _prepareTester(tester);

    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            sessionDetailProvider('session-a').overrideWithValue(
              AsyncError(Exception('boom'), StackTrace.current),
            ),
          ],
          child: const MaterialApp(home: SessionDetailsPage(sessionId: 'session-a')),
        ),
      ),
    );
    await _pumpProviderFrames(tester);

    expect(find.text('データを読み込めませんでした'), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);
  });

  testWidgets('opens session details from a timetable session card', (tester) async {
    GoRouter.optionURLReflectsImperativeAPIs = true;
    addTearDown(() => GoRouter.optionURLReflectsImperativeAPIs = false);
    final router = GoRouter(
      initialLocation: '/sessions',
      routes: [
        GoRoute(
          path: '/sessions',
          builder: (context, state) => const SessionTimetablePage(),
          routes: [
            GoRoute(
              path: ':sessionId',
              builder: (context, state) => SessionDetailsPage(
                sessionId: state.pathParameters['sessionId']!,
              ),
            ),
          ],
        ),
      ],
    );

    await _pumpWithProviders(
      tester,
      MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        locale: const Locale('en'),
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
    await _pumpProviderFrames(tester);

    final sessionCard = find.ancestor(
      of: find.text('Session A').first,
      matching: find.byType(InkWell),
    );
    await tester.tap(sessionCard.first);
    await tester.pumpAndSettle();

    expect(find.text('Sessionize'), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.path,
      '/sessions/session-a',
    );
  });
}

Future<void> _pumpProviderFrames(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
}

Future<void> _pumpSessionDetailsPage(
  WidgetTester tester, {
  required String sessionId,
  SessionRepository? sessionRepository,
  VenueRepository? venueRepository,
  SpeakerRepository? speakerRepository,
  double? contentWidth,
  Size viewportSize = const Size(1200, 2400),
}) async {
  final page = SessionDetailsPage(sessionId: sessionId);
  await _pumpWithProviders(
    tester,
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: contentWidth == null
          ? page
          : Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: contentWidth,
                child: page,
              ),
            ),
    ),
    sessionRepository: sessionRepository,
    venueRepository: venueRepository,
    speakerRepository: speakerRepository,
    viewportSize: viewportSize,
  );
}

Future<void> _pumpWithProviders(
  WidgetTester tester,
  Widget child, {
  SessionRepository? sessionRepository,
  VenueRepository? venueRepository,
  SpeakerRepository? speakerRepository,
  Size viewportSize = const Size(1200, 2400),
}) async {
  final preferences = await _prepareTester(
    tester,
    viewportSize: viewportSize,
  );

  await tester.pumpWidget(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          sessionRepositoryProvider.overrideWithValue(
            sessionRepository ?? _FakeSessionRepository(_sessions),
          ),
          sessionTimetableTimelineEventRepositoryProvider.overrideWithValue(
            const _FakeTimelineEventRepository([]),
          ),
          sessionTimetableVenueRepositoryProvider.overrideWithValue(
            venueRepository ?? _FakeVenueRepository(_venues),
          ),
          sessionTimetableSpeakerRepositoryProvider.overrideWithValue(
            speakerRepository ?? _FakeSpeakerRepository(_speakers),
          ),
        ],
        child: child,
      ),
    ),
  );
}

Future<SharedPreferences> _prepareTester(
  WidgetTester tester, {
  Size viewportSize = const Size(1200, 2400),
}) async {
  tester.view.physicalSize = viewportSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

final _sessions = [
  Session(
    id: 'session-a',
    title: const LocaleMap(ja: 'セッション A', en: 'Session A'),
    description: const LocaleMap(ja: '説明 A', en: 'Description A'),
    primaryLocale: 'en',
    startsAt: DateTime.utc(2026, 10, 29, 1),
    endsAt: DateTime.utc(2026, 10, 29, 1, 45),
    venueId: 'hall-a',
    speakerIds: const ['speaker-a', 'speaker-b'],
    sessionizeUrl: 'https://sessionize.com/flutterkaigi-2026/session-a',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
  Session(
    id: 'session-without-optionals',
    title: const LocaleMap(
      ja: '任意項目なし',
      en: 'No Optional Fields',
    ),
    description: const LocaleMap(ja: '', en: ''),
    primaryLocale: 'en',
    startsAt: DateTime.utc(2026, 10, 29, 2),
    endsAt: DateTime.utc(2026, 10, 29, 2, 45),
    venueId: 'hall-a',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
];

Session _sessionWithSessionizeUrl({
  required String id,
  required String sessionizeUrl,
}) => Session(
  id: id,
  title: LocaleMap(ja: id, en: id),
  description: LocaleMap(ja: id, en: id),
  primaryLocale: 'en',
  startsAt: DateTime.utc(2026, 10, 29, 1),
  endsAt: DateTime.utc(2026, 10, 29, 1, 45),
  venueId: 'hall-a',
  sessionizeUrl: sessionizeUrl,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _venues = [
  Venue(
    id: 'hall-a',
    name: const LocaleMap(ja: 'ホール A', en: 'Hall A'),
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
];

final _speakers = [
  Speaker(
    id: 'speaker-a',
    name: 'Speaker A',
    bio: 'Bio A',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
  Speaker(
    id: 'speaker-b',
    name: 'Speaker B',
    bio: 'Bio B',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
];

final _responsiveSpeakers = [
  Speaker(
    id: 'responsive-speaker-a',
    name: 'A speaker with a deliberately long name that must wrap without truncation',
    bio:
        'This deliberately long biography verifies that the first speaker uses the remaining width, wraps naturally, and stays readable without overlapping the avatar or another speaker.',
    xId: 'responsive_speaker_a',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
  Speaker(
    id: 'responsive-speaker-b',
    name: 'Second speaker whose complete name must also remain visible on narrow screens',
    bio:
        'A second long biography verifies that every speaker is listed vertically and that adjacent speaker rows never overlap at any supported viewport width.',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
];

final class _FakeSessionRepository implements SessionRepository {
  const _FakeSessionRepository(this._sessions);

  final List<Session> _sessions;

  @override
  Stream<List<Session>> watchAll() => Stream.value(_sessions);

  @override
  Future<void> save(Session session) async {}

  @override
  Future<void> delete(String id) async {}
}

final class _FakeVenueRepository implements VenueRepository {
  const _FakeVenueRepository(this._venues);

  final List<Venue> _venues;

  @override
  Stream<List<Venue>> watchAll() => Stream.value(_venues);

  @override
  Future<void> save(Venue venue) async {}

  @override
  Future<void> delete(String id) async {}
}

final class _FakeTimelineEventRepository implements TimelineEventRepository {
  const _FakeTimelineEventRepository(this._timelineEvents);

  final List<TimelineEvent> _timelineEvents;

  @override
  Stream<List<TimelineEvent>> watchAll() => Stream.value(_timelineEvents);

  @override
  Future<void> save(TimelineEvent timelineEvent) async {}

  @override
  Future<void> delete(String id) async {}
}

final class _FakeSpeakerRepository implements SpeakerRepository {
  const _FakeSpeakerRepository(this._speakers);

  final List<Speaker> _speakers;

  @override
  Stream<List<Speaker>> watchAll() => Stream.value(_speakers);

  @override
  Future<void> save(Speaker speaker) async {}

  @override
  Future<void> delete(String id) async {}
}
