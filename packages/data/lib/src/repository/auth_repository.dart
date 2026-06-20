import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

abstract interface class AuthRepository {
  Stream<User?> authStateChanges();
  Future<void> signInWithGoogle();
  Future<void> signOut();
}

final class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<void> signInWithGoogle() {
    if (kIsWeb) return _auth.signInWithPopup(GoogleAuthProvider());
    if (Platform.isAndroid || Platform.isIOS) {
      throw UnimplementedError('google_sign_in パッケージを追加して実装する');
    }
    throw UnimplementedError('サポートされていないプラットフォームです');
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
