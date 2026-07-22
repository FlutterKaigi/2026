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
	@override late final _Translations$sponsors$en sponsors = _Translations$sponsors$en._(_root);
	@override late final _Translations$sessionTimetable$en sessionTimetable = _Translations$sessionTimetable$en._(_root);
	@override late final _Translations$sessionDetails$en sessionDetails = _Translations$sessionDetails$en._(_root);
	@override late final _Translations$sessionBookmark$en sessionBookmark = _Translations$sessionBookmark$en._(_root);
	@override late final _Translations$bookmarkedSessions$en bookmarkedSessions = _Translations$bookmarkedSessions$en._(_root);
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
	@override String get sessions => 'Sessions';
	@override String get sponsors => 'Sponsors';
	@override String get info => 'Info';
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

// Path: sponsors
class _Translations$sponsors$en extends Translations$sponsors$ja {
	_Translations$sponsors$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Sponsors';
	@override String get subtitle => 'The sponsors supporting FlutterKaigi 2026';
	@override String get empty => 'Sponsors have not been published yet';
	@override String get error => 'Failed to load sponsors';
	@override String logoSemanticLabel({required Object name}) => '${name} logo';
}

// Path: sessionTimetable
class _Translations$sessionTimetable$en extends Translations$sessionTimetable$ja {
	_Translations$sessionTimetable$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Timetable';
	@override String dayButtonLabel({required Object day, required Object date}) => 'Day ${day} (${date})';
	@override String get empty => 'The timetable has not been published yet';
	@override String get emptyFiltered => 'There are no items for the selected venue';
	@override String get error => 'Failed to load timetable';
	@override late final _Translations$sessionTimetable$timeFormat$en timeFormat = _Translations$sessionTimetable$timeFormat$en._(_root);
	@override late final _Translations$sessionTimetable$venue$en venue = _Translations$sessionTimetable$venue$en._(_root);
	@override late final _Translations$sessionTimetable$speaker$en speaker = _Translations$sessionTimetable$speaker$en._(_root);
	@override late final _Translations$sessionTimetable$type$en type = _Translations$sessionTimetable$type$en._(_root);
}

// Path: sessionDetails
class _Translations$sessionDetails$en extends Translations$sessionDetails$ja {
	_Translations$sessionDetails$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Session Details';
	@override String get description => 'Description';
	@override String get schedule => 'Schedule and Venue';
	@override String get speakers => 'Speakers';
	@override String get links => 'Links';
	@override String get sessionize => 'Sessionize';
	@override String get share => 'Share';
	@override String get notFound => 'Session not found';
	@override String get error => 'Failed to load session';
}

// Path: sessionBookmark
class _Translations$sessionBookmark$en extends Translations$sessionBookmark$ja {
	_Translations$sessionBookmark$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get openBookmarked => 'Bookmarked sessions';
	@override String get add => 'Add bookmark';
	@override String get remove => 'Remove bookmark';
	@override String get updateFailed => 'Failed to update bookmark';
}

// Path: bookmarkedSessions
class _Translations$bookmarkedSessions$en extends Translations$bookmarkedSessions$ja {
	_Translations$bookmarkedSessions$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bookmarked Sessions';
	@override String get emptyTitle => 'No bookmarked sessions';
	@override String get emptyBody => 'Bookmark sessions to find them here.';
	@override String get openSessions => 'Open sessions';
	@override String get error => 'Failed to load bookmarked sessions';
}

