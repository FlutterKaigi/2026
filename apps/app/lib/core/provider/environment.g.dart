// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'environment.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(environment)
final environmentProvider = EnvironmentProvider._();

final class EnvironmentProvider
    extends $FunctionalProvider<Environment, Environment, Environment>
    with $Provider<Environment> {
  EnvironmentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'environmentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$environmentHash();

  @$internal
  @override
  $ProviderElement<Environment> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Environment create(Ref ref) {
    return environment(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Environment value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Environment>(value),
    );
  }
}

String _$environmentHash() => r'05c95e9467ac43b1426657960e7469684ba4f23d';
