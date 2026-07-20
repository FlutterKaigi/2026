///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsEn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsEn _root = this; // ignore: unused_field

	@override 
	TranslationsEn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEn(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$en app = _Translations$app$en._(_root);
	@override late final _Translations$navigation$en navigation = _Translations$navigation$en._(_root);
	@override late final _Translations$news$en news = _Translations$news$en._(_root);
	@override late final _Translations$liveCaptions$en liveCaptions = _Translations$liveCaptions$en._(_root);
	@override late final _Translations$eventInfo$en eventInfo = _Translations$eventInfo$en._(_root);
	@override late final _Translations$notFound$en notFound = _Translations$notFound$en._(_root);
	@override late final _Translations$common$en common = _Translations$common$en._(_root);
}

// Path: app
class _Translations$app$en extends Translations$app$ja {
	_Translations$app$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'FlutterKaigi 2026';
}

// Path: navigation
class _Translations$navigation$en extends Translations$navigation$ja {
	_Translations$navigation$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get news => 'News';
	@override String get captions => 'Captions';
	@override String get info => 'Event Info';
}

// Path: news
class _Translations$news$en extends Translations$news$ja {
	_Translations$news$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'News';
	@override String get empty => 'There is no news yet';
	@override String get error => 'Failed to load news';
}

// Path: liveCaptions
class _Translations$liveCaptions$en extends Translations$liveCaptions$ja {
	_Translations$liveCaptions$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Live Captions';
	@override String get description => 'Pick a session or scan the QR code in the room to see live translated captions';
	@override String get live => 'LIVE';
	@override String get sessionsEmpty => 'Sessions have not been published yet';
	@override String get sessionsError => 'Failed to load sessions';
	@override String get scanQr => 'Scan QR code';
	@override late final _Translations$liveCaptions$room$en room = _Translations$liveCaptions$room$en._(_root);
	@override late final _Translations$liveCaptions$scan$en scan = _Translations$liveCaptions$scan$en._(_root);
}

// Path: eventInfo
class _Translations$eventInfo$en extends Translations$eventInfo$ja {
	_Translations$eventInfo$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Event Info';
	@override String get version => 'Version';
	@override late final _Translations$eventInfo$themeMode$en themeMode = _Translations$eventInfo$themeMode$en._(_root);
}

// Path: notFound
class _Translations$notFound$en extends Translations$notFound$ja {
	_Translations$notFound$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Page not found';
	@override String get description => 'The page you are looking for does not exist or may have moved.';
}

// Path: common
class _Translations$common$en extends Translations$common$ja {
	_Translations$common$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get retry => 'Retry';
}

// Path: liveCaptions.room
class _Translations$liveCaptions$room$en extends Translations$liveCaptions$room$ja {
	_Translations$liveCaptions$room$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get notLive => 'This room is not streaming right now';
	@override String get disabled => 'Captions are currently turned off';
	@override String get waiting => 'Captions will appear here once streaming starts';
	@override String get empty => 'No captions yet';
	@override String get error => 'Failed to load captions';
	@override String get original => 'Original';
}

// Path: liveCaptions.scan
class _Translations$liveCaptions$scan$en extends Translations$liveCaptions$scan$ja {
	_Translations$liveCaptions$scan$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Scan QR code';
	@override String get instruction => 'Scan the QR code posted in the room';
	@override String get manualLabel => 'Enter a room ID directly';
	@override String get manualHint => 'hall-a';
	@override String get open => 'Open';
	@override String get invalid => 'This QR code does not point to captions';
	@override String get cameraError => 'Camera is unavailable. Enter the room ID directly instead';
}

// Path: eventInfo.themeMode
class _Translations$eventInfo$themeMode$en extends Translations$eventInfo$themeMode$ja {
	_Translations$eventInfo$themeMode$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Theme';
	@override String get system => 'System';
	@override String get light => 'Light';
	@override String get dark => 'Dark';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'FlutterKaigi 2026',
			'navigation.news' => 'News',
			'navigation.captions' => 'Captions',
			'navigation.info' => 'Event Info',
			'news.title' => 'News',
			'news.empty' => 'There is no news yet',
			'news.error' => 'Failed to load news',
			'liveCaptions.title' => 'Live Captions',
			'liveCaptions.description' => 'Pick a session or scan the QR code in the room to see live translated captions',
			'liveCaptions.live' => 'LIVE',
			'liveCaptions.sessionsEmpty' => 'Sessions have not been published yet',
			'liveCaptions.sessionsError' => 'Failed to load sessions',
			'liveCaptions.scanQr' => 'Scan QR code',
			'liveCaptions.room.notLive' => 'This room is not streaming right now',
			'liveCaptions.room.disabled' => 'Captions are currently turned off',
			'liveCaptions.room.waiting' => 'Captions will appear here once streaming starts',
			'liveCaptions.room.empty' => 'No captions yet',
			'liveCaptions.room.error' => 'Failed to load captions',
			'liveCaptions.room.original' => 'Original',
			'liveCaptions.scan.title' => 'Scan QR code',
			'liveCaptions.scan.instruction' => 'Scan the QR code posted in the room',
			'liveCaptions.scan.manualLabel' => 'Enter a room ID directly',
			'liveCaptions.scan.manualHint' => 'hall-a',
			'liveCaptions.scan.open' => 'Open',
			'liveCaptions.scan.invalid' => 'This QR code does not point to captions',
			'liveCaptions.scan.cameraError' => 'Camera is unavailable. Enter the room ID directly instead',
			'eventInfo.title' => 'Event Info',
			'eventInfo.version' => 'Version',
			'eventInfo.themeMode.title' => 'Theme',
			'eventInfo.themeMode.system' => 'System',
			'eventInfo.themeMode.light' => 'Light',
			'eventInfo.themeMode.dark' => 'Dark',
			'notFound.title' => 'Page not found',
			'notFound.description' => 'The page you are looking for does not exist or may have moved.',
			'common.retry' => 'Retry',
			_ => null,
		};
	}
}
