import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  // 管理ダッシュボードは flutterkaigi.jp ドメインへサインインを誘導する（UI ヒント）。
  (_) => FirebaseAuthRepository(hostedDomain: 'flutterkaigi.jp'),
);

