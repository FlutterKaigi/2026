@TestOn('browser')
library;

import 'dart:async';

import 'package:data/data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final google = _UnexpectedNativeGooglePlatform();
  late _Auth auth;
  late FirebaseAuthRepository repository;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    GoogleSignInPlatform.instance = google;
    google.calls.clear();
    auth = _Auth();
    repository = FirebaseAuthRepository(auth: auth, hostedDomain: 'example.com');
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    expect(google.calls, isEmpty);
  });

  test('Google sign-in opens the Firebase popup with the hosted domain even in an Android browser', () async {
    auth.signInGate = Completer<UserCredential>();
    var completed = false;

    final signIn = repository.signInWithGoogle().then((_) => completed = true);

    final provider = auth.providers.single as GoogleAuthProvider;
    expect(provider.providerId, GoogleAuthProvider.PROVIDER_ID);
    expect(provider.parameters, {'hd': 'example.com'});
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);

    auth.signInGate!.complete(_UserCredential());
    await signIn;
    expect(completed, isTrue);
  });

  test('Google sign-in without a hosted domain does not restrict the popup account selection', () async {
    repository = FirebaseAuthRepository(auth: auth);

    await repository.signInWithGoogle();

    expect((auth.providers.single as GoogleAuthProvider).parameters, isEmpty);
  });

  test('Google popup errors retain the Firebase error contract', () async {
    final failure = FirebaseAuthException(code: 'popup-blocked');
    auth.signInError = failure;

    await expectLater(repository.signInWithGoogle(), throwsA(same(failure)));

    expect(auth.providers, hasLength(1));
  });

  test('account deletion waits for popup reauthentication before deleting user data and the account', () async {
    final user = _User()..reauthenticationGate = Completer<UserCredential>();
    auth.currentUser = user;

    final deletion = repository.deleteAccount(beforeDelete: () async => user.events.add('beforeDelete'));

    final provider = user.providers.single as GoogleAuthProvider;
    expect(provider.providerId, GoogleAuthProvider.PROVIDER_ID);
    expect(provider.parameters, {'hd': 'example.com'});
    await Future<void>.delayed(Duration.zero);
    expect(user.events, ['reauthenticateWithPopup']);

    user.reauthenticationGate!.complete(_UserCredential());
    await deletion;
    expect(user.events, ['reauthenticateWithPopup', 'beforeDelete', 'delete']);
    expect(auth.providers, isEmpty);
  });

  for (final code in ['popup-closed-by-user', 'user-mismatch']) {
    test('a $code popup failure leaves user data and the account intact', () async {
      final failure = FirebaseAuthException(code: code);
      final user = _User()..reauthenticationError = failure;
      auth.currentUser = user;

      await expectLater(
        repository.deleteAccount(beforeDelete: () async => user.events.add('beforeDelete')),
        throwsA(same(failure)),
      );

      expect(user.events, ['reauthenticateWithPopup']);
      expect(auth.currentUser, same(user));
    });
  }

  test('sign-out clears the Firebase session without calling native Google APIs', () async {
    auth.currentUser = _User();

    await repository.signOut();

    expect(auth.signOutCount, 1);
    expect(auth.currentUser, isNull);
  });
}

class _UnexpectedNativeGooglePlatform extends GoogleSignInPlatform {
  final calls = <String>[];

  Never _unexpected(String method) {
    calls.add(method);
    throw StateError('Web authentication called native Google $method');
  }

  @override
  Future<void> init(InitParameters params) => _unexpected('init');

  @override
  Future<AuthenticationResults> authenticate(AuthenticateParameters params) => _unexpected('authenticate');

  @override
  Future<void> signOut(SignOutParams params) => _unexpected('signOut');

  @override
  dynamic noSuchMethod(Invocation invocation) => _unexpected(invocation.memberName.toString());
}

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? currentUser;

  final providers = <AuthProvider>[];
  Completer<UserCredential>? signInGate;
  Object? signInError;
  var signOutCount = 0;

  @override
  Future<UserCredential> signInWithPopup(AuthProvider provider) async {
    providers.add(provider);
    if (signInError case final error?) {
      throw error;
    }
    if (signInGate case final gate?) {
      return gate.future;
    }
    return _UserCredential();
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    currentUser = null;
  }
}

class _User extends Fake implements User {
  @override
  List<UserInfo> get providerData => [_UserInfo(GoogleAuthProvider.PROVIDER_ID)];

  final providers = <AuthProvider>[];
  final events = <String>[];
  Completer<UserCredential>? reauthenticationGate;
  Object? reauthenticationError;

  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) async {
    providers.add(provider);
    events.add('reauthenticateWithPopup');
    if (reauthenticationError case final error?) {
      throw error;
    }
    if (reauthenticationGate case final gate?) {
      return gate.future;
    }
    return _UserCredential();
  }

  @override
  Future<void> delete() async => events.add('delete');
}

class _UserInfo extends Fake implements UserInfo {
  _UserInfo(this.providerId);

  @override
  final String providerId;
}

class _UserCredential extends Fake implements UserCredential {}
