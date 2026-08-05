import 'dart:async';

import 'package:data/data.dart';
import 'package:data/user.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [UserInfo] stand-in exposing only the provider id.
final class FakeUserInfo extends Fake implements UserInfo {
  FakeUserInfo(this.providerId);

  @override
  final String providerId;
}

/// A [User] stand-in exposing only the fields the UI reads.
final class FakeUser extends Fake implements User {
  FakeUser({this.email, this.displayName, List<String> providerIds = const []})
    : providerData = [for (final id in providerIds) FakeUserInfo(id)];

  @override
  final String? email;

  @override
  final String? displayName;

  @override
  final List<UserInfo> providerData;
}

/// In-memory [AuthRepository] for widget tests.
final class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({User? initialUser}) : _user = initialUser;

  final _controller = StreamController<User?>.broadcast();
  User? _user;

  /// When set, the next auth action throws this exception once.
  FirebaseAuthException? nextError;

  /// Auth actions invoked on this repository, in call order.
  final calledMethods = <String>[];

  String? lastEmail;
  String? lastPassword;
  String? lastResetEmail;
  String? lastDeletePassword;

  @override
  Stream<User?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  User? get currentUser => _user;

  @override
  Future<void> signInWithGoogle() => _run(
    'signInWithGoogle',
    FakeUser(
      email: 'google@example.com',
      displayName: 'Google User',
      providerIds: const ['google.com'],
    ),
  );

  @override
  Future<void> signInWithApple() => _run(
    'signInWithApple',
    FakeUser(
      email: 'apple@example.com',
      displayName: 'Apple User',
      providerIds: const ['apple.com'],
    ),
  );

  @override
  Future<void> signInWithEmailAndPassword({required String email, required String password}) {
    lastEmail = email;
    lastPassword = password;
    return _run(
      'signInWithEmailAndPassword',
      FakeUser(email: email, providerIds: const ['password']),
    );
  }

  @override
  Future<void> createUserWithEmailAndPassword({required String email, required String password}) {
    lastEmail = email;
    lastPassword = password;
    return _run(
      'createUserWithEmailAndPassword',
      FakeUser(email: email, providerIds: const ['password']),
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    calledMethods.add('sendPasswordResetEmail');
    lastResetEmail = email;
    _throwIfConfigured();
  }

  @override
  Future<void> signOut() => _run('signOut', null);

  @override
  Future<void> deleteAccount({String? password}) {
    lastDeletePassword = password;
    return _run('deleteAccount', null);
  }

  void dispose() {
    unawaited(_controller.close());
  }

  Future<void> _run(String method, User? signedInUser) async {
    calledMethods.add(method);
    _throwIfConfigured();
    _user = signedInUser;
    _controller.add(signedInUser);
  }

  void _throwIfConfigured() {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
  }
}
