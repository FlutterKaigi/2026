import 'dart:async';

import 'package:data/data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final google = _GooglePlatform();
  late _Auth auth;
  late FirebaseAuthRepository repository;

  setUpAll(() {
    GoogleSignInPlatform.instance = google;
  });

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    google.reset();
    auth = _Auth();
    repository = FirebaseAuthRepository(auth: auth, hostedDomain: 'example.com');
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('concurrent Android sign-ins wait for one shared initialization and use native ID tokens', () async {
    google.initializationGate = Completer<void>();
    final anotherRepository = FirebaseAuthRepository(auth: auth, hostedDomain: 'example.com');
    final signIns = Future.wait([
      repository.signInWithGoogle(),
      anotherRepository.signInWithGoogle(),
    ]);

    await Future<void>.delayed(Duration.zero);
    expect(google.initializations, hasLength(1));
    expect(google.initializations.single.hostedDomain, 'example.com');
    expect(google.events, isEmpty);
    expect(auth.credentials, isEmpty);

    google.initializationGate!.complete();
    await signIns;

    expect(google.initializations, hasLength(1));
    expect(google.events.where((event) => event == 'authenticate'), hasLength(2));
    expect(auth.credentials, hasLength(2));
    expect(auth.providers, isEmpty);
    for (final credential in auth.credentials) {
      expect(credential.providerId, GoogleAuthProvider.PROVIDER_ID);
      expect((credential as OAuthCredential).idToken, 'native-google-id-token');
    }
  });

  test('sign-in clears an earlier Google session before requesting a fresh account', () async {
    await repository.signInWithGoogle();

    expect(google.events, ['signOut', 'authenticate']);
    expect(auth.credentials, hasLength(1));
    expect(auth.providers, isEmpty);
  });

  test('failed Google session cleanup stops authentication and uses the Firebase error contract', () async {
    google.signOutError = PlatformException(code: 'Clear Failed', message: 'Google sign-out failed');

    await expectLater(
      repository.signInWithGoogle(),
      throwsA(
        isA<FirebaseAuthException>()
            .having((error) => error.code, 'code', 'google-sign-in-failed')
            .having((error) => error.message, 'message', 'Google sign-out failed'),
      ),
    );

    expect(google.events, ['signOut']);
    expect(auth.credentials, isEmpty);
    expect(auth.providers, isEmpty);
  });

  test('iOS Google sign-in retains the Firebase provider flow and hosted domain', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await repository.signInWithGoogle();

    final provider = auth.providers.single as GoogleAuthProvider;
    expect(provider.providerId, GoogleAuthProvider.PROVIDER_ID);
    expect(provider.parameters, {'hd': 'example.com'});
    expect(auth.credentials, isEmpty);
    expect(google.events, isEmpty);
  });

  test('iOS Google account deletion retains provider reauthentication and hosted domain', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final user = _User([GoogleAuthProvider.PROVIDER_ID]);
    auth.currentUser = user;

    await repository.deleteAccount(beforeDelete: () async => user.events.add('beforeDelete'));

    final provider = user.providers.single as GoogleAuthProvider;
    expect(provider.providerId, GoogleAuthProvider.PROVIDER_ID);
    expect(provider.parameters, {'hd': 'example.com'});
    expect(user.events, ['reauthenticateWithProvider', 'beforeDelete', 'delete']);
    expect(user.credentials, isEmpty);
    expect(google.events, isEmpty);
  });

  test('iOS sign-out keeps the Firebase session flow without invoking the Google plugin', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    auth.currentUser = _User([GoogleAuthProvider.PROVIDER_ID]);

    await repository.signOut();

    expect(auth.signOutCount, 1);
    expect(google.events, isEmpty);
  });

  for (final entry in {
    GoogleSignInExceptionCode.canceled: 'canceled',
    GoogleSignInExceptionCode.userMismatch: 'user-mismatch',
    GoogleSignInExceptionCode.clientConfigurationError: 'google-sign-in-failed',
  }.entries) {
    test('maps native ${entry.key.name} to the existing Firebase error contract', () async {
      google.authenticationError = GoogleSignInException(code: entry.key, description: 'Native failure');

      await expectLater(
        repository.signInWithGoogle(),
        throwsA(
          isA<FirebaseAuthException>()
              .having((error) => error.code, 'code', entry.value)
              .having((error) => error.message, 'message', 'Native failure'),
        ),
      );
      expect(auth.credentials, isEmpty);
    });
  }

  for (final token in <String?>[null, '']) {
    test('rejects a ${token == null ? 'missing' : 'blank'} Google ID token before contacting Firebase', () async {
      google.idToken = token;

      await expectLater(
        repository.signInWithGoogle(),
        throwsA(isA<FirebaseAuthException>().having((error) => error.code, 'code', 'invalid-credential')),
      );
      expect(auth.credentials, isEmpty);
    });
  }

  test('preserves Firebase credential exchange errors', () async {
    final failure = FirebaseAuthException(code: 'account-exists-with-different-credential');
    auth.credentialError = failure;

    await expectLater(repository.signInWithGoogle(), throwsA(same(failure)));
  });

  test('account deletion reauthenticates with a native token before deleting user data and the account', () async {
    final user = _User([GoogleAuthProvider.PROVIDER_ID]);
    auth.currentUser = user;

    await repository.deleteAccount(beforeDelete: () async => user.events.add('beforeDelete'));

    expect(google.events, ['signOut', 'authenticate']);
    expect(user.credentials.single.providerId, GoogleAuthProvider.PROVIDER_ID);
    expect((user.credentials.single as OAuthCredential).idToken, 'native-google-id-token');
    expect(user.events, ['reauthenticate', 'beforeDelete', 'delete']);
    expect(user.providers, isEmpty);
    expect(auth.credentials, isEmpty);
  });

  test('canceling account reauthentication leaves user data and the account intact', () async {
    final user = _User([GoogleAuthProvider.PROVIDER_ID]);
    auth.currentUser = user;
    google.authenticationError = const GoogleSignInException(code: GoogleSignInExceptionCode.canceled);

    await expectLater(
      repository.deleteAccount(beforeDelete: () async => user.events.add('beforeDelete')),
      throwsA(isA<FirebaseAuthException>().having((error) => error.code, 'code', 'canceled')),
    );
    expect(user.credentials, isEmpty);
    expect(user.events, isEmpty);
  });

  test('a different Google account cannot delete the signed-in Firebase account or its data', () async {
    final user = _User([GoogleAuthProvider.PROVIDER_ID]);
    final failure = FirebaseAuthException(code: 'user-mismatch');
    user.reauthenticationError = failure;
    auth.currentUser = user;

    await expectLater(
      repository.deleteAccount(beforeDelete: () async => user.events.add('beforeDelete')),
      throwsA(same(failure)),
    );
    expect(user.events, ['reauthenticate']);
    expect(auth.credentials, isEmpty);
  });

  test('a failed data deletion leaves the reauthenticated Firebase account intact', () async {
    final user = _User([GoogleAuthProvider.PROVIDER_ID]);
    final failure = StateError('Data deletion failed');
    auth.currentUser = user;

    await expectLater(repository.deleteAccount(beforeDelete: () async => throw failure), throwsA(same(failure)));
    expect(user.events, ['reauthenticate']);
  });

  test('email account deletion continues to reauthenticate with a password without Google', () async {
    final user = _User([EmailAuthProvider.PROVIDER_ID]);
    auth.currentUser = user;

    await repository.deleteAccount(password: 'test-password');

    expect(user.credentials.single.providerId, EmailAuthProvider.PROVIDER_ID);
    expect(user.events, ['reauthenticate', 'delete']);
    expect(google.events, isEmpty);
  });

  test('signing out a Google account clears both Google and Firebase sessions', () async {
    auth.currentUser = _User([GoogleAuthProvider.PROVIDER_ID]);

    await repository.signOut();

    expect(google.events, ['signOut']);
    expect(auth.signOutCount, 1);
  });

  test('Google sign-out failure still signs out Firebase', () async {
    auth.currentUser = _User([GoogleAuthProvider.PROVIDER_ID]);
    google.signOutError = PlatformException(code: 'Clear Failed', message: 'Google sign-out failed');

    await expectLater(
      repository.signOut(),
      throwsA(
        isA<FirebaseAuthException>()
            .having((error) => error.code, 'code', 'google-sign-in-failed')
            .having((error) => error.message, 'message', 'Google sign-out failed'),
      ),
    );

    expect(google.events, ['signOut']);
    expect(auth.signOutCount, 1);
  });

  test('signing out an email-only account does not invoke Google', () async {
    auth.currentUser = _User([EmailAuthProvider.PROVIDER_ID]);

    await repository.signOut();

    expect(google.events, isEmpty);
    expect(auth.signOutCount, 1);
  });

  test('signing out without a current user does not invoke Google', () async {
    await repository.signOut();

    expect(google.events, isEmpty);
    expect(auth.signOutCount, 1);
  });
}

