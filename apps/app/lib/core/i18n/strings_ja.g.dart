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
	late final Translations$liveCaptions$ja liveCaptions = Translations$liveCaptions$ja.internal(_root);
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

	/// ja: '字幕'
	String get captions => '字幕';

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

// Path: liveCaptions
class Translations$liveCaptions$ja {
	Translations$liveCaptions$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'ライブ字幕'
	String get title => 'ライブ字幕';

	/// ja: 'セッションを選ぶか、会場内の QR コードを読み取ると同時通訳字幕が表示されます'
	String get description => 'セッションを選ぶか、会場内の QR コードを読み取ると同時通訳字幕が表示されます';

	/// ja: 'LIVE'
	String get live => 'LIVE';

	/// ja: 'セッションはまだ公開されていません'
	String get sessionsEmpty => 'セッションはまだ公開されていません';

	/// ja: 'セッション情報を取得できませんでした'
	String get sessionsError => 'セッション情報を取得できませんでした';

	/// ja: 'QR コードを読み取る'
	String get scanQr => 'QR コードを読み取る';

	late final Translations$liveCaptions$room$ja room = Translations$liveCaptions$room$ja.internal(_root);
	late final Translations$liveCaptions$scan$ja scan = Translations$liveCaptions$scan$ja.internal(_root);
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

// Path: liveCaptions.room
class Translations$liveCaptions$room$ja {
	Translations$liveCaptions$room$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '現在このルームは配信していません'
	String get notLive => '現在このルームは配信していません';

	/// ja: '字幕の配信は現在停止しています'
	String get disabled => '字幕の配信は現在停止しています';

	/// ja: '字幕の配信が始まるとここに表示されます'
	String get waiting => '字幕の配信が始まるとここに表示されます';

	/// ja: '字幕はまだありません'
	String get empty => '字幕はまだありません';

	/// ja: '字幕を取得できませんでした'
	String get error => '字幕を取得できませんでした';

	/// ja: '原文'
	String get original => '原文';
}

// Path: liveCaptions.scan
class Translations$liveCaptions$scan$ja {
	Translations$liveCaptions$scan$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'QR コードを読み取る'
	String get title => 'QR コードを読み取る';

	/// ja: '会場内に掲示された QR コードを読み取ってください'
	String get instruction => '会場内に掲示された QR コードを読み取ってください';

	/// ja: 'ルーム ID を直接入力'
	String get manualLabel => 'ルーム ID を直接入力';

	/// ja: 'hall-a'
	String get manualHint => 'hall-a';

	/// ja: '開く'
	String get open => '開く';

	/// ja: 'この QR コードからは字幕を開けません'
	String get invalid => 'この QR コードからは字幕を開けません';

	/// ja: 'カメラを利用できません。ルーム ID を直接入力してください'
	String get cameraError => 'カメラを利用できません。ルーム ID を直接入力してください';
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
			'navigation.captions' => '字幕',
			'navigation.info' => 'イベント情報',
			'news.title' => 'お知らせ',
			'news.empty' => 'お知らせはまだありません',
			'news.error' => 'お知らせを取得できませんでした',
			'liveCaptions.title' => 'ライブ字幕',
			'liveCaptions.description' => 'セッションを選ぶか、会場内の QR コードを読み取ると同時通訳字幕が表示されます',
			'liveCaptions.live' => 'LIVE',
			'liveCaptions.sessionsEmpty' => 'セッションはまだ公開されていません',
			'liveCaptions.sessionsError' => 'セッション情報を取得できませんでした',
			'liveCaptions.scanQr' => 'QR コードを読み取る',
			'liveCaptions.room.notLive' => '現在このルームは配信していません',
			'liveCaptions.room.disabled' => '字幕の配信は現在停止しています',
			'liveCaptions.room.waiting' => '字幕の配信が始まるとここに表示されます',
			'liveCaptions.room.empty' => '字幕はまだありません',
			'liveCaptions.room.error' => '字幕を取得できませんでした',
			'liveCaptions.room.original' => '原文',
			'liveCaptions.scan.title' => 'QR コードを読み取る',
			'liveCaptions.scan.instruction' => '会場内に掲示された QR コードを読み取ってください',
			'liveCaptions.scan.manualLabel' => 'ルーム ID を直接入力',
			'liveCaptions.scan.manualHint' => 'hall-a',
			'liveCaptions.scan.open' => '開く',
			'liveCaptions.scan.invalid' => 'この QR コードからは字幕を開けません',
			'liveCaptions.scan.cameraError' => 'カメラを利用できません。ルーム ID を直接入力してください',
			'eventInfo.title' => 'イベント情報',
			'eventInfo.version' => 'バージョン',
			'eventInfo.themeMode.title' => 'テーマ',
			'eventInfo.themeMode.system' => 'システムに合わせる',
			'eventInfo.themeMode.light' => 'ライト',
			'eventInfo.themeMode.dark' => 'ダーク',
			'notFound.title' => 'ページが見つかりません',
			'notFound.description' => 'お探しのページは存在しないか、移動した可能性があります。',
			'common.retry' => '再試行',
			_ => null,
		};
	}
}
