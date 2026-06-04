// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(newsRepository)
final newsRepositoryProvider = NewsRepositoryProvider._();

final class NewsRepositoryProvider
    extends $FunctionalProvider<NewsRepository, NewsRepository, NewsRepository>
    with $Provider<NewsRepository> {
  NewsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newsRepositoryHash();

  @$internal
  @override
  $ProviderElement<NewsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NewsRepository create(Ref ref) {
    return newsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NewsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NewsRepository>(value),
    );
  }
}

String _$newsRepositoryHash() => r'25f1294948dc1d005390b80909748f19006d2a1a';

@ProviderFor(news)
final newsProvider = NewsProvider._();

final class NewsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<News>>,
          List<News>,
          FutureOr<List<News>>
        >
    with $FutureModifier<List<News>>, $FutureProvider<List<News>> {
  NewsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newsHash();

  @$internal
  @override
  $FutureProviderElement<List<News>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<News>> create(Ref ref) {
    return news(ref);
  }
}

String _$newsHash() => r'81858b3e4d6156d8bc4d809753f25e23883774e2';
