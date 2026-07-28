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
	@override late final _Translations$links$en links = _Translations$links$en._(_root);
	@override late final _Translations$navigation$en navigation = _Translations$navigation$en._(_root);
	@override late final _Translations$news$en news = _Translations$news$en._(_root);
	@override late final _Translations$sponsors$en sponsors = _Translations$sponsors$en._(_root);
	@override late final _Translations$trademarks$en trademarks = _Translations$trademarks$en._(_root);
	@override late final _Translations$sessionTimetable$en sessionTimetable = _Translations$sessionTimetable$en._(_root);
	@override late final _Translations$sessionSearch$en sessionSearch = _Translations$sessionSearch$en._(_root);
	@override late final _Translations$sessionDetails$en sessionDetails = _Translations$sessionDetails$en._(_root);
	@override late final _Translations$sessionBookmark$en sessionBookmark = _Translations$sessionBookmark$en._(_root);
	@override late final _Translations$bookmarkedSessions$en bookmarkedSessions = _Translations$bookmarkedSessions$en._(_root);
	@override late final _Translations$eventInfo$en eventInfo = _Translations$eventInfo$en._(_root);
	@override late final _Translations$settings$en settings = _Translations$settings$en._(_root);
	@override late final _Translations$licenses$en licenses = _Translations$licenses$en._(_root);
	@override late final _Translations$error$en error = _Translations$error$en._(_root);
	@override late final _Translations$notFound$en notFound = _Translations$notFound$en._(_root);
}

// Path: app
class _Translations$app$en extends Translations$app$ja {
	_Translations$app$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'FlutterKaigi 2026';
}

// Path: links
class _Translations$links$en extends Translations$links$ja {
	_Translations$links$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get openError => 'Could not open the link';
}

// Path: navigation
class _Translations$navigation$en extends Translations$navigation$ja {
	_Translations$navigation$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get sessions => 'Sessions';
	@override String get sponsors => 'Sponsors';
	@override String get info => 'Event';
}

// Path: news
class _Translations$news$en extends Translations$news$ja {
	_Translations$news$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'News';
	@override String get empty => 'There is no news yet';
}

// Path: sponsors
class _Translations$sponsors$en extends Translations$sponsors$ja {
	_Translations$sponsors$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Sponsors';
	@override String get detailTitle => 'Sponsor Details';
	@override String get subtitle => 'The sponsors supporting FlutterKaigi 2026';
	@override String get empty => 'Sponsors have not been published yet';
	@override String get notFound => 'Sponsor not found';
	@override String logoSemanticLabel({required Object name}) => '${name} logo';
	@override String tierBadge({required Object tier}) => '${tier} Sponsor';
	@override String get jobBoards => 'Job Boards';
	@override String get jobBoardCta => 'Hiring information';
	@override String get recruitCta => 'Careers';
	@override String get connect => 'Connect';
}

// Path: trademarks
class _Translations$trademarks$en extends Translations$trademarks$ja {
	_Translations$trademarks$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get flutterAffiliation => 'Flutter and the related logo are trademarks of Google LLC. FlutterKaigi is not affiliated with or otherwise sponsored by Google LLC.';
	@override String get flutterNameAndLogo => 'The Flutter name and the Flutter logo are trademarks of Google LLC.';
	@override String get revComm => 'RevComm is a registered trademark or trademark of RevComm Inc.';
}

// Path: sessionTimetable
class _Translations$sessionTimetable$en extends Translations$sessionTimetable$ja {
	_Translations$sessionTimetable$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Timetable';
	@override String dayButtonLabel({required Object day, required Object date}) => 'Day ${day} (${date})';
	@override late final _Translations$sessionTimetable$view$en view = _Translations$sessionTimetable$view$en._(_root);
	@override String get empty => 'The timetable has not been published yet';
	@override String get emptyFiltered => 'There are no items for this day';
	@override late final _Translations$sessionTimetable$venue$en venue = _Translations$sessionTimetable$venue$en._(_root);
	@override late final _Translations$sessionTimetable$speaker$en speaker = _Translations$sessionTimetable$speaker$en._(_root);
	@override late final _Translations$sessionTimetable$type$en type = _Translations$sessionTimetable$type$en._(_root);
}

