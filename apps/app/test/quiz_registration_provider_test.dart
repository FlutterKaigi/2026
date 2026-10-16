import 'dart:async';

import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_auth_repository.dart';

void main() {
  final first = _event('first');
  final second = _event('second');

  ProviderContainer containerFor({
    required Stream<QuizParticipant?> Function(String eventId, String uid) participants,
  }) {
    // The published rounds are read only once an account is signed in.
    final auth = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(auth.dispose);
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        quizEventRepositoryProvider.overrideWithValue(_Events([first, second])),
        quizParticipantRepositoryProvider.overrideWithValue(_Participants(participants)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<ProviderSubscription<AsyncValue<QuizRegistration?>>> watch(ProviderContainer container, String uid) async {
    final subscription = container.listen(quizRegistrationProvider(uid), (_, _) {});
    addTearDown(subscription.close);
    await pumpEventQueue();
    return subscription;
  }

  test('finds the round the account registered for', () async {
    final container = containerFor(
      participants: (eventId, uid) => Stream.value(eventId == 'second' ? _participant(uid) : null),
    );

    final registration = (await watch(container, 'uid-1')).read();

    expect(registration.value?.event, second);
    expect(registration.value?.participant, _participant('uid-1'));
  });

  test('answers null when the account registered for no round', () async {
    final container = containerFor(participants: (_, _) => Stream.value(null));

    final registration = (await watch(container, 'uid-1')).read();

    expect(registration, isA<AsyncData<QuizRegistration?>>());
    expect(registration.value, isNull);
  });

  test('never shows the previous account registration to the next account', () async {
    final container = containerFor(
      participants: (eventId, uid) => Stream.value(uid == 'uid-1' && eventId == 'first' ? _participant(uid) : null),
    );
    expect((await watch(container, 'uid-1')).read().value?.event, first);

    final next = (await watch(container, 'uid-2')).read();

    expect(next, isA<AsyncData<QuizRegistration?>>());
    expect(next.value, isNull);
  });

  test('waits for every round before saying the account is not registered', () async {
    final firstRound = StreamController<QuizParticipant?>();
    addTearDown(firstRound.close);
    final container = containerFor(
      participants: (eventId, _) => eventId == 'first' ? firstRound.stream : Stream.value(null),
    );

    final subscription = await watch(container, 'uid-1');
    expect(subscription.read(), isA<AsyncLoading<QuizRegistration?>>());

    firstRound.add(null);
    await pumpEventQueue();
    expect(subscription.read(), isA<AsyncData<QuizRegistration?>>());
    expect(subscription.read().value, isNull);
  });

  test('a registration found in one round does not wait for the others', () async {
    final container = containerFor(
      participants: (eventId, uid) => eventId == 'first' ? const Stream.empty() : Stream.value(_participant(uid)),
    );

    expect((await watch(container, 'uid-1')).read().value?.event, second);
  });

  test('reports a round that failed to load when no round has the registration', () async {
    final failure = Exception('unavailable');
    final container = containerFor(
      participants: (eventId, _) => eventId == 'first' ? Stream.error(failure) : Stream.value(null),
    );

    final registration = (await watch(container, 'uid-1')).read();

    expect(registration, isA<AsyncError<QuizRegistration?>>());
    expect(registration.error, failure);
  });

  test('keeps a healthy registration when another round fails to load', () async {
    final container = containerFor(
      participants: (eventId, uid) =>
          eventId == 'first' ? Stream.error(Exception('unavailable')) : Stream.value(_participant(uid)),
    );

    final registration = (await watch(container, 'uid-1')).read();

    expect(registration, isA<AsyncData<QuizRegistration?>>());
    expect(registration.value?.event, second);
  });

  test('reports a participant read that fails after the registration loaded', () async {
    final secondRound = StreamController<QuizParticipant?>()..add(_participant('uid-1'));
    addTearDown(secondRound.close);
    final container = containerFor(
      participants: (eventId, _) => eventId == 'second' ? secondRound.stream : Stream.value(null),
    );
    final subscription = await watch(container, 'uid-1');
    expect(subscription.read().value?.event, second);

    final failure = Exception('unavailable');
    secondRound.addError(failure);
    await pumpEventQueue();

    expect(subscription.read(), isA<AsyncError<QuizRegistration?>>());
    expect(subscription.read().error, failure);
  });
}

QuizEvent _event(String id) => QuizEvent(
  id: id,
  title: LocaleMap(ja: id, en: id),
  status: QuizEventStatus.registration,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

QuizParticipant _participant(String uid) =>
    QuizParticipant(id: uid, displayName: uid, registeredAt: DateTime.utc(2026, 10, 29));

class _Events extends Fake implements QuizEventRepository {
  _Events(this.events);

  final List<QuizEvent> events;

  @override
  Stream<List<QuizEvent>> watchPublished() => Stream.value(events);
}

class _Participants extends Fake implements QuizParticipantRepository {
  _Participants(this.watch);

  final Stream<QuizParticipant?> Function(String eventId, String uid) watch;

  @override
  Stream<QuizParticipant?> watchByUid(String eventId, String uid) => watch(eventId, uid);
}
