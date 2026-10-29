import 'dart:async';

import 'package:data/data.dart';
import 'package:data/user.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUser extends Fake implements User {
  FakeUser({this.uid = 'attendee', this.email = 'attendee@example.com', this.displayName, this.isAnonymous = false});

  @override
  final String uid;

  @override
  final String? email;

  @override
  final String? displayName;

  @override
  final bool isAnonymous;
}

class FakeAuthRepository extends Fake implements AuthRepository {
  FakeAuthRepository({this._user});

  User? _user;
  final _events = StreamController<User?>.broadcast();
  final calls = <String>[];
  FirebaseAuthException? nextError;
  String? lastEmail;
  String? lastPassword;
  String? lastResetEmail;
  User appleUser = FakeUser();
  Completer<void>? appleSignInGate;

  @override
  User? get currentUser => _user;

  @override
  Stream<User?> authStateChanges() async* {
    yield _user;
    yield* _events.stream;
  }

  void setUser(User? user) {
    _user = user;
    _events.add(user);
  }

  void _checkError() {
    final error = nextError;
    nextError = null;
    if (error != null) throw error;
  }

  @override
  Future<void> signInWithGoogle() async {
    calls.add('google');
    _checkError();
    setUser(FakeUser());
  }

  @override
  Future<void> signInWithApple() async {
    calls.add('apple');
    _checkError();
    await appleSignInGate?.future;
    setUser(appleUser);
  }

  @override
  Future<void> signInWithEmailAndPassword({required String email, required String password}) async {
    calls.add('email');
    lastEmail = email;
    lastPassword = password;
    _checkError();
    setUser(FakeUser(email: email));
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    calls.add('reset');
    lastResetEmail = email;
    _checkError();
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    _checkError();
    setUser(null);
  }

  Future<void> dispose() => _events.close();
}

class FakeStampRallyRepository extends Fake implements StampRallyRepository {
  StampRallySettings settings = const StampRallySettings(checkpoints: [1, 2], isOpen: true);
  Set<String> sponsorIds = {'s1', 's2'};
  final cards = <String, StampRallyCard>{};
  final cardErrors = <String, Object>{};
  final pendingCards = <String>{};
  final watchedUids = <String>[];
  final cancelledUids = <String>[];
  final _controllers = <String, List<StreamController<StampRallyCard>>>{};

  @override
  Stream<StampRallySettings> watchSettings() => Stream.value(settings);

  @override
  Stream<Set<String>> watchSponsorIds() => Stream.value(sponsorIds);

  @override
  Stream<StampRallyCard> watchCard(String uid) {
    late final StreamController<StampRallyCard> controller;
    controller = StreamController<StampRallyCard>(
      onListen: () {
        watchedUids.add(uid);
        if (cardErrors[uid] case final error?) {
          controller.addError(error);
          unawaited(controller.close());
        } else if (!pendingCards.contains(uid)) {
          controller.add(cards[uid] ?? StampRallyCard.empty);
        }
      },
      onCancel: () {
        cancelledUids.add(uid);
        _controllers[uid]?.remove(controller);
      },
    );
    (_controllers[uid] ??= []).add(controller);
    return controller.stream;
  }

  void emitCard(String uid, StampRallyCard card) {
    cards[uid] = card;
    for (final controller in _controllers[uid] ?? <StreamController<StampRallyCard>>[]) {
      controller.add(card);
    }
  }

  Future<void> dispose() async {
    final controllers = _controllers.values.expand((value) => value).toList();
    await Future.wait(controllers.map((controller) => controller.close()));
  }
}

class FakeSponsorRepository extends Fake implements SponsorRepository {
  List<Sponsor> sponsors = [fakeSponsor('s1', 'スポンサー A'), fakeSponsor('s2', 'スポンサー B')];
  final excludesUnsupportedTiers = <bool>[];

  @override
  Stream<List<Sponsor>> watchAll({bool excludeUnsupportedTiers = false}) {
    excludesUnsupportedTiers.add(excludeUnsupportedTiers);
    return Stream.value(sponsors);
  }
}

Sponsor fakeSponsor(String id, String name) => Sponsor(
  id: id,
  name: LocaleMap(ja: name, en: name),
  description: const LocaleMap(ja: '', en: ''),
  tier: SponsorTier.gold,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