// Path: sessionSearch
class _Translations$sessionSearch$en extends Translations$sessionSearch$ja {
	_Translations$sessionSearch$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Search sessions';
	@override String get hint => 'Search titles, descriptions, and speakers';
	@override String get clear => 'Clear search';
	@override String get allDates => 'All days';
	@override String get allTypes => 'All types';
	@override String get allLanguages => 'All languages';
	@override String get dateFilter => 'Filter by day';
	@override String get typeFilter => 'Filter by type';
	@override String get languageFilter => 'Filter by language';
	@override String get dateChip => 'Day';
	@override String get typeChip => 'Type';
	@override String get languageChip => 'Language';
	@override String get promptTitle => 'Find a session';
	@override String get promptBody => 'Enter a keyword or select a day, session type, or language';
	@override String get emptyTitle => 'No sessions found';
	@override String get emptyBody => 'Try changing the keyword or filters';
	@override String resultCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} session',
		other: '${n} sessions',
	);
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
}

// Path: eventInfo
class _Translations$eventInfo$en extends Translations$eventInfo$ja {
	_Translations$eventInfo$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Event Overview';
	@override String get newsTitle => 'Latest News';
	@override String get newsSubtitle => 'See the latest FlutterKaigi 2026 updates';
	@override String get logoSemanticLabel => 'FlutterKaigi 2026 logo';
	@override String get tagline => 'Connect, Converse, Ignite.';
	@override String get themeName => '〜Assemble〜';
	@override String get description => 'Japan\'s Flutter tech conference in 2026. Two days for sharing Flutter and Dart expertise and connecting with the community.';
	@override String get dateLabel => 'Date';
	@override String get date => 'October 29–30, 2026';
	@override String get venueLabel => 'Venue';
	@override String get venue => 'Hamamatsucho Convention Hall';
	@override String get viewMap => 'View Map';
	@override String get other => 'Other';
	@override String get officialWebsite => 'Official Website';
	@override String get codeOfConduct => 'Code of Conduct';
	@override String get privacyPolicy => 'Privacy Policy';
	@override String get exclusionPolicy => 'Exclusion of Anti-Social Forces';
	@override String get contact => 'Contact';
	@override String get sourceCode => 'View Source Code';
	@override String get ossLicenses => 'OSS Licenses';
}

// Path: settings
class _Translations$settings$en extends Translations$settings$ja {
	_Translations$settings$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Settings';
	@override String get appearance => 'Appearance';
	@override String get appInfo => 'App Information';
	@override String get version => 'Version';
	@override String get saveError => 'Could not save the setting';
	@override late final _Translations$settings$themeMode$en themeMode = _Translations$settings$themeMode$en._(_root);
	@override late final _Translations$settings$language$en language = _Translations$settings$language$en._(_root);
}

// Path: licenses
class _Translations$licenses$en extends Translations$licenses$ja {
	_Translations$licenses$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Licenses';
	@override String get searchHint => 'Search packages';
	@override String get clearSearch => 'Clear search';
	@override String licenseCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} license',
		other: '${n} licenses',
	);
	@override String get notFound => 'License not found';
}

// Path: error
class _Translations$error$en extends Translations$error$ja {
	_Translations$error$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Could not load data';
	@override String get message => 'Check your connection and try again.';
	@override String get permissionDenied => 'You do not have permission to view this information. Please contact FlutterKaigi staff.';
	@override String get unavailable => 'Check your connection and try again in a moment.';
	@override String get timeout => 'Loading is taking longer than expected. Please try again.';
	@override String get retry => 'Retry';
	@override String get imageSemanticLabel => 'Dashumaru looking troubled';
}

// Path: notFound
class _Translations$notFound$en extends Translations$notFound$ja {
	_Translations$notFound$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Page not found';
	@override String get description => 'The page you are looking for does not exist or may have moved.';
}

