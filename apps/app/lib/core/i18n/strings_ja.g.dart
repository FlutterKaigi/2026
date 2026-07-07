///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsJa = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ja,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ja>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$app$ja app = Translations$app$ja.internal(_root);
	late final Translations$navigation$ja navigation = Translations$navigation$ja.internal(_root);
	late final Translations$news$ja news = Translations$news$ja.internal(_root);
	late final Translations$eventInfo$ja eventInfo = Translations$eventInfo$ja.internal(_root);
	late final Translations$notFound$ja notFound = Translations$notFound$ja.internal(_root);
	late final Translations$common$ja common = Translations$common$ja.internal(_root);
}

// Path: app
class Translations$app$ja {
	Translations$app$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'FlutterKaigi 2026'
	String get title => 'FlutterKaigi 2026';
}

// Path: navigation
class Translations$navigation$ja {
	Translations$navigation$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'お知らせ'
	String get news => 'お知らせ';

	/// ja: 'イベント情報'
	String get info => 'イベント情報';
}

// Path: news
class Translations$news$ja {
	Translations$news$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'お知らせ'
	String get title => 'お知らせ';

	/// ja: 'お知らせはまだありません'
	String get empty => 'お知らせはまだありません';

	/// ja: 'お知らせを取得できませんでした'
	String get error => 'お知らせを取得できませんでした';
}

// Path: eventInfo
class Translations$eventInfo$ja {
	Translations$eventInfo$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'イベント情報'
	String get title => 'イベント情報';

	/// ja: 'バージョン'
	String get version => 'バージョン';

	late final Translations$eventInfo$themeMode$ja themeMode = Translations$eventInfo$themeMode$ja.internal(_root);
	late final Translations$eventInfo$language$ja language = Translations$eventInfo$language$ja.internal(_root);
}

// Path: notFound
class Translations$notFound$ja {
	Translations$notFound$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'ページが見つかりません'
	String get title => 'ページが見つかりません';

	/// ja: 'お探しのページは存在しないか、移動した可能性があります。'
	String get description => 'お探しのページは存在しないか、移動した可能性があります。';
}

// Path: common
class Translations$common$ja {
	Translations$common$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '再試行'
	String get retry => '再試行';
}

// Path: eventInfo.themeMode
class Translations$eventInfo$themeMode$ja {
	Translations$eventInfo$themeMode$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'テーマ'
	String get title => 'テーマ';

	/// ja: 'システムに合わせる'
	String get system => 'システムに合わせる';

	/// ja: 'ライト'
	String get light => 'ライト';

	/// ja: 'ダーク'
	String get dark => 'ダーク';
}

// Path: eventInfo.language
class Translations$eventInfo$language$ja {
	Translations$eventInfo$language$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '表示言語'
	String get title => '表示言語';

	/// ja: '日本語'
	String get japanese => '日本語';

	/// ja: 'English'
	String get english => 'English';
}

/// The flat map containing all translations for locale <ja>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'FlutterKaigi 2026',
			'navigation.news' => 'お知らせ',
			'navigation.info' => 'イベント情報',
			'news.title' => 'お知らせ',
			'news.empty' => 'お知らせはまだありません',
			'news.error' => 'お知らせを取得できませんでした',
			'eventInfo.title' => 'イベント情報',
			'eventInfo.version' => 'バージョン',
			'eventInfo.themeMode.title' => 'テーマ',
			'eventInfo.themeMode.system' => 'システムに合わせる',
			'eventInfo.themeMode.light' => 'ライト',
			'eventInfo.themeMode.dark' => 'ダーク',
			'eventInfo.language.title' => '表示言語',
			'eventInfo.language.japanese' => '日本語',
			'eventInfo.language.english' => 'English',
			'notFound.title' => 'ページが見つかりません',
			'notFound.description' => 'お探しのページは存在しないか、移動した可能性があります。',
			'common.retry' => '再試行',
			_ => null,
		};
	}
}