class _GooglePlatform extends GoogleSignInPlatform {
  final initializations = <InitParameters>[];
  final events = <String>[];
  Completer<void>? initializationGate;
  String? idToken;
  GoogleSignInException? authenticationError;
  Object? signOutError;

  void reset() {
    events.clear();
    initializationGate = null;
    idToken = 'native-google-id-token';
    authenticationError = null;
    signOutError = null;
  }

  @override
  Future<void> init(InitParameters params) async {
    initializations.add(params);
    await initializationGate?.future;
  }

  @override
  Future<AuthenticationResults> authenticate(AuthenticateParameters params) async {
    events.add('authenticate');
    if (authenticationError case final error?) {
      throw error;
    }
    return AuthenticationResults(
      user: const GoogleSignInUserData(email: 'attendee@example.com', id: 'google-user'),
      authenticationTokens: AuthenticationTokenData(idToken: idToken),
    );
  }

  @override
  Future<void> signOut(SignOutParams params) async {
    events.add('signOut');
    if (signOutError case final error?) {
      throw error;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected Google API: ${invocation.memberName}');
}

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? currentUser;

  final credentials = <AuthCredential>[];
  final providers = <AuthProvider>[];
  Object? credentialError;
  var signOutCount = 0;

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    credentials.add(credential);
    if (credentialError case final error?) {
      throw error;
    }
    return _UserCredential();
  }

  @override
  Future<UserCredential> signInWithProvider(AuthProvider provider) async {
    providers.add(provider);
    return _UserCredential();
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    currentUser = null;
  }
}

class _User extends Fake implements User {
  _User(List<String> providers) : providerData = providers.map(_UserInfo.new).toList();

  @override
  final List<UserInfo> providerData;

  @override
  String get email => 'attendee@example.com';

  final credentials = <AuthCredential>[];
  final providers = <AuthProvider>[];
  final events = <String>[];
  Object? reauthenticationError;

  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) async {
    events.add('reauthenticate');
    credentials.add(credential);
    if (reauthenticationError case final error?) {
      throw error;
    }
    return _UserCredential();
  }

  @override
  Future<UserCredential> reauthenticateWithProvider(AuthProvider provider) async {
    events.add('reauthenticateWithProvider');
    providers.add(provider);
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