// Path: sessionTimetable.view
class _Translations$sessionTimetable$view$en extends Translations$sessionTimetable$view$ja {
	_Translations$sessionTimetable$view$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get openRooms => 'Switch to room timeline';
	@override String get openList => 'Switch to list view';
	@override String get shared => 'Shared';
}

// Path: sessionTimetable.venue
class _Translations$sessionTimetable$venue$en extends Translations$sessionTimetable$venue$ja {
	_Translations$sessionTimetable$venue$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
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

// Path: settings.themeMode
class _Translations$settings$themeMode$en extends Translations$settings$themeMode$ja {
	_Translations$settings$themeMode$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Theme';
	@override String get system => 'System';
	@override String get light => 'Light';
	@override String get dark => 'Dark';
}

// Path: settings.language
class _Translations$settings$language$en extends Translations$settings$language$ja {
	_Translations$settings$language$en._(TranslationsEn root) : this._root = root, super.internal(root);

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
			'links.openError' => 'Could not open the link',
			'navigation.sessions' => 'Sessions',
			'navigation.sponsors' => 'Sponsors',
			'navigation.info' => 'Event',
			'news.title' => 'News',
			'news.empty' => 'There is no news yet',
			'sponsors.title' => 'Sponsors',
			'sponsors.detailTitle' => 'Sponsor Details',
			'sponsors.subtitle' => 'The sponsors supporting FlutterKaigi 2026',
			'sponsors.empty' => 'Sponsors have not been published yet',
			'sponsors.notFound' => 'Sponsor not found',
			'sponsors.logoSemanticLabel' => ({required Object name}) => '${name} logo',
			'sponsors.tierBadge' => ({required Object tier}) => '${tier} Sponsor',
			'sponsors.jobBoards' => 'Job Boards',
			'sponsors.jobBoardCta' => 'Hiring information',
			'sponsors.recruitCta' => 'Careers',
			'sponsors.connect' => 'Connect',
			'trademarks.flutterAffiliation' => 'Flutter and the related logo are trademarks of Google LLC. FlutterKaigi is not affiliated with or otherwise sponsored by Google LLC.',
			'trademarks.flutterNameAndLogo' => 'The Flutter name and the Flutter logo are trademarks of Google LLC.',
			'trademarks.revComm' => 'RevComm is a registered trademark or trademark of RevComm Inc.',
			'sessionTimetable.title' => 'Timetable',
			'sessionTimetable.dayButtonLabel' => ({required Object day, required Object date}) => 'Day ${day} (${date})',
			'sessionTimetable.view.openRooms' => 'Switch to room timeline',
			'sessionTimetable.view.openList' => 'Switch to list view',
			'sessionTimetable.view.shared' => 'Shared',
			'sessionTimetable.empty' => 'The timetable has not been published yet',
			'sessionTimetable.emptyFiltered' => 'There are no items for this day',
			'sessionTimetable.venue.unknown' => 'Venue TBA',
			'sessionTimetable.speaker.none' => 'Speaker TBA',
			'sessionTimetable.type.regular' => 'Regular Talk',
			'sessionTimetable.type.lightningTalk' => 'Lightning Talk',
			'sessionTimetable.type.beginnersLightningTalk' => 'Beginners LT',
			'sessionTimetable.type.handsOn' => 'Hands-on',
			'sessionTimetable.type.event' => 'Event',
			'sessionSearch.title' => 'Search sessions',
			'sessionSearch.hint' => 'Search titles, descriptions, and speakers',
			'sessionSearch.clear' => 'Clear search',
			'sessionSearch.allDates' => 'All days',
			'sessionSearch.allTypes' => 'All types',
			'sessionSearch.allLanguages' => 'All languages',
			'sessionSearch.dateFilter' => 'Filter by day',
			'sessionSearch.typeFilter' => 'Filter by type',
			'sessionSearch.languageFilter' => 'Filter by language',
			'sessionSearch.dateChip' => 'Day',
			'sessionSearch.typeChip' => 'Type',
			'sessionSearch.languageChip' => 'Language',
			'sessionSearch.promptTitle' => 'Find a session',
			'sessionSearch.promptBody' => 'Enter a keyword or select a day, session type, or language',
			'sessionSearch.emptyTitle' => 'No sessions found',
			'sessionSearch.emptyBody' => 'Try changing the keyword or filters',
			'sessionSearch.resultCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} session', other: '${n} sessions', ),
			'sessionDetails.title' => 'Session Details',
			'sessionDetails.description' => 'Description',
			'sessionDetails.schedule' => 'Schedule and Venue',
			'sessionDetails.speakers' => 'Speakers',
			'sessionDetails.links' => 'Links',
			'sessionDetails.sessionize' => 'Sessionize',
			'sessionDetails.share' => 'Share',
			'sessionDetails.notFound' => 'Session not found',
			'sessionBookmark.openBookmarked' => 'Bookmarked sessions',
			'sessionBookmark.add' => 'Add bookmark',
			'sessionBookmark.remove' => 'Remove bookmark',
			'sessionBookmark.updateFailed' => 'Failed to update bookmark',
			'bookmarkedSessions.title' => 'Bookmarked Sessions',
			'bookmarkedSessions.emptyTitle' => 'No bookmarked sessions',
			'bookmarkedSessions.emptyBody' => 'Bookmark sessions to find them here.',
			'bookmarkedSessions.openSessions' => 'Open sessions',
			'eventInfo.title' => 'Event Overview',
			'eventInfo.newsTitle' => 'Latest News',
			'eventInfo.newsSubtitle' => 'See the latest FlutterKaigi 2026 updates',
			'eventInfo.logoSemanticLabel' => 'FlutterKaigi 2026 logo',
			'eventInfo.tagline' => 'Connect, Converse, Ignite.',
			'eventInfo.themeName' => '〜Assemble〜',
			'eventInfo.description' => 'Japan\'s Flutter tech conference in 2026. Two days for sharing Flutter and Dart expertise and connecting with the community.',
			'eventInfo.dateLabel' => 'Date',
			'eventInfo.date' => 'October 29–30, 2026',
			'eventInfo.venueLabel' => 'Venue',
			'eventInfo.venue' => 'Hamamatsucho Convention Hall',
			'eventInfo.viewMap' => 'View Map',
			'eventInfo.other' => 'Other',
			'eventInfo.officialWebsite' => 'Official Website',
			'eventInfo.codeOfConduct' => 'Code of Conduct',
			'eventInfo.privacyPolicy' => 'Privacy Policy',
			'eventInfo.exclusionPolicy' => 'Exclusion of Anti-Social Forces',
			'eventInfo.contact' => 'Contact',
			'eventInfo.sourceCode' => 'View Source Code',
			'eventInfo.ossLicenses' => 'OSS Licenses',
			'settings.title' => 'Settings',
			'settings.appearance' => 'Appearance',
			'settings.appInfo' => 'App Information',
			'settings.version' => 'Version',
			'settings.saveError' => 'Could not save the setting',
			'settings.themeMode.title' => 'Theme',
			'settings.themeMode.system' => 'System',
			'settings.themeMode.light' => 'Light',
			'settings.themeMode.dark' => 'Dark',
			'settings.language.title' => 'Language',
			'settings.language.japanese' => '日本語',
			'settings.language.english' => 'English',
			'licenses.title' => 'Licenses',
			'licenses.searchHint' => 'Search packages',
			'licenses.clearSearch' => 'Clear search',
			'licenses.licenseCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} license', other: '${n} licenses', ),
			'licenses.notFound' => 'License not found',
			'error.title' => 'Could not load data',
			'error.message' => 'Check your connection and try again.',
			'error.permissionDenied' => 'You do not have permission to view this information. Please contact FlutterKaigi staff.',
			'error.unavailable' => 'Check your connection and try again in a moment.',
			'error.timeout' => 'Loading is taking longer than expected. Please try again.',
			'error.retry' => 'Retry',
			'error.imageSemanticLabel' => 'Dashumaru looking troubled',
			'notFound.title' => 'Page not found',
			'notFound.description' => 'The page you are looking for does not exist or may have moved.',
			_ => null,
		};
	}
}