// Path: eventInfo
class _Translations$eventInfo$en extends Translations$eventInfo$ja {
	_Translations$eventInfo$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Info';
	@override String get version => 'Version';
	@override late final _Translations$eventInfo$themeMode$en themeMode = _Translations$eventInfo$themeMode$en._(_root);
	@override late final _Translations$eventInfo$language$en language = _Translations$eventInfo$language$en._(_root);
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

// Path: sessionTimetable.timeFormat
class _Translations$sessionTimetable$timeFormat$en extends Translations$sessionTimetable$timeFormat$ja {
	_Translations$sessionTimetable$timeFormat$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get twentyFourHour => '24 Hour';
	@override String get amPm => 'AM/PM';
}

// Path: sessionTimetable.venue
class _Translations$sessionTimetable$venue$en extends Translations$sessionTimetable$venue$ja {
	_Translations$sessionTimetable$venue$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get all => 'All';
	@override String get unknown => 'Venue TBA';
}

// Path: sessionTimetable.speaker
class _Translations$sessionTimetable$speaker$en extends Translations$sessionTimetable$speaker$ja {
	_Translations$sessionTimetable$speaker$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get none => 'Speaker TBA';
}

// Path: sessionTimetable.type
class _Translations$sessionTimetable$type$en extends Translations$sessionTimetable$type$ja {
	_Translations$sessionTimetable$type$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get regular => 'Regular Talk';
	@override String get lightningTalk => 'Lightning Talk';
	@override String get beginnersLightningTalk => 'Beginners LT';
	@override String get handsOn => 'Hands-on';
	@override String get event => 'Event';
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

// Path: eventInfo.language
class _Translations$eventInfo$language$en extends Translations$eventInfo$language$ja {
	_Translations$eventInfo$language$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Language';
	@override String get japanese => '日本語';
	@override String get english => 'English';
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
			'navigation.sessions' => 'Sessions',
			'navigation.sponsors' => 'Sponsors',
			'navigation.info' => 'Info',
			'news.title' => 'News',
			'news.empty' => 'There is no news yet',
			'news.error' => 'Failed to load news',
			'sponsors.title' => 'Sponsors',
			'sponsors.subtitle' => 'The sponsors supporting FlutterKaigi 2026',
			'sponsors.empty' => 'Sponsors have not been published yet',
			'sponsors.error' => 'Failed to load sponsors',
			'sponsors.logoSemanticLabel' => ({required Object name}) => '${name} logo',
			'sessionTimetable.title' => 'Timetable',
			'sessionTimetable.dayButtonLabel' => ({required Object day, required Object date}) => 'Day ${day} (${date})',
			'sessionTimetable.empty' => 'The timetable has not been published yet',
			'sessionTimetable.emptyFiltered' => 'There are no items for the selected venue',
			'sessionTimetable.error' => 'Failed to load timetable',
			'sessionTimetable.timeFormat.twentyFourHour' => '24 Hour',
			'sessionTimetable.timeFormat.amPm' => 'AM/PM',
			'sessionTimetable.venue.all' => 'All',
			'sessionTimetable.venue.unknown' => 'Venue TBA',
			'sessionTimetable.speaker.none' => 'Speaker TBA',
			'sessionTimetable.type.regular' => 'Regular Talk',
			'sessionTimetable.type.lightningTalk' => 'Lightning Talk',
			'sessionTimetable.type.beginnersLightningTalk' => 'Beginners LT',
			'sessionTimetable.type.handsOn' => 'Hands-on',
			'sessionTimetable.type.event' => 'Event',
			'sessionDetails.title' => 'Session Details',
			'sessionDetails.description' => 'Description',
			'sessionDetails.schedule' => 'Schedule and Venue',
			'sessionDetails.speakers' => 'Speakers',
			'sessionDetails.links' => 'Links',
			'sessionDetails.sessionize' => 'Sessionize',
			'sessionDetails.share' => 'Share',
			'sessionDetails.notFound' => 'Session not found',
			'sessionDetails.error' => 'Failed to load session',
			'sessionBookmark.openBookmarked' => 'Bookmarked sessions',
			'sessionBookmark.add' => 'Add bookmark',
			'sessionBookmark.remove' => 'Remove bookmark',
			'sessionBookmark.updateFailed' => 'Failed to update bookmark',
			'bookmarkedSessions.title' => 'Bookmarked Sessions',
			'bookmarkedSessions.emptyTitle' => 'No bookmarked sessions',
			'bookmarkedSessions.emptyBody' => 'Bookmark sessions to find them here.',
			'bookmarkedSessions.openSessions' => 'Open sessions',
			'bookmarkedSessions.error' => 'Failed to load bookmarked sessions',
			'eventInfo.title' => 'Info',
			'eventInfo.version' => 'Version',
			'eventInfo.themeMode.title' => 'Theme',
			'eventInfo.themeMode.system' => 'System',
			'eventInfo.themeMode.light' => 'Light',
			'eventInfo.themeMode.dark' => 'Dark',
			'eventInfo.language.title' => 'Language',
			'eventInfo.language.japanese' => '日本語',
			'eventInfo.language.english' => 'English',
			'notFound.title' => 'Page not found',
			'notFound.description' => 'The page you are looking for does not exist or may have moved.',
			'common.retry' => 'Retry',
			_ => null,
		};
	}
}
