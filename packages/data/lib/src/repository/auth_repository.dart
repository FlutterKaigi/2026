import 'dart:io';

import 'package:data/src/firebase/firebase_initializer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

abstract interface class AuthRepository {
  Stream<User?> authStateChanges();
  User? get currentUser;
  Future<void> signInWithGoogle();
  Future<void> signInAnonymously();
  Future<void> signInWithApple();
  Future<void> signInWithEmailAndPassword({required String email, required String password});
  Future<void> createUserWithEmailAndPassword({required String email, required String password});
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> signOut();

  /// 現在のユーザーを再認証してから完全に削除する。
  ///
  /// メール+パスワードのユーザーは再認証のため [password] が必須。
  Future<void> deleteAccount({String? password});
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
  User? get currentUser => _auth.currentUser;

  @override
  Future<void> signInWithGoogle() {
    return _signInWithOAuth(_googleProvider());
  }

  @override
  Future<void> signInAnonymously() => _auth.signInAnonymously();

  @override
  Future<void> signInWithApple() {
    if (kIsWeb || !Platform.isIOS) {
      throw UnsupportedError('AppleサインインはiOSでのみ利用できます');
    }
    return _auth.signInWithProvider(_appleProvider());
  }

  GoogleAuthProvider _googleProvider() {
    final provider = GoogleAuthProvider();
    if (hostedDomain != null) {
      provider.setCustomParameters({'hd': hostedDomain!});
    }
    return provider;
  }

  AppleAuthProvider _appleProvider() => AppleAuthProvider()
    ..addScope('email')
    ..addScope('name');

  /// GoogleはWebではポップアップ、モバイルではsignInWithProviderで
  /// サインインする。
  ///
  /// Auth Emulator接続時は全プラットフォームでEmulatorの擬似IdP画面が
  /// 開く。
  Future<void> _signInWithOAuth(AuthProvider provider) {
    if (kIsWeb) {
      return _auth.signInWithPopup(provider);
    }
    if (Platform.isAndroid || Platform.isIOS) {
      return _auth.signInWithProvider(provider);
    }
    throw UnsupportedError('サポートされていないプラットフォームです');
  }

  @override
  Future<void> signInWithEmailAndPassword({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  @override
  Future<void> createUserWithEmailAndPassword({required String email, required String password}) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  @override
  Future<void> sendPasswordResetEmail({required String email}) => _auth.sendPasswordResetEmail(email: email);

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('サインインしていないためアカウントを削除できません');
    }

    // `requires-recent-login` の分岐をなくすため削除の直前に必ず再認証する。
    // Apple はトークン失効(App Store Review Guideline 5.1.1(v))に必要な
    // authorizationCode も再認証で取得する。
    final providerIds = user.providerData.map((info) => info.providerId).toSet();
    final usesApple = providerIds.contains(AppleAuthProvider.PROVIDER_ID);
    if (usesApple && (kIsWeb || !Platform.isIOS)) {
      // Web / Android のApple OAuthを開始するとServices IDが必要になる。
      // Apple連携済みアカウントの削除とトークン失効はiOSからだけ行う。
      throw FirebaseAuthException(
        code: 'apple-token-revocation-failed',
        message: 'Apple連携済みアカウントはiOSアプリから削除してください',
      );
    }
    UserCredential? appleCredential;
    if (providerIds.contains(EmailAuthProvider.PROVIDER_ID)) {
      final email = user.email;
      if (password == null || email == null) {
        throw ArgumentError('メール+パスワードのユーザーの削除には password が必要です');
      }
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    } else if (providerIds.contains(GoogleAuthProvider.PROVIDER_ID)) {
      await _reauthenticateWithOAuth(user, _googleProvider());
    } else if (providerIds.contains(AppleAuthProvider.PROVIDER_ID)) {
      appleCredential = await _reauthenticateWithOAuth(user, _appleProvider());
    }

    // Apple が他のプロバイダーとリンクされている場合も必ず失効する。
    // 上の再認証で Apple を使っていなければ、失効用トークンを得るために
    // Apple でもう一度再認証する。
    if (usesApple) {
      appleCredential ??= await _reauthenticateWithOAuth(user, _appleProvider());
      await _revokeAppleToken(appleCredential);
    }

    await user.delete();
  }

  Future<UserCredential> _reauthenticateWithOAuth(User user, AuthProvider provider) {
    if (kIsWeb) {
      return user.reauthenticateWithPopup(provider);
    }
    if (Platform.isAndroid || Platform.isIOS) {
      return user.reauthenticateWithProvider(provider);
    }
    throw UnsupportedError('サポートされていないプラットフォームです');
  }

  /// アカウント削除前に Apple ID のトークンを失効させる。
  ///
  /// Apple はアカウント削除時のトークン失効を要求しているため、失効に失敗した
  /// 場合は例外を伝播させて削除自体を中断する。
  /// https://developer.apple.com/support/offering-account-deletion-in-your-app/
  Future<void> _revokeAppleToken(UserCredential credential) async {
    // Auth Emulator は失効エンドポイントを提供しないため、Emulator接続時のみ
    // 明示的にスキップする。
    if (FirebaseInitializer.emulatorConfigured) {
      return;
    }
    if (kIsWeb || !Platform.isIOS) {
      throw UnsupportedError('Appleアカウントの削除はiOSでのみ利用できます');
    }
    final authorizationCode = credential.additionalUserInfo?.authorizationCode;
    if (authorizationCode == null) {
      throw FirebaseAuthException(
        code: 'apple-token-revocation-failed',
        message: '再認証結果に authorizationCode が含まれていないためトークンを失効できません',
      );
    }
    await _auth.revokeTokenWithAuthorizationCode(authorizationCode);
  }
}
