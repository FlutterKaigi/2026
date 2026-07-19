import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

abstract interface class AuthRepository {
  Stream<User?> authStateChanges();
  Future<void> signInWithGoogle();
  Future<void> signOut();
}

final class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, this.hostedDomain}) : _auth = auth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;

  /// 指定すると Google サインインの `hd` パラメータに渡し、アカウント選択を
  /// 当該ドメインへ誘導する（UI ヒントであり強制力はない。実際の認可は
  /// Firestore ルールの hasAdminAccess で行う）。null の場合は無制限。
  final String? hostedDomain;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<void> signInWithGoogle() {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      if (hostedDomain != null) {
        provider.setCustomParameters({'hd': hostedDomain!});
      }
      return _auth.signInWithPopup(provider);
    }
    if (Platform.isAndroid || Platform.isIOS) {
      throw UnimplementedError('google_sign_in パッケージを追加して実装する');
    }
    throw UnimplementedError('サポートされていないプラットフォームです');
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
