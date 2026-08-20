import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/core/env.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final collectionSyncServiceProvider = Provider<CollectionSyncService>(
  (_) => CollectionSyncService(),
);

/// 本番環境へ反映できる Firestore コレクション。
///
/// [id] は Firestore のコレクション名で、Cloud Functions 側の許可リストと一致させる。
enum SyncCollection {
  sponsors('sponsors', 'スポンサー'),
  news('news', 'ニュース'),
  venues('venues', '会場'),
  speakers('speakers', 'スピーカー'),
  sessions('sessions', 'セッション'),
  timelineEvents('timelineEvents', 'タイムライン');

  const SyncCollection(this.id, this.label);

  final String id;
  final String label;
}

/// 反映ボタン 1 つで扱う単位。相互に参照を持つコレクションはまとめて反映する。
enum SyncTarget {
  news('ニュース', [SyncCollection.news]),
  sponsors('スポンサー', [SyncCollection.sponsors]),

  /// セッション・スピーカー・会場・タイムラインは相互に参照を持つため一括で反映する。
  sessionData('セッション情報', [
    SyncCollection.venues,
    SyncCollection.speakers,
    SyncCollection.sessions,
    SyncCollection.timelineEvents,
  ]);

  const SyncTarget(this.label, this.collections);

  final String label;
  final List<SyncCollection> collections;
}

/// コレクション 1 つ分の反映件数。
class CollectionSyncCount {
  const CollectionSyncCount({
    required this.collection,
    required this.created,
    required this.updated,
    required this.deleted,
    required this.total,
  });

  factory CollectionSyncCount.fromJson(Map<String, dynamic> json) => CollectionSyncCount(
    collection: json['collection'] as String? ?? '',
    created: (json['created'] as num?)?.toInt() ?? 0,
    updated: (json['updated'] as num?)?.toInt() ?? 0,
    deleted: (json['deleted'] as num?)?.toInt() ?? 0,
    total: (json['total'] as num?)?.toInt() ?? 0,
  );

  final String collection;
  final int created;
  final int updated;
  final int deleted;
  final int total;

  /// Firestore のコレクション名に対応する日本語ラベル（未知の場合はコレクション名のまま）。
  String get label {
    for (final syncCollection in SyncCollection.values) {
      if (syncCollection.id == collection) return syncCollection.label;
    }
    return collection;
  }
}

/// `syncCollectionsToProd` callable function の実行結果。
class CollectionSyncResult {
  const CollectionSyncResult({
    required this.dryRun,
    required this.created,
    required this.updated,
    required this.deleted,
    required this.total,
    required this.collections,
  });

  factory CollectionSyncResult.fromJson(Map<String, dynamic> json) => CollectionSyncResult(
    dryRun: json['dryRun'] as bool? ?? false,
    created: (json['created'] as num?)?.toInt() ?? 0,
    updated: (json['updated'] as num?)?.toInt() ?? 0,
    deleted: (json['deleted'] as num?)?.toInt() ?? 0,
    total: (json['total'] as num?)?.toInt() ?? 0,
    collections: (json['collections'] as List<Object?>? ?? [])
        .whereType<Map<Object?, Object?>>()
        .map((e) => CollectionSyncCount.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );

  final bool dryRun;
  final int created;
  final int updated;
  final int deleted;
  final int total;

  /// コレクションごとの内訳（Cloud Functions 側の依存順）。
  final List<CollectionSyncCount> collections;
}

/// STG の指定コレクションを本番環境へ完全ミラーする Cloud Functions を呼び出す。
class CollectionSyncService {
  CollectionSyncService({FirebaseFunctions? functions}) : _functions = functions ?? _defaultFunctions();

  static FirebaseFunctions _defaultFunctions() {
    final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
    if (Flavor.current == Flavor.dev) {
      functions.useFunctionsEmulator('localhost', 5001);
    }
    return functions;
  }

  final FirebaseFunctions _functions;

  /// [dryRun] が true の場合は書き込みを行わず、予定件数のみ取得する。
  Future<CollectionSyncResult> syncToProd({
    required List<SyncCollection> collections,
    required bool dryRun,
  }) async {
    final result = await _functions.httpsCallable('syncCollectionsToProd').call<Object?>({
      'collections': collections.map((c) => c.id).toList(),
      'dryRun': dryRun,
    });
    final data = result.data;
    if (data is! Map) {
      throw StateError('syncCollectionsToProd から不正なレスポンスを受け取りました: $data');
    }
    return CollectionSyncResult.fromJson(Map<String, dynamic>.from(data));
  }
}
