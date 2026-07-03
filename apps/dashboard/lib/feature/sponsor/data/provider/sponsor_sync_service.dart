import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/core/env.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final sponsorSyncServiceProvider = Provider<SponsorSyncService>(
  (_) => SponsorSyncService(),
);

/// `syncSponsorsToProd` callable function の実行結果。
class SponsorSyncResult {
  const SponsorSyncResult({
    required this.dryRun,
    required this.created,
    required this.updated,
    required this.deleted,
    required this.total,
  });

  factory SponsorSyncResult.fromJson(Map<String, dynamic> json) => SponsorSyncResult(
    dryRun: json['dryRun'] as bool? ?? false,
    created: (json['created'] as num?)?.toInt() ?? 0,
    updated: (json['updated'] as num?)?.toInt() ?? 0,
    deleted: (json['deleted'] as num?)?.toInt() ?? 0,
    total: (json['total'] as num?)?.toInt() ?? 0,
  );

  final bool dryRun;
  final int created;
  final int updated;
  final int deleted;
  final int total;
}

/// STG の sponsors コレクションを本番環境へ完全ミラーする Cloud Functions を呼び出す。
class SponsorSyncService {
  SponsorSyncService({FirebaseFunctions? functions}) : _functions = functions ?? _defaultFunctions();

  static FirebaseFunctions _defaultFunctions() {
    final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
    if (Flavor.current == Flavor.dev) {
      functions.useFunctionsEmulator('localhost', 5001);
    }
    return functions;
  }

  final FirebaseFunctions _functions;

  /// [dryRun] が true の場合は書き込みを行わず、予定件数のみ取得する。
  Future<SponsorSyncResult> syncToProd({required bool dryRun}) async {
    final result = await _functions.httpsCallable('syncSponsorsToProd').call<Object?>({'dryRun': dryRun});
    final data = result.data;
    if (data is! Map) {
      throw StateError('syncSponsorsToProd から不正なレスポンスを受け取りました: $data');
    }
    return SponsorSyncResult.fromJson(Map<String, dynamic>.from(data));
  }
}
