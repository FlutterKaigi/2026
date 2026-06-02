// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_data_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(firebaseDataClient)
final firebaseDataClientProvider = FirebaseDataClientProvider._();

final class FirebaseDataClientProvider
    extends
        $FunctionalProvider<
          FirebaseDataClient,
          FirebaseDataClient,
          FirebaseDataClient
        >
    with $Provider<FirebaseDataClient> {
  FirebaseDataClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseDataClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseDataClientHash();

  @$internal
  @override
  $ProviderElement<FirebaseDataClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseDataClient create(Ref ref) {
    return firebaseDataClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseDataClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseDataClient>(value),
    );
  }
}

String _$firebaseDataClientHash() =>
    r'a2d0afad5a6b963c9d2f094d7f5e613a8d4a7e83';
