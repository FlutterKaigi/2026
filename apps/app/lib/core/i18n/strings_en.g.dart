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
	@override late final _Translations$staffMembers$en staffMembers = _Translations$staffMembers$en._(_root);
	@override late final _Translations$trademarks$en trademarks = _Translations$trademarks$en._(_root);
	@override late final _Translations$sessionTimetable$en sessionTimetable = _Translations$sessionTimetable$en._(_root);
	@override late final _Translations$sessionSearch$en sessionSearch = _Translations$sessionSearch$en._(_root);
	@override late final _Translations$sessionDetails$en sessionDetails = _Translations$sessionDetails$en._(_root);
	@override late final _Translations$sessionBookmark$en sessionBookmark = _Translations$sessionBookmark$en._(_root);
	@override late final _Translations$bookmarkedSessions$en bookmarkedSessions = _Translations$bookmarkedSessions$en._(_root);
	@override late final _Translations$venueMap$en venueMap = _Translations$venueMap$en._(_root);
	@override late final _Translations$venueWalk$en venueWalk = _Translations$venueWalk$en._(_root);
	@override late final _Translations$eventInfo$en eventInfo = _Translations$eventInfo$en._(_root);
	@override late final _Translations$contributors$en contributors = _Translations$contributors$en._(_root);
	@override late final _Translations$auth$en auth = _Translations$auth$en._(_root);
	@override late final _Translations$profile$en profile = _Translations$profile$en._(_root);
	@override late final _Translations$snsPost$en snsPost = _Translations$snsPost$en._(_root);
	@override late final _Translations$mission$en mission = _Translations$mission$en._(_root);
	@override late final _Translations$venueEvents$en venueEvents = _Translations$venueEvents$en._(_root);
	@override late final _Translations$eventGuide$en eventGuide = _Translations$eventGuide$en._(_root);
	@override late final _Translations$stampRally$en stampRally = _Translations$stampRally$en._(_root);
	@override late final _Translations$exchange$en exchange = _Translations$exchange$en._(_root);
	@override late final _Translations$supportLt$en supportLt = _Translations$supportLt$en._(_root);
	@override late final _Translations$countryRegion$en countryRegion = _Translations$countryRegion$en._(_root);
	@override late final _Translations$settings$en settings = _Translations$settings$en._(_root);
	@override late final _Translations$licenses$en licenses = _Translations$licenses$en._(_root);
	@override late final _Translations$error$en error = _Translations$error$en._(_root);
	@override late final _Translations$notFound$en notFound = _Translations$notFound$en._(_root);
	@override late final _Translations$common$en common = _Translations$common$en._(_root);
	@override late final _Translations$quiz$en quiz = _Translations$quiz$en._(_root);
	@override late final _Translations$forceUpdate$en forceUpdate = _Translations$forceUpdate$en._(_root);
	@override late final _Translations$pushNotification$en pushNotification = _Translations$pushNotification$en._(_root);
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
	@override String get copied => 'Link copied';
}

// Path: navigation
class _Translations$navigation$en extends Translations$navigation$ja {
	_Translations$navigation$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get sessions => 'Sessions';
	@override String get venueMap => 'Venue Map';
	@override String get sponsors => 'Sponsors';
	@override String get info => 'Event';
	@override String get account => 'Account';
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
	@override String githubCardSemanticLabel({required Object name}) => 'View ${name}\'s GitHub profile';
	@override String xCardSemanticLabel({required Object name}) => 'View ${name}\'s X profile';
	@override String externalCardSemanticLabel({required Object name}) => 'Open ${name}\'s link';
	@override String tierBadge({required Object tier}) => '${tier} Sponsor';
	@override String get jobBoards => 'Job Boards';
	@override String get jobBoardCta => 'Hiring information';
	@override String get recruitCta => 'Careers';
	@override String get connect => 'Connect';
}

// Path: staffMembers
class _Translations$staffMembers$en extends Translations$staffMembers$ja {
	_Translations$staffMembers$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Staff';
	@override String get empty => 'Staff profiles have not been published yet';
	@override String get error => 'Failed to load staff profiles';
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
	@override String get feedback => 'Send session feedback';
	@override String get feedbackDescription => 'Let us know what you thought of this session';
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

// Path: venueMap
class _Translations$venueMap$en extends Translations$venueMap$ja {
	_Translations$venueMap$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Venue Map';
	@override String get floor => 'Hamamatsucho Convention Hall · 5F';
	@override String get loadError => 'Could not load the venue map';
	@override String get loadErrorDescription => 'Please try again.';
	@override String get search => 'Find a place';
	@override String get searchHint => 'Hall, sponsor, booth number, facility';
	@override String get clearSearch => 'Clear search';
	@override String get placesCount => 'places';
	@override String get showOnMap => 'Show on map';
	@override String get all => 'All';
	@override String get halls => 'Halls';
	@override String get booths => 'Sponsors';
	@override String get facilities => 'Facilities';
	@override String get noResults => 'No matching places';
	@override String get clearSelection => 'Clear selection';
	@override String get zoomIn => 'Zoom in';
	@override String get zoomOut => 'Zoom out';
	@override String get fit => 'Show entire floor';
	@override String get rotate => 'Rotate map';
	@override String get twoD => '2D';
	@override String get threeD => '3D';
	@override String get viewMode => 'Map view';
	@override String get useTwoD => 'Show in 2D';
	@override String get saveFailed => 'Could not save the view preference';
}

// Path: venueWalk
class _Translations$venueWalk$en extends Translations$venueWalk$ja {
	_Translations$venueWalk$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get sceneLabel => 'Explore the venue with Dashumaru. Walk using the stick, a tap on the floor, or the arrow keys.';
	@override String get currentLocation => 'You are at';
	@override String get entrance => 'Entrance';
	@override String get entranceSign => 'Entrance';
	@override String get selectedPoint => 'Selected spot';
	@override String headingTo({required Object place}) => 'Walking to ${place}';
	@override String arrivedAt({required Object place}) => 'Arrived at ${place}';
	@override String get unreachable => 'Cannot walk to that spot';
	@override String get photoMode => 'Photo mode';
	@override String get walkToPhotoSpot => 'Walk to the photo spot';
	@override String get followTooltip => 'Follow Dashumaru';
	@override String get overviewTooltip => 'View the entire floor';
	@override String get follow => 'Follow';
	@override String get overview => 'Overview';
	@override String get help => 'How to play';
	@override String get stickHint => 'Use the stick to walk';
	@override String get stickLabel => 'Stick to move Dashumaru';
	@override String get stopTooltip => 'Stop walking';
	@override String get stop => 'Stop here';
	@override String get reset => 'Return to the entrance';
	@override String get wave => 'Wave';
	@override String get backToWalk => 'Back to walking';
	@override String get run => 'Run';
	@override String get runningSpeed => 'Running';
	@override String get walkingSpeed => 'Walking';
	@override String get runHint => 'Hold to run. Release to walk. On a keyboard, hold Shift.';
	@override String get close => 'Close';
	@override late final _Translations$venueWalk$instructions$en instructions = _Translations$venueWalk$instructions$en._(_root);
	@override late final _Translations$venueWalk$photo$en photo = _Translations$venueWalk$photo$en._(_root);
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
	@override String get credits => 'Credits';
	@override String get contributors => 'Contributors';
	@override String get other => 'Other';
	@override String get officialWebsite => 'Official Website';
	@override String get codeOfConduct => 'Code of Conduct';
	@override String get privacyPolicy => 'Privacy Policy';
	@override String get exclusionPolicy => 'Exclusion of Anti-Social Forces';
	@override String get contact => 'Contact';
	@override String get sourceCode => 'View Source Code';
	@override String get staffMembers => 'Staff';
	@override String get ossLicenses => 'OSS Licenses';
	@override late final _Translations$eventInfo$survey$en survey = _Translations$eventInfo$survey$en._(_root);
}

// Path: contributors
class _Translations$contributors$en extends Translations$contributors$ja {
	_Translations$contributors$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Contributors';
	@override String get openRepository => 'Open the FlutterKaigi/2026 repository';
	@override String get empty => 'No contributors found';
	@override String contributionsCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} contribution',
		other: '${n} contributions',
	);
}

// Path: auth
class _Translations$auth$en extends Translations$auth$ja {
	_Translations$auth$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$auth$signIn$en signIn = _Translations$auth$signIn$en._(_root);
	@override late final _Translations$auth$email$en email = _Translations$auth$email$en._(_root);
	@override late final _Translations$auth$account$en account = _Translations$auth$account$en._(_root);
	@override late final _Translations$auth$error$en error = _Translations$auth$error$en._(_root);
}

// Path: profile
class _Translations$profile$en extends Translations$profile$ja {
	_Translations$profile$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Profile';
	@override String get signInRequired => 'Sign in to create your profile';
	@override String get editTitle => 'Edit Profile';
	@override String get createTitle => 'Create Profile';
	@override String get promptTitle => 'Set up your profile';
	@override String get promptBody => 'Add your country or region and social links to exchange profiles with other attendees at the venue.';
	@override String get create => 'Create profile';
	@override String get edit => 'Edit profile';
	@override String get save => 'Save';
	@override String get saved => 'Profile saved';
	@override String get saveFailed => 'Could not save the profile';
	@override String get visibilityNote => 'Your profile is visible to other signed-in attendees';
	@override String get avatarSemanticLabel => 'Profile picture';
	@override String get displayNameLabel => 'Display name';
	@override String get displayNameRequired => 'Enter a display name';
	@override String get countryLabel => 'Country / Region';
	@override String get countryPlaceholder => 'Select';
	@override String get countryRequired => 'Select your country or region';
	@override String get countrySearchHint => 'Search countries and regions';
	@override String countryNoResults({required Object query}) => 'No countries or regions match "${query}"';
	@override String get countryNoResultsHint => 'You can also search by Japanese name or ISO code';
	@override String get snsLinksLabel => 'Social links';
	@override String get snsLinksEmpty => 'Add links to X, GitHub and more';
	@override String get addSnsLink => 'Add a link';
	@override String get removeSnsLink => 'Remove this link';
	@override String get snsPlatformLabel => 'Service';
	@override String get snsUrlLabel => 'URL';
	@override String get snsIdOrUrlLabel => 'ID or URL';
	@override String get snsIdOrUrlRequired => 'Enter an ID or URL';
	@override String get snsIdOrUrlInvalid => 'Enter a valid ID or a URL starting with https://';
	@override String get snsUrlRequired => 'Enter a URL';
	@override String get snsUrlInvalid => 'Enter a URL starting with https://';
	@override String snsLinksMax({required Object n}) => 'You can add up to ${n} links';
	@override String get snsPlatformOther => 'Other';
	@override String get bioLabel => 'Bio';
	@override String get bioHint => 'What you work on, what you\'d like to talk about today, etc.';
	@override String get discardTitle => 'Discard changes?';
	@override String get discardBody => 'Unsaved changes will be lost.';
	@override String get discardAction => 'Discard';
	@override String get keepEditing => 'Keep editing';
}

// Path: snsPost
class _Translations$snsPost$en extends Translations$snsPost$ja {
	_Translations$snsPost$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Register SNS post';
	@override String get signInRequired => 'Sign in to register your SNS post';
	@override String get heading => 'Register your photo post';
	@override String get description => 'Post a photo with an eligible attendee on SNS,\nthen register the URL of that post.';
	@override String get companionLabel => 'Who is in your photo?';
	@override String get companionHint => 'Choose one category for the person in the photo';
	@override String get companionRequired => 'Choose one companion category';
	@override late final _Translations$snsPost$companions$en companions = _Translations$snsPost$companions$en._(_root);
	@override String get urlLabel => 'SNS post URL';
	@override String get urlHint => 'Link to the photo post, not your profile page';
	@override String get invalidUrl => 'Enter a valid post URL (https://…)';
	@override String get register => 'Register post';
	@override String get update => 'Update registration';
	@override String get saving => 'Saving…';
	@override String get cancel => 'Cancel';
	@override String get saveFailed => 'Could not save. Check your connection and try again.';
	@override String get invalidRegistration => 'The saved registration could not be read. Register the post URL and companion category again.';
	@override String get registeredTitle => 'SNS post registered';
	@override String get registeredBody => 'Your SNS post mission is complete.';
	@override String updatedAt({required Object date}) => 'Updated: ${date}';
	@override String get openPost => 'Open post';
	@override String get openFailed => 'Could not open the post';
	@override String get viewMissions => 'View mission progress';
	@override String get edit => 'Edit URL or category';
}

// Path: mission
class _Translations$mission$en extends Translations$mission$ja {
	_Translations$mission$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Missions';
	@override String get signInRequired => 'Sign in to view your mission progress';
	@override String get complete => 'Complete';
	@override String get incomplete => 'Incomplete';
	@override String get loading => 'Checking';
	@override String get loadFailed => 'Unavailable';
	@override String get allComplete => 'All missions complete!';
	@override String get inProgress => 'Mission progress';
	@override String get checkFailed => 'Some results are unavailable';
	@override String progress({required Object n, required Object total}) => '${n} of ${total} missions complete';
	@override String get ltTitle => 'Join Support LT';
	@override String get ltDescription => 'Supporters and speakers register with the code at the venue';
	@override String get exchangeTitle => 'Exchange profiles';
	@override String exchangeDescription({required Object required}) => 'Meet at least ${required} people, including someone from a different country or region';
	@override String exchangeCount({required Object n, required Object required}) => '${n} / ${required} people met';
	@override String get differentCountry => 'Met someone from a different country or region';
	@override String get profileRequired => 'Add your country or region to your profile';
	@override String get snsTitle => 'Share a photo on SNS';
	@override String get snsDescription => 'Post a photo with an eligible attendee and register its URL and category';
}

// Path: venueEvents
class _Translations$venueEvents$en extends Translations$venueEvents$ja {
	_Translations$venueEvents$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Join Venue Events';
	@override String get entrySubtitle => 'Stamp rally, profile exchange and more';
	@override String get day1 => 'Thu, Oct 29 · Day 1';
	@override String get day2 => 'Fri, Oct 30 · Day 2';
	@override String get signInTitle => 'Sign in to take part';
	@override String get signInDescription => 'Your stamps and quiz records are saved to your account.';
	@override String get previewHeading => 'Sign in to join these activities';
	@override late final _Translations$venueEvents$features$en features = _Translations$venueEvents$features$en._(_root);
	@override late final _Translations$venueEvents$status$en status = _Translations$venueEvents$status$en._(_root);
	@override late final _Translations$venueEvents$quizCheckIn$en quizCheckIn = _Translations$venueEvents$quizCheckIn$en._(_root);
}

// Path: eventGuide
class _Translations$eventGuide$en extends Translations$eventGuide$ja {
	_Translations$eventGuide$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Event day guide';
	@override String get open => 'View the event day guide';
	@override String get skip => 'Skip';
	@override String get next => 'Next';
	@override String get close => 'Close';
	@override String pageIndicator({required Object page, required Object total}) => 'Page ${page} of ${total}';
	@override late final _Translations$eventGuide$welcome$en welcome = _Translations$eventGuide$welcome$en._(_root);
	@override late final _Translations$eventGuide$sessions$en sessions = _Translations$eventGuide$sessions$en._(_root);
	@override late final _Translations$eventGuide$venueEvents$en venueEvents = _Translations$eventGuide$venueEvents$en._(_root);
	@override late final _Translations$eventGuide$quiz$en quiz = _Translations$eventGuide$quiz$en._(_root);
}

// Path: stampRally
class _Translations$stampRally$en extends Translations$stampRally$ja {
	_Translations$stampRally$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Stamp Rally';
	@override String get signInRequired => 'Sign in to collect stamps';
	@override String get description => 'Scan the QR codes at sponsor booths to collect stamps';
	@override String get scanButton => 'Scan QR code';
	@override String get sponsorsButton => 'View stamps by sponsor';
	@override String get sponsorsTitle => 'Stamps by sponsor';
	@override String get sponsorsDescription => 'See which sponsors you have collected stamps from';
	@override String get sponsorsSignInRequired => 'Sign in to see your stamp collection by sponsor';
	@override String get sponsorsEmpty => 'No participating sponsors yet';
	@override String sponsorUnavailable({required Object id}) => 'Sponsor (${id})';
	@override String sponsorAcquiredAt({required Object date}) => 'Collected at ${date}';
	@override String get lumaTicketButton => 'Open ticket in Luma';
	@override String get lumaTicketDescription => 'Show your Luma ticket QR code to the staff when collecting prizes';
	@override String get closed => 'Stamps are not available right now. Prizes and the crane game are still available';
	@override String stampCount({required Object n, required Object total}) => '${n} / ${total}';
	@override String stampCountSemantic({required Object n, required Object total}) => '${n} of ${total} stamps collected';
	@override String nextCheckpoint({required Object n, required Object number}) => '${n} more for prize #${number}';
	@override String get allCheckpoints => 'You have reached every prize';
	@override String checkpointLabel({required Object number, required Object required}) => '#${number} (${required} stamps)';
	@override String get checkpointLocked => 'Not yet';
	@override String get checkpointAchieved => 'Ready to redeem';
	@override String checkpointRedeemed({required Object date}) => 'Redeemed ${date}';
	@override String get thanksCardTitle => 'Crane game';
	@override String get thanksCardDescription => 'Collect thanks cards at the venue to play the crane game once';
	@override String get thanksCardNotRedeemed => 'Not played';
	@override String thanksCardRedeemed({required Object date}) => 'Played ${date}';
	@override String get roadmapTitle => 'Stamps';
	@override String stampSlotSemantic({required Object n, required Object status}) => 'Stamp ${n}, ${status}';
	@override String get acquired => 'Collected';
	@override String get notAcquired => 'Not collected';
	@override String get scanTitle => 'Scan QR code';
	@override String get scanHint => 'Fit the QR code at a sponsor booth or the prize counter inside the frame';
	@override String get scanInvalid => 'This is not a stamp rally QR code';
	@override String get scanCameraError => 'The camera is unavailable. Allow camera access in Settings';
	@override String get resultTitle => 'Stamp Rally';
	@override String get processing => 'Checking…';
	@override String get stampAcquiredTitle => 'Stamp collected!';
	@override String get stampAlreadyTitle => 'You already have this stamp';
	@override String checkpointReached({required Object number}) => 'You reached prize #${number}!';
	@override String get rewardTitle => 'Prize redemption';
	@override String rewardRedeemedTitle({required Object numbers}) => 'You can receive prize ${numbers}';
	@override String get rewardNoneTitle => 'No new prizes to redeem';
	@override String rewardNoneBody({required Object n}) => 'You have ${n} stamps';
	@override String get rewardStaffNote => 'Show this screen to the staff';
	@override String rewardRedeemedAt({required Object number, required Object date}) => '#${number} redeemed ${date}';
	@override String get thanksCardResultTitle => 'You can play the crane game';
	@override String get thanksCardAlreadyTitle => 'You have already played the crane game';
	@override String thanksCardResultAt({required Object date}) => 'Checked in ${date}';
	@override String get invalidTitle => 'Invalid QR code';
	@override String get invalidBody => 'Check that this is a stamp rally QR code';
	@override String get closedTitle => 'Stamps are not available right now';
	@override String get networkError => 'Could not connect. Try again somewhere with a better signal';
	@override String get failed => 'Something went wrong';
	@override String get sessionExpired => 'Please sign in again';
	@override String get permissionDenied => 'This account cannot take part';
	@override String get retry => 'Try again';
	@override String get viewCard => 'View stamp rally';
}

// Path: exchange
class _Translations$exchange$en extends Translations$exchange$ja {
	_Translations$exchange$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Profile Exchange';
	@override String get qrDescription => 'Show this QR code to another attendee and have them scan it to exchange profiles';
	@override String get qrSemanticLabel => 'Profile exchange QR code';
	@override String qrExpiresAt({required Object date}) => 'Valid until ${date}';
	@override String get scanButton => 'Scan a QR code';
	@override String get listButton => 'View exchanged profiles';
	@override String get signInRequired => 'Sign in to show your QR code';
	@override String get profileRequired => 'Create a profile to show your QR code';
	@override String get profileRequiredAction => 'Create profile';
	@override String get scanTitle => 'Scan a QR code';
	@override String get scanHint => 'Line up the other attendee\'s QR code within the frame';
	@override String get scanCameraError => 'Camera unavailable. Please allow camera access in Settings';
	@override String get scanInvalid => 'Could not read this code. Make sure it\'s a profile exchange QR code';
	@override String get scanSelf => 'You can\'t scan your own QR code';
	@override String get scanSucceeded => 'Profile exchanged';
	@override String get scanAlreadyExists => 'Already exchanged';
	@override String get scanFailed => 'Could not exchange profiles';
	@override String get listTitle => 'Exchanged Profiles';
	@override String get listEmpty => 'No exchanges yet';
	@override String get listEmptyBody => 'Scan a QR code to exchange profiles with other attendees';
	@override String get profileUnavailable => 'This profile is no longer available';
	@override String get deleteTooltip => 'Delete';
	@override String get deleteConfirmTitle => 'Delete this exchange?';
	@override String get deleteConfirmBody => 'This only removes it from your own list. The other attendee\'s list is unaffected.';
	@override String get deleteConfirmAction => 'Delete';
	@override String get deleteCancel => 'Cancel';
	@override String get deleteFailed => 'Could not delete the exchange';
	@override String get noteAddTooltip => 'Add a note';
	@override String get noteEditTooltip => 'Edit note';
	@override String get noteEditTitle => 'Note';
	@override String get noteEditHint => 'Visible only to you';
	@override String get noteLabel => 'Note';
	@override String get noteSave => 'Save';
	@override String get noteCancel => 'Cancel';
	@override String get noteSaveFailed => 'Could not save the note';
	@override String get codeSectionTitle => 'Exchange with a code';
	@override String get codeSectionDescription => 'If the camera isn\'t available, share and enter a 6-digit code instead. The same code works for everyone until it expires';
	@override String get myCodeSemanticLabel => 'Profile exchange 6-digit code';
	@override String myCodeExpiresAt({required Object date}) => 'Valid until ${date}';
	@override String get myCodeExpired => 'This code has expired';
	@override String get myCodeRefresh => 'Get a new code';
	@override String get myCodeCopy => 'Copy code';
	@override String get myCodeCopied => 'Code copied';
	@override String get enterCodeLabel => 'Enter the other attendee\'s code';
	@override String get enterCodeHint => '123456';
	@override String get enterCodeButton => 'Exchange';
	@override String get enterCodeInvalidFormat => 'Enter a 6-digit code';
	@override String get redeemInvalid => 'This code wasn\'t found, or it has expired';
	@override String get redeemSelf => 'You can\'t enter your own code';
	@override String get redeemRateLimited => 'Too many attempts. Please try again in a few minutes';
	@override String get shareLinkSignInRequired => 'Sign in to exchange profiles with them';
	@override String get shareLinkProfileRequired => 'Create a profile to exchange profiles with them';
	@override String get shareLinkInvalidTitle => 'This link isn\'t valid';
	@override String get shareLinkInvalidBody => 'Make sure it\'s a profile exchange link';
	@override String get shareLinkExpiredTitle => 'This link has expired';
	@override String get shareLinkExpiredBody => 'Ask the other attendee to share their QR code or link again';
	@override String get shareLinkSelfTitle => 'This is your own share link';
	@override String get shareLinkSelfBody => 'Other attendees who open this link can exchange profiles with you';
	@override String get shareLinkGoHome => 'Back to home';
	@override String get shareLinkViewList => 'View exchanged profiles';
}

// Path: supportLt
class _Translations$supportLt$en extends Translations$supportLt$ja {
	_Translations$supportLt$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Support LT Registration';
	@override String get description => 'Scan the QR code shown at the venue to register your participation in Support LT';
	@override String get scanButton => 'Scan the QR code';
	@override String get scanTitle => 'Scan the QR code';
	@override String get scanHint => 'Line up the QR code shown at the venue within the frame';
	@override String get scanCameraError => 'Camera unavailable. Allow camera access in Settings, or enter the 6-digit code on the previous screen';
	@override String get scanInvalid => 'Could not read this code. Make sure it\'s the Support LT registration QR code';
	@override String get linkInvalid => 'This link isn\'t valid. Scan the QR code at the venue again';
	@override String get codeSectionTitle => 'If you can\'t scan the QR code';
	@override String get codeSectionDescription => 'Enter the 6-digit code provided by the organizers';
	@override String get codeLabel => 'Registration code';
	@override String get register => 'Register participation';
	@override String get submitting => 'Registering…';
	@override String get registeredTitle => 'Registration complete';
	@override String get registeredBody => 'Enjoy Support LT';
	@override String get backToAccount => 'Back to account';
	@override String get signInRequired => 'Sign in to register your participation in Support LT';
	@override String get invalidFormat => 'Enter a 6-digit code';
	@override String get invalidCode => 'This code is incorrect. Scan the QR code at the venue again or ask the organizers';
	@override String get rateLimited => 'Too many attempts. Please try again in a few minutes';
	@override String get networkError => 'A network error occurred. Check your connection and try again';
	@override String get sessionExpired => 'Your sign-in session has expired. Please sign in again';
	@override String get permissionDenied => 'Registration is not permitted. Please ask the organizers';
	@override String get registrationFailed => 'Could not register your participation. Please try again';
}

// Path: countryRegion
class _Translations$countryRegion$en extends Translations$countryRegion$ja {
	_Translations$countryRegion$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get asia => 'Asia';
	@override String get oceania => 'Oceania';
	@override String get americas => 'Americas';
	@override String get europe => 'Europe';
	@override String get africa => 'Africa';
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

// Path: common
class _Translations$common$en extends Translations$common$ja {
	_Translations$common$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get retry => 'Retry';
}

// Path: quiz
class _Translations$quiz$en extends Translations$quiz$ja {
	_Translations$quiz$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Quiz';
	@override late final _Translations$quiz$list$en list = _Translations$quiz$list$en._(_root);
	@override late final _Translations$quiz$signInRequired$en signInRequired = _Translations$quiz$signInRequired$en._(_root);
	@override late final _Translations$quiz$errors$en errors = _Translations$quiz$errors$en._(_root);
	@override late final _Translations$quiz$preparing$en preparing = _Translations$quiz$preparing$en._(_root);
	@override late final _Translations$quiz$registration$en registration = _Translations$quiz$registration$en._(_root);
	@override late final _Translations$quiz$waiting$en waiting = _Translations$quiz$waiting$en._(_root);
	@override late final _Translations$quiz$progress$en progress = _Translations$quiz$progress$en._(_root);
	@override late final _Translations$quiz$checkIn$en checkIn = _Translations$quiz$checkIn$en._(_root);
	@override late final _Translations$quiz$selection$en selection = _Translations$quiz$selection$en._(_root);
	@override late final _Translations$quiz$team$en team = _Translations$quiz$team$en._(_root);
	@override late final _Translations$quiz$rules$en rules = _Translations$quiz$rules$en._(_root);
	@override late final _Translations$quiz$entryClosed$en entryClosed = _Translations$quiz$entryClosed$en._(_root);
	@override late final _Translations$quiz$question$en question = _Translations$quiz$question$en._(_root);
	@override late final _Translations$quiz$suspense$en suspense = _Translations$quiz$suspense$en._(_root);
	@override late final _Translations$quiz$revealed$en revealed = _Translations$quiz$revealed$en._(_root);
	@override late final _Translations$quiz$result$en result = _Translations$quiz$result$en._(_root);
}

// Path: forceUpdate
class _Translations$forceUpdate$en extends Translations$forceUpdate$ja {
	_Translations$forceUpdate$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Update Required';
	@override String get message => 'A new version of the app is available. Please update to the latest version.';
	@override String get updateButton => 'Update';
}

// Path: pushNotification
class _Translations$pushNotification$en extends Translations$pushNotification$ja {
	_Translations$pushNotification$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get open => 'Open';
}

// Path: sessionTimetable.view
class _Translations$sessionTimetable$view$en extends Translations$sessionTimetable$view$ja {
	_Translations$sessionTimetable$view$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get list => 'List';
	@override String get rooms => 'By room';
	@override String get saveFailed => 'Could not save the view preference';
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
	@override String get event => 'Event';
}

// Path: venueWalk.instructions
class _Translations$venueWalk$instructions$en extends Translations$venueWalk$instructions$ja {
	_Translations$venueWalk$instructions$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Exploring the venue';
	@override String get movement => 'Use the stick at the bottom left to walk. Hold the run icon at the bottom right to run, and release it to walk again.';
	@override String get camera => 'Drag the background to look around and pinch to zoom. Tap the floor to walk to that spot automatically.';
	@override String get places => 'Use “Find a place” to choose a destination and explore the four halls. Tap the map icon for a view of the entire floor.';
	@override String get photos => 'Tap the camera to take a photo. The picture icon beside it takes you to the creative board. Choose a pose and frame for your photo.';
	@override String get keyboard => 'On a computer, use W A S D or the arrow keys to move. Hold Shift to run and press Esc to stop.';
	@override String get scope => 'Explore the venue on the fifth floor. This does not show your real location, and you cannot use the escalators to change floors.';
	@override String get credits => '3D model: yakitama5 / flutter_deck_slides\nDashumaru: FlutterKaigi';
}

// Path: venueWalk.photo
class _Translations$venueWalk$photo$en extends Translations$venueWalk$photo$ja {
	_Translations$venueWalk$photo$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'A photo with Dashumaru';
	@override String get resultTitle => 'Your photo';
	@override String get imageLabel => 'A souvenir photo of Dashumaru';
	@override String get downloadStarted => 'Your photo download has started';
	@override String get saveFailed => 'Could not save the photo. Please try again.';
	@override String get savePng => 'Save PNG';
	@override String get captureFailed => 'Could not take the photo. Please try again.';
	@override String get caption => 'Exploring the venue with Dashumaru.';
	@override String captionAt({required Object place}) => 'With Dashumaru at ${place}.';
	@override String get shutter => 'Take a photo';
	@override String get capturing => 'Taking photo';
	@override String get hideUi => 'Hide controls. Tap the screen to bring them back';
	@override String get faceCamera => 'Face the camera';
	@override String get removeFrame => 'Remove frame';
	@override String get addFrame => 'Add frame';
	@override late final _Translations$venueWalk$photo$poses$en poses = _Translations$venueWalk$photo$poses$en._(_root);
}

// Path: eventInfo.survey
class _Translations$eventInfo$survey$en extends Translations$eventInfo$survey$ja {
	_Translations$eventInfo$survey$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Survey Request';
	@override String get description => 'We would like to hear your opinions to make future FlutterKaigi events better.';
	@override String get button => 'Answer the General Survey';
}

// Path: auth.signIn
class _Translations$auth$signIn$en extends Translations$auth$signIn$ja {
	_Translations$auth$signIn$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get required => 'Sign in required';
	@override String get accountTitle => 'Sign in';
	@override String get accountDescription => 'Your profile and venue event records\nare saved to your account';
	@override String get withGoogle => 'Sign in with Google';
	@override String get withApple => 'Sign in with Apple';
	@override String get withEmail => 'Sign in with email';
}

// Path: auth.email
class _Translations$auth$email$en extends Translations$auth$email$ja {
	_Translations$auth$email$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Sign in with email';
	@override String get emailLabel => 'Email address';
	@override String get passwordLabel => 'Password';
	@override String get emailRequired => 'Enter your email address';
	@override String get passwordRequired => 'Enter your password';
	@override String get showPassword => 'Show password';
	@override String get hidePassword => 'Hide password';
	@override String get signInButton => 'Sign in';
	@override String get createAccountButton => 'Create account';
	@override String get switchToCreateAccount => 'Create a new account';
	@override String get switchToSignIn => 'Sign in with an existing account';
	@override String get forgotPassword => 'Reset your password';
	@override String get resetEmailSent => 'Password reset email sent';
}

// Path: auth.account
class _Translations$auth$account$en extends Translations$auth$account$ja {
	_Translations$auth$account$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Account';
	@override String get signedIn => 'Signed in';
	@override String get signOut => 'Sign out';
	@override String get noEmail => 'No email address';
	@override String get delete => 'Delete account';
	@override String get deleteConfirmTitle => 'Delete your account?';
	@override String get deleteConfirmBody => 'Your account will be permanently deleted and cannot be restored. Re-authentication is required before deletion.';
	@override String get deleteConfirmAction => 'Delete';
	@override String get deletePasswordTitle => 'Confirm your password';
	@override String get deletePasswordBody => 'Enter your current password to delete your account.';
	@override String get deleted => 'Your account has been deleted';
	@override String get cancel => 'Cancel';
}

// Path: auth.error
class _Translations$auth$error$en extends Translations$auth$error$ja {
	_Translations$auth$error$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get invalidEmail => 'The email address is badly formatted';
	@override String get userDisabled => 'This account has been disabled';
	@override String get invalidCredential => 'Incorrect email address or password';
	@override String get emailAlreadyInUse => 'This email address is already in use';
	@override String get weakPassword => 'The password is too weak. Choose a stronger password';
	@override String get tooManyRequests => 'Too many attempts. Please try again later';
	@override String get network => 'A network error occurred. Check your connection and try again';
	@override String get requiresRecentLogin => 'Recent authentication is required. Please try again';
	@override String get userMismatch => 'The re-authenticated account does not match the signed-in account';
	@override String get appleTokenRevocationFailed => 'Could not delete the account because revoking the Apple token failed. Please try again';
	@override String get unknown => 'Authentication failed. Please try again';
}

// Path: snsPost.companions
class _Translations$snsPost$companions$en extends Translations$snsPost$companions$ja {
	_Translations$snsPost$companions$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get staff => 'Staff';
	@override String get speaker => 'Speaker';
	@override String get sponsor => 'Sponsor';
	@override String get firstTime => 'First-time attendee';
	@override String get differentCountry => 'Different country or region';
}

// Path: venueEvents.features
class _Translations$venueEvents$features$en extends Translations$venueEvents$features$ja {
	_Translations$venueEvents$features$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$venueEvents$features$quiz$en quiz = _Translations$venueEvents$features$quiz$en._(_root);
	@override late final _Translations$venueEvents$features$stampRally$en stampRally = _Translations$venueEvents$features$stampRally$en._(_root);
	@override late final _Translations$venueEvents$features$profileExchange$en profileExchange = _Translations$venueEvents$features$profileExchange$en._(_root);
	@override late final _Translations$venueEvents$features$supportLt$en supportLt = _Translations$venueEvents$features$supportLt$en._(_root);
	@override late final _Translations$venueEvents$features$snsPost$en snsPost = _Translations$venueEvents$features$snsPost$en._(_root);
	@override late final _Translations$venueEvents$features$mission$en mission = _Translations$venueEvents$features$mission$en._(_root);
}

// Path: venueEvents.status
class _Translations$venueEvents$status$en extends Translations$venueEvents$status$ja {
	_Translations$venueEvents$status$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get registered => 'Registered';
	@override String get checkedIn => 'Checked in';
	@override String team({required Object team}) => 'Team ${team}';
	@override String stampCount({required Object n, required Object total}) => '${n} / ${total}';
	@override String exchangeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} person',
		other: '${n} people',
	);
}

// Path: venueEvents.quizCheckIn
class _Translations$venueEvents$quizCheckIn$en extends Translations$venueEvents$quizCheckIn$ja {
	_Translations$venueEvents$quizCheckIn$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Quiz check-in is open';
	@override String get body => 'Scan the QR code on the venue screen';
}

// Path: eventGuide.welcome
class _Translations$eventGuide$welcome$en extends Translations$eventGuide$welcome$ja {
	_Translations$eventGuide$welcome$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Welcome to FlutterKaigi 2026';
	@override String get body => 'Here are three features you\'ll use at the event';
}

// Path: eventGuide.sessions
class _Translations$eventGuide$sessions$en extends Translations$eventGuide$sessions$ja {
	_Translations$eventGuide$sessions$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bookmark sessions';
	@override String get body => 'After a session ends, you can send\nfeedback from its details screen';
	@override String get sampleTime => '11:00 – 11:40';
	@override String get sampleRoom => 'Hall A';
	@override String get afterSession => 'After the session';
}

// Path: eventGuide.venueEvents
class _Translations$eventGuide$venueEvents$en extends Translations$eventGuide$venueEvents$ja {
	_Translations$eventGuide$venueEvents$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Connect with attendees and sponsors';
	@override String get body => 'Start the stamp rally and profile exchange\nfrom “Join Venue Events”';
	@override String get eventTab => 'Event tab';
}

// Path: eventGuide.quiz
class _Translations$eventGuide$quiz$en extends Translations$eventGuide$quiz$ja {
	_Translations$eventGuide$quiz$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Quiz on Day 2';
	@override String get body => 'After registering, check in with\nthe QR code on the screen';
	@override String get checkInOpens => 'Check-in opens';
	@override String get firstRound => 'First round';
	@override String get secondRound => 'Second round';
	@override String get firstRoundTime => '15:30';
	@override String get secondRoundTime => '16:30';
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

// Path: quiz.list
class _Translations$quiz$list$en extends Translations$quiz$list$ja {
	_Translations$quiz$list$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get empty => 'No quizzes yet';
	@override String get error => 'Failed to load quizzes';
	@override late final _Translations$quiz$list$status$en status = _Translations$quiz$list$status$en._(_root);
}

// Path: quiz.signInRequired
class _Translations$quiz$signInRequired$en extends Translations$quiz$signInRequired$ja {
	_Translations$quiz$signInRequired$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get inPage => 'Sign in to take part in the quiz';
}

// Path: quiz.errors
class _Translations$quiz$errors$en extends Translations$quiz$errors$ja {
	_Translations$quiz$errors$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get signInFailed => 'Failed to sign in';
	@override String get eventLoadFailed => 'Failed to load the event';
}

// Path: quiz.preparing
class _Translations$quiz$preparing$en extends Translations$quiz$preparing$ja {
	_Translations$quiz$preparing$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'The quiz is being prepared';
	@override String get description => 'Once it is announced, you can join from this screen.';
}

// Path: quiz.registration
class _Translations$quiz$registration$en extends Translations$quiz$registration$ja {
	_Translations$quiz$registration$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'You can join only one round.';
	@override String get participantCount => 'Participants:';
	@override String get participantUnit => '';
	@override String capacity({required Object max}) => '/ ${max}';
	@override String get join => 'Join';
	@override String full({required Object max}) => 'Full capacity (${max} participants) reached';
	@override String get failed => 'Could not register. Please try again later.';
	@override String get alreadyParticipated => 'You have already registered for another round and cannot join this one.';
	@override String get closed => 'Registration for this round has closed.';
	@override String get unavailable => 'Registration could not be confirmed. Check your connection and try again.';
	@override String get accountUnavailable => 'This account cannot join. Please contact event staff.';
	@override late final _Translations$quiz$registration$flow$en flow = _Translations$quiz$registration$flow$en._(_root);
}

// Path: quiz.waiting
class _Translations$quiz$waiting$en extends Translations$quiz$waiting$ja {
	_Translations$quiz$waiting$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Registration confirmed';
	@override String get description => 'When check-in opens, scan the QR code on the venue screen.';
}

// Path: quiz.progress
class _Translations$quiz$progress$en extends Translations$quiz$progress$ja {
	_Translations$quiz$progress$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get join => 'Join';
	@override String get checkIn => 'Check in';
	@override String get selectTeam => 'Choose team';
	@override String semantic({required Object current, required Object total}) => 'Step ${current} of ${total}';
}

// Path: quiz.checkIn
class _Translations$quiz$checkIn$en extends Translations$quiz$checkIn$ja {
	_Translations$quiz$checkIn$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Check-in';
	@override String get instructions => 'Scan the QR code shown on the venue screen.';
	@override String get scanButton => 'Scan the QR code';
	@override String get scanTitle => 'Scan the QR code';
	@override String get scanHint => 'Line up the QR code shown on the venue screen within the frame';
	@override String get scanCameraError => 'Camera unavailable. Allow camera access in Settings, or enter the 6-digit check-in code on the previous screen';
	@override String get scanInvalid => 'Could not read this code. Make sure it\'s the quiz check-in QR code';
	@override String get scanOtherEvent => 'This QR code is for another round. Scan the QR code for the round you registered for';
	@override String get codeSectionTitle => 'If you can\'t scan the QR code';
	@override String get codeLabel => 'Check-in code';
	@override String get submit => 'Check in';
	@override String get submitting => 'Checking…';
	@override String get invalidFormat => 'Enter a 6-digit code';
	@override String get linkInvalid => 'This link isn\'t valid. Scan the QR code at the venue again';
	@override String get wrongCode => 'That code is incorrect. Check the 6-digit code on the screen and enter it again.';
	@override String get rateLimited => 'Too many attempts. Wait about a minute and try again';
	@override String get closed => 'Check-in has closed. Please contact event staff.';
	@override String get notRegistered => 'Your registration was canceled. To take part, please ask a staff member.';
	@override String get unavailable => 'Could not confirm your check-in. Check your connection and try again.';
	@override String get failed => 'Couldn\'t check you in. Update the app to the latest version, sign in again, and try again.';
}

// Path: quiz.selection
class _Translations$quiz$selection$en extends Translations$quiz$selection$ja {
	_Translations$quiz$selection$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Select your team';
	@override String get instructions => 'Sit at the table the staff assigned you, then select the team shown on that table.';
	@override String get unselected => 'Not decided yet';
	@override String current({required Object team}) => 'Your team is ${team}';
	@override String option({required Object team, required Object count}) => '${team} (${count} people)';
	@override String get confirm => 'Confirm this team';
	@override String get sending => 'Sending…';
	@override String get changeHint => 'You can change teams while selection is open.';
	@override String get closed => 'Team selection has closed. Please wait for the questions.';
	@override String get closedUnselected => 'Team selection has closed. Please contact event staff.';
	@override String get changed => 'Your team was changed. Check your current team and select again.';
	@override String get failed => 'Couldn\'t confirm your selection. Check your connection and tap "Confirm this team" again.';
}

// Path: quiz.team
class _Translations$quiz$team$en extends Translations$quiz$team$ja {
	_Translations$quiz$team$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get yourTable => 'Your team';
	@override String get gatherHint => 'Please wait for the question.';
	@override String badge({required Object name}) => 'Team ${name}';
	@override String members({required Object count}) => 'Members · ${count}';
	@override String get you => 'You';
}

// Path: quiz.rules
class _Translations$quiz$rules$en extends Translations$quiz$rules$ja {
	_Translations$quiz$rules$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Quiz rules';
	@override String get teamAnswerTitle => 'One answer per team';
	@override String get teamAnswerBody => 'Anyone on your team can change it until time\'s up. The last accepted answer counts.';
	@override String get scoringTitle => '10 points per question';
	@override String get scoringBody => 'Tied teams share the same rank.';
	@override String get sponsorAwardTitle => 'Sponsor Award';
	@override String get sponsorAwardBody => 'Awarded to teams that answer every question from the same sponsor correctly.';
}

// Path: quiz.entryClosed
class _Translations$quiz$entryClosed$en extends Translations$quiz$entryClosed$ja {
	_Translations$quiz$entryClosed$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Entry is closed';
	@override String get description => 'Results will be shown on this screen.';
}

// Path: quiz.question
class _Translations$quiz$question$en extends Translations$quiz$question$ja {
	_Translations$quiz$question$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String number({required Object n}) => 'Question ${n}';
	@override String sponsoredBy({required Object name}) => '${name}\'s question';
	@override String get secondsUnit => 's';
	@override String get locked => 'Answers are closed';
	@override String get submitFailed => 'Could not submit. The question may have closed.';
	@override String answeredBy({required Object name}) => 'Selected by ${name}';
	@override String get member => 'a member';
	@override String get reading => 'The question is being read. Please wait for answers to open.';
	@override String get synchronizing => 'Checking the remaining time…';
	@override String get connectionUnavailable => 'Connection unavailable. Check your connection and try again.';
	@override String get cached => 'Your team\'s latest answer couldn\'t be confirmed.';
	@override String get tapHint => 'The option you tap becomes your team\'s answer.';
	@override String get sending => 'Sending your answer…';
	@override String get accepted => 'Accepted as your team\'s answer';
	@override String get changeHint => 'Anyone on your team can change it until time\'s up.';
	@override String get submitUnconfirmed => 'Acceptance could not be confirmed. Check your connection and the current team answer, and retry before the deadline.';
}

// Path: quiz.suspense
class _Translations$quiz$suspense$en extends Translations$quiz$suspense$ja {
	_Translations$quiz$suspense$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Time\'s up!';
	@override String get description => 'Waiting for the answer reveal';
}

// Path: quiz.revealed
class _Translations$quiz$revealed$en extends Translations$quiz$revealed$ja {
	_Translations$quiz$revealed$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Answer reveal';
	@override String get correct => 'Correct!';
	@override String get wrong => 'Not this time…';
	@override String get correctLabel => 'Correct';
	@override String get wrongLabel => 'Incorrect';
	@override String get yourAnswer => 'Your team\'s answer';
	@override String teamScore({required Object score}) => 'Total: ${score} pts';
	@override String gain({required Object points}) => '+${points} pts';
}

// Path: quiz.result
class _Translations$quiz$result$en extends Translations$quiz$result$ja {
	_Translations$quiz$result$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Final results';
	@override String table({required Object name}) => 'Team ${name}';
	@override String points({required Object score}) => '${score} pts';
	@override String get yourTeam => 'Your team';
	@override String rank({required Object rank}) => '#${rank}';
	@override String get ranking => 'Ranking';
	@override String get tieNote => 'If teams are tied, how winners are decided will be announced at the venue.';
	@override late final _Translations$quiz$result$award$en award = _Translations$quiz$result$award$en._(_root);
	@override String get error => 'Failed to load results';
}

// Path: venueWalk.photo.poses
class _Translations$venueWalk$photo$poses$en extends Translations$venueWalk$photo$poses$ja {
	_Translations$venueWalk$photo$poses$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get standing => 'Stand';
	@override String get wave => 'Wave';
	@override String get sitting => 'Sit';
	@override String get jumping => 'Jump';
}

// Path: venueEvents.features.quiz
class _Translations$venueEvents$features$quiz$en extends Translations$venueEvents$features$quiz$ja {
	_Translations$venueEvents$features$quiz$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Quiz';
	@override String get action => 'Check in with the QR code on the screen and choose your team';
	@override String get preview => 'Day 2, from 15:30';
}

// Path: venueEvents.features.stampRally
class _Translations$venueEvents$features$stampRally$en extends Translations$venueEvents$features$stampRally$ja {
	_Translations$venueEvents$features$stampRally$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Stamp Rally';
	@override String get action => 'Scan the QR codes at sponsor booths';
	@override String get preview => 'Visit the sponsor booths';
}

// Path: venueEvents.features.profileExchange
class _Translations$venueEvents$features$profileExchange$en extends Translations$venueEvents$features$profileExchange$ja {
	_Translations$venueEvents$features$profileExchange$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Profile Exchange';
	@override String get action => 'Exchange with attendees by QR code or 6-digit code';
	@override String get preview => 'Exchange QR codes with attendees';
}

// Path: venueEvents.features.supportLt
class _Translations$venueEvents$features$supportLt$en extends Translations$venueEvents$features$supportLt$ja {
	_Translations$venueEvents$features$supportLt$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Join Support LT';
	@override String get action => 'Register with the QR code at the venue';
	@override String get preview => 'Register with the venue QR code';
}

// Path: venueEvents.features.snsPost
class _Translations$venueEvents$features$snsPost$en extends Translations$venueEvents$features$snsPost$ja {
	_Translations$venueEvents$features$snsPost$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Register SNS post';
	@override String get action => 'Post a photo and register its URL';
	@override String get preview => 'Register your photo post\'s URL';
}

// Path: venueEvents.features.mission
class _Translations$venueEvents$features$mission$en extends Translations$venueEvents$features$mission$ja {
	_Translations$venueEvents$features$mission$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Missions';
	@override String get preview => 'Support LT, exchanges and SNS posts';
}

// Path: quiz.list.status
class _Translations$quiz$list$status$en extends Translations$quiz$list$status$ja {
	_Translations$quiz$list$status$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get preparing => 'Coming soon';
	@override String get registration => 'Open for entry';
	@override String get entryClosed => 'Registration closed';
	@override String get inProgress => 'In progress';
	@override String get finished => 'Results';
}

// Path: quiz.registration.flow
class _Translations$quiz$registration$flow$en extends Translations$quiz$registration$flow$ja {
	_Translations$quiz$registration$flow$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'How it works';
	@override String get step1Title => 'Join';
	@override String get step2Title => 'Check in at the venue';
	@override String get step2Body => 'Scan the QR code on the screen';
	@override String get step3Title => 'Select your team';
	@override String get step3Body => 'Choose the table (A–T) the staff assigned you';
	@override String get step4Title => 'Answer as a team';
	@override String get step4Body => '10 points per question. Answer every question from one sponsor correctly to win the Sponsor Award.';
}

// Path: quiz.result.award
class _Translations$quiz$result$award$en extends Translations$quiz$result$award$ja {
	_Translations$quiz$result$award$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Sponsor Award';
	@override String perfect({required Object sponsor}) => 'All ${sponsor} questions correct';
	@override String get voucher => 'Event staff will hand you a prize voucher.';
	@override String get voucherHint => 'Please wait for instructions from the staff.';
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
			'links.copied' => 'Link copied',
			'navigation.sessions' => 'Sessions',
			'navigation.venueMap' => 'Venue Map',
			'navigation.sponsors' => 'Sponsors',
			'navigation.info' => 'Event',
			'navigation.account' => 'Account',
			'news.title' => 'News',
			'news.empty' => 'There is no news yet',
			'sponsors.title' => 'Sponsors',
			'sponsors.detailTitle' => 'Sponsor Details',
			'sponsors.subtitle' => 'The sponsors supporting FlutterKaigi 2026',
			'sponsors.empty' => 'Sponsors have not been published yet',
			'sponsors.notFound' => 'Sponsor not found',
			'sponsors.logoSemanticLabel' => ({required Object name}) => '${name} logo',
			'sponsors.githubCardSemanticLabel' => ({required Object name}) => 'View ${name}\'s GitHub profile',
			'sponsors.xCardSemanticLabel' => ({required Object name}) => 'View ${name}\'s X profile',
			'sponsors.externalCardSemanticLabel' => ({required Object name}) => 'Open ${name}\'s link',
			'sponsors.tierBadge' => ({required Object tier}) => '${tier} Sponsor',
			'sponsors.jobBoards' => 'Job Boards',
			'sponsors.jobBoardCta' => 'Hiring information',
			'sponsors.recruitCta' => 'Careers',
			'sponsors.connect' => 'Connect',
			'staffMembers.title' => 'Staff',
			'staffMembers.empty' => 'Staff profiles have not been published yet',
			'staffMembers.error' => 'Failed to load staff profiles',
			'trademarks.flutterAffiliation' => 'Flutter and the related logo are trademarks of Google LLC. FlutterKaigi is not affiliated with or otherwise sponsored by Google LLC.',
			'trademarks.flutterNameAndLogo' => 'The Flutter name and the Flutter logo are trademarks of Google LLC.',
			'trademarks.revComm' => 'RevComm is a registered trademark or trademark of RevComm Inc.',
			'sessionTimetable.title' => 'Timetable',
			'sessionTimetable.dayButtonLabel' => ({required Object day, required Object date}) => 'Day ${day} (${date})',
			'sessionTimetable.view.list' => 'List',
			'sessionTimetable.view.rooms' => 'By room',
			'sessionTimetable.view.saveFailed' => 'Could not save the view preference',
			'sessionTimetable.view.shared' => 'Shared',
			'sessionTimetable.empty' => 'The timetable has not been published yet',
			'sessionTimetable.emptyFiltered' => 'There are no items for this day',
			'sessionTimetable.venue.unknown' => 'Venue TBA',
			'sessionTimetable.speaker.none' => 'Speaker TBA',
			'sessionTimetable.type.regular' => 'Regular Talk',
			'sessionTimetable.type.lightningTalk' => 'Lightning Talk',
			'sessionTimetable.type.beginnersLightningTalk' => 'Beginners LT',
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
			'sessionDetails.feedback' => 'Send session feedback',
			'sessionDetails.feedbackDescription' => 'Let us know what you thought of this session',
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
			'venueMap.title' => 'Venue Map',
			'venueMap.floor' => 'Hamamatsucho Convention Hall · 5F',
			'venueMap.loadError' => 'Could not load the venue map',
			'venueMap.loadErrorDescription' => 'Please try again.',
			'venueMap.search' => 'Find a place',
			'venueMap.searchHint' => 'Hall, sponsor, booth number, facility',
			'venueMap.clearSearch' => 'Clear search',
			'venueMap.placesCount' => 'places',
			'venueMap.showOnMap' => 'Show on map',
			'venueMap.all' => 'All',
			'venueMap.halls' => 'Halls',
			'venueMap.booths' => 'Sponsors',
			'venueMap.facilities' => 'Facilities',
			'venueMap.noResults' => 'No matching places',
			'venueMap.clearSelection' => 'Clear selection',
			'venueMap.zoomIn' => 'Zoom in',
			'venueMap.zoomOut' => 'Zoom out',
			'venueMap.fit' => 'Show entire floor',
			'venueMap.rotate' => 'Rotate map',
			'venueMap.twoD' => '2D',
			'venueMap.threeD' => '3D',
			'venueMap.viewMode' => 'Map view',
			'venueMap.useTwoD' => 'Show in 2D',
			'venueMap.saveFailed' => 'Could not save the view preference',
			'venueWalk.sceneLabel' => 'Explore the venue with Dashumaru. Walk using the stick, a tap on the floor, or the arrow keys.',
			'venueWalk.currentLocation' => 'You are at',
			'venueWalk.entrance' => 'Entrance',
			'venueWalk.entranceSign' => 'Entrance',
			'venueWalk.selectedPoint' => 'Selected spot',
			'venueWalk.headingTo' => ({required Object place}) => 'Walking to ${place}',
			'venueWalk.arrivedAt' => ({required Object place}) => 'Arrived at ${place}',
			'venueWalk.unreachable' => 'Cannot walk to that spot',
			'venueWalk.photoMode' => 'Photo mode',
			'venueWalk.walkToPhotoSpot' => 'Walk to the photo spot',
			'venueWalk.followTooltip' => 'Follow Dashumaru',
			'venueWalk.overviewTooltip' => 'View the entire floor',
			'venueWalk.follow' => 'Follow',
			'venueWalk.overview' => 'Overview',
			'venueWalk.help' => 'How to play',
			'venueWalk.stickHint' => 'Use the stick to walk',
			'venueWalk.stickLabel' => 'Stick to move Dashumaru',
			'venueWalk.stopTooltip' => 'Stop walking',
			'venueWalk.stop' => 'Stop here',
			'venueWalk.reset' => 'Return to the entrance',
			'venueWalk.wave' => 'Wave',
			'venueWalk.backToWalk' => 'Back to walking',
			'venueWalk.run' => 'Run',
			'venueWalk.runningSpeed' => 'Running',
			'venueWalk.walkingSpeed' => 'Walking',
			'venueWalk.runHint' => 'Hold to run. Release to walk. On a keyboard, hold Shift.',
			'venueWalk.close' => 'Close',
			'venueWalk.instructions.title' => 'Exploring the venue',
			'venueWalk.instructions.movement' => 'Use the stick at the bottom left to walk. Hold the run icon at the bottom right to run, and release it to walk again.',
			'venueWalk.instructions.camera' => 'Drag the background to look around and pinch to zoom. Tap the floor to walk to that spot automatically.',
			'venueWalk.instructions.places' => 'Use “Find a place” to choose a destination and explore the four halls. Tap the map icon for a view of the entire floor.',
			'venueWalk.instructions.photos' => 'Tap the camera to take a photo. The picture icon beside it takes you to the creative board. Choose a pose and frame for your photo.',
			'venueWalk.instructions.keyboard' => 'On a computer, use W A S D or the arrow keys to move. Hold Shift to run and press Esc to stop.',
			'venueWalk.instructions.scope' => 'Explore the venue on the fifth floor. This does not show your real location, and you cannot use the escalators to change floors.',
			'venueWalk.instructions.credits' => '3D model: yakitama5 / flutter_deck_slides\nDashumaru: FlutterKaigi',
			'venueWalk.photo.title' => 'A photo with Dashumaru',
			'venueWalk.photo.resultTitle' => 'Your photo',
			'venueWalk.photo.imageLabel' => 'A souvenir photo of Dashumaru',
			'venueWalk.photo.downloadStarted' => 'Your photo download has started',
			'venueWalk.photo.saveFailed' => 'Could not save the photo. Please try again.',
			'venueWalk.photo.savePng' => 'Save PNG',
			'venueWalk.photo.captureFailed' => 'Could not take the photo. Please try again.',
			'venueWalk.photo.caption' => 'Exploring the venue with Dashumaru.',
			'venueWalk.photo.captionAt' => ({required Object place}) => 'With Dashumaru at ${place}.',
			'venueWalk.photo.shutter' => 'Take a photo',
			'venueWalk.photo.capturing' => 'Taking photo',
			'venueWalk.photo.hideUi' => 'Hide controls. Tap the screen to bring them back',
			'venueWalk.photo.faceCamera' => 'Face the camera',
			'venueWalk.photo.removeFrame' => 'Remove frame',
			'venueWalk.photo.addFrame' => 'Add frame',
			'venueWalk.photo.poses.standing' => 'Stand',
			'venueWalk.photo.poses.wave' => 'Wave',
			'venueWalk.photo.poses.sitting' => 'Sit',
			'venueWalk.photo.poses.jumping' => 'Jump',
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
			'eventInfo.credits' => 'Credits',
			'eventInfo.contributors' => 'Contributors',
			'eventInfo.other' => 'Other',
			'eventInfo.officialWebsite' => 'Official Website',
			'eventInfo.codeOfConduct' => 'Code of Conduct',
			'eventInfo.privacyPolicy' => 'Privacy Policy',
			'eventInfo.exclusionPolicy' => 'Exclusion of Anti-Social Forces',
			'eventInfo.contact' => 'Contact',
			'eventInfo.sourceCode' => 'View Source Code',
			'eventInfo.staffMembers' => 'Staff',
			'eventInfo.ossLicenses' => 'OSS Licenses',
			'eventInfo.survey.title' => 'Survey Request',
			'eventInfo.survey.description' => 'We would like to hear your opinions to make future FlutterKaigi events better.',
			'eventInfo.survey.button' => 'Answer the General Survey',
			'contributors.title' => 'Contributors',
			'contributors.openRepository' => 'Open the FlutterKaigi/2026 repository',
			'contributors.empty' => 'No contributors found',
			'contributors.contributionsCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} contribution', other: '${n} contributions', ), 
			'auth.signIn.required' => 'Sign in required',
			'auth.signIn.accountTitle' => 'Sign in',
			'auth.signIn.accountDescription' => 'Your profile and venue event records\nare saved to your account',
			'auth.signIn.withGoogle' => 'Sign in with Google',
			'auth.signIn.withApple' => 'Sign in with Apple',
			'auth.signIn.withEmail' => 'Sign in with email',
			'auth.email.title' => 'Sign in with email',
			'auth.email.emailLabel' => 'Email address',
			'auth.email.passwordLabel' => 'Password',
			'auth.email.emailRequired' => 'Enter your email address',
			'auth.email.passwordRequired' => 'Enter your password',
			'auth.email.showPassword' => 'Show password',
			'auth.email.hidePassword' => 'Hide password',
			'auth.email.signInButton' => 'Sign in',
			'auth.email.createAccountButton' => 'Create account',
			'auth.email.switchToCreateAccount' => 'Create a new account',
			'auth.email.switchToSignIn' => 'Sign in with an existing account',
			'auth.email.forgotPassword' => 'Reset your password',
			'auth.email.resetEmailSent' => 'Password reset email sent',
			'auth.account.title' => 'Account',
			'auth.account.signedIn' => 'Signed in',
			'auth.account.signOut' => 'Sign out',
			'auth.account.noEmail' => 'No email address',
			'auth.account.delete' => 'Delete account',
			'auth.account.deleteConfirmTitle' => 'Delete your account?',
			'auth.account.deleteConfirmBody' => 'Your account will be permanently deleted and cannot be restored. Re-authentication is required before deletion.',
			'auth.account.deleteConfirmAction' => 'Delete',
			'auth.account.deletePasswordTitle' => 'Confirm your password',
			'auth.account.deletePasswordBody' => 'Enter your current password to delete your account.',
			'auth.account.deleted' => 'Your account has been deleted',
			'auth.account.cancel' => 'Cancel',
			'auth.error.invalidEmail' => 'The email address is badly formatted',
			'auth.error.userDisabled' => 'This account has been disabled',
			'auth.error.invalidCredential' => 'Incorrect email address or password',
			'auth.error.emailAlreadyInUse' => 'This email address is already in use',
			'auth.error.weakPassword' => 'The password is too weak. Choose a stronger password',
			'auth.error.tooManyRequests' => 'Too many attempts. Please try again later',
			'auth.error.network' => 'A network error occurred. Check your connection and try again',
			'auth.error.requiresRecentLogin' => 'Recent authentication is required. Please try again',
			'auth.error.userMismatch' => 'The re-authenticated account does not match the signed-in account',
			'auth.error.appleTokenRevocationFailed' => 'Could not delete the account because revoking the Apple token failed. Please try again',
			'auth.error.unknown' => 'Authentication failed. Please try again',
			'profile.title' => 'Profile',
			'profile.signInRequired' => 'Sign in to create your profile',
			'profile.editTitle' => 'Edit Profile',
			'profile.createTitle' => 'Create Profile',
			'profile.promptTitle' => 'Set up your profile',
			'profile.promptBody' => 'Add your country or region and social links to exchange profiles with other attendees at the venue.',
			'profile.create' => 'Create profile',
			'profile.edit' => 'Edit profile',
			'profile.save' => 'Save',
			'profile.saved' => 'Profile saved',
			'profile.saveFailed' => 'Could not save the profile',
			'profile.visibilityNote' => 'Your profile is visible to other signed-in attendees',
			'profile.avatarSemanticLabel' => 'Profile picture',
			'profile.displayNameLabel' => 'Display name',
			'profile.displayNameRequired' => 'Enter a display name',
			'profile.countryLabel' => 'Country / Region',
			'profile.countryPlaceholder' => 'Select',
			'profile.countryRequired' => 'Select your country or region',
			'profile.countrySearchHint' => 'Search countries and regions',
			'profile.countryNoResults' => ({required Object query}) => 'No countries or regions match "${query}"',
			'profile.countryNoResultsHint' => 'You can also search by Japanese name or ISO code',
			'profile.snsLinksLabel' => 'Social links',
			'profile.snsLinksEmpty' => 'Add links to X, GitHub and more',
			'profile.addSnsLink' => 'Add a link',
			'profile.removeSnsLink' => 'Remove this link',
			'profile.snsPlatformLabel' => 'Service',
			'profile.snsUrlLabel' => 'URL',
			'profile.snsIdOrUrlLabel' => 'ID or URL',
			'profile.snsIdOrUrlRequired' => 'Enter an ID or URL',
			'profile.snsIdOrUrlInvalid' => 'Enter a valid ID or a URL starting with https://',
			'profile.snsUrlRequired' => 'Enter a URL',
			'profile.snsUrlInvalid' => 'Enter a URL starting with https://',
			'profile.snsLinksMax' => ({required Object n}) => 'You can add up to ${n} links',
			'profile.snsPlatformOther' => 'Other',
			'profile.bioLabel' => 'Bio',
			'profile.bioHint' => 'What you work on, what you\'d like to talk about today, etc.',
			'profile.discardTitle' => 'Discard changes?',
			'profile.discardBody' => 'Unsaved changes will be lost.',
			'profile.discardAction' => 'Discard',
			'profile.keepEditing' => 'Keep editing',
			'snsPost.title' => 'Register SNS post',
			'snsPost.signInRequired' => 'Sign in to register your SNS post',
			'snsPost.heading' => 'Register your photo post',
			'snsPost.description' => 'Post a photo with an eligible attendee on SNS,\nthen register the URL of that post.',
			'snsPost.companionLabel' => 'Who is in your photo?',
			'snsPost.companionHint' => 'Choose one category for the person in the photo',
			'snsPost.companionRequired' => 'Choose one companion category',
			'snsPost.companions.staff' => 'Staff',
			'snsPost.companions.speaker' => 'Speaker',
			'snsPost.companions.sponsor' => 'Sponsor',
			'snsPost.companions.firstTime' => 'First-time attendee',
			'snsPost.companions.differentCountry' => 'Different country or region',
			'snsPost.urlLabel' => 'SNS post URL',
			'snsPost.urlHint' => 'Link to the photo post, not your profile page',
			'snsPost.invalidUrl' => 'Enter a valid post URL (https://…)',
			'snsPost.register' => 'Register post',
			'snsPost.update' => 'Update registration',
			'snsPost.saving' => 'Saving…',
			'snsPost.cancel' => 'Cancel',
			'snsPost.saveFailed' => 'Could not save. Check your connection and try again.',
			'snsPost.invalidRegistration' => 'The saved registration could not be read. Register the post URL and companion category again.',
			'snsPost.registeredTitle' => 'SNS post registered',
			'snsPost.registeredBody' => 'Your SNS post mission is complete.',
			'snsPost.updatedAt' => ({required Object date}) => 'Updated: ${date}',
			'snsPost.openPost' => 'Open post',
			'snsPost.openFailed' => 'Could not open the post',
			'snsPost.viewMissions' => 'View mission progress',
			'snsPost.edit' => 'Edit URL or category',
			'mission.title' => 'Missions',
			'mission.signInRequired' => 'Sign in to view your mission progress',
			'mission.complete' => 'Complete',
			'mission.incomplete' => 'Incomplete',
			'mission.loading' => 'Checking',
			'mission.loadFailed' => 'Unavailable',
			'mission.allComplete' => 'All missions complete!',
			'mission.inProgress' => 'Mission progress',
			'mission.checkFailed' => 'Some results are unavailable',
			'mission.progress' => ({required Object n, required Object total}) => '${n} of ${total} missions complete',
			'mission.ltTitle' => 'Join Support LT',
			'mission.ltDescription' => 'Supporters and speakers register with the code at the venue',
			'mission.exchangeTitle' => 'Exchange profiles',
			'mission.exchangeDescription' => ({required Object required}) => 'Meet at least ${required} people, including someone from a different country or region',
			'mission.exchangeCount' => ({required Object n, required Object required}) => '${n} / ${required} people met',
			'mission.differentCountry' => 'Met someone from a different country or region',
			'mission.profileRequired' => 'Add your country or region to your profile',
			'mission.snsTitle' => 'Share a photo on SNS',
			'mission.snsDescription' => 'Post a photo with an eligible attendee and register its URL and category',
			'venueEvents.title' => 'Join Venue Events',
			'venueEvents.entrySubtitle' => 'Stamp rally, profile exchange and more',
			'venueEvents.day1' => 'Thu, Oct 29 · Day 1',
			'venueEvents.day2' => 'Fri, Oct 30 · Day 2',
			'venueEvents.signInTitle' => 'Sign in to take part',
			'venueEvents.signInDescription' => 'Your stamps and quiz records are saved to your account.',
			'venueEvents.previewHeading' => 'Sign in to join these activities',
			'venueEvents.features.quiz.title' => 'Quiz',
			'venueEvents.features.quiz.action' => 'Check in with the QR code on the screen and choose your team',
			'venueEvents.features.quiz.preview' => 'Day 2, from 15:30',
			'venueEvents.features.stampRally.title' => 'Stamp Rally',
			'venueEvents.features.stampRally.action' => 'Scan the QR codes at sponsor booths',
			'venueEvents.features.stampRally.preview' => 'Visit the sponsor booths',
			'venueEvents.features.profileExchange.title' => 'Profile Exchange',
			'venueEvents.features.profileExchange.action' => 'Exchange with attendees by QR code or 6-digit code',
			'venueEvents.features.profileExchange.preview' => 'Exchange QR codes with attendees',
			'venueEvents.features.supportLt.title' => 'Join Support LT',
			'venueEvents.features.supportLt.action' => 'Register with the QR code at the venue',
			'venueEvents.features.supportLt.preview' => 'Register with the venue QR code',
			'venueEvents.features.snsPost.title' => 'Register SNS post',
			'venueEvents.features.snsPost.action' => 'Post a photo and register its URL',
			'venueEvents.features.snsPost.preview' => 'Register your photo post\'s URL',
			'venueEvents.features.mission.title' => 'Missions',
			'venueEvents.features.mission.preview' => 'Support LT, exchanges and SNS posts',
			'venueEvents.status.registered' => 'Registered',
			'venueEvents.status.checkedIn' => 'Checked in',
			'venueEvents.status.team' => ({required Object team}) => 'Team ${team}',
			'venueEvents.status.stampCount' => ({required Object n, required Object total}) => '${n} / ${total}',
			'venueEvents.status.exchangeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} person', other: '${n} people', ), 
			'venueEvents.quizCheckIn.title' => 'Quiz check-in is open',
			'venueEvents.quizCheckIn.body' => 'Scan the QR code on the venue screen',
			'eventGuide.title' => 'Event day guide',
			'eventGuide.open' => 'View the event day guide',
			'eventGuide.skip' => 'Skip',
			'eventGuide.next' => 'Next',
			'eventGuide.close' => 'Close',
			'eventGuide.pageIndicator' => ({required Object page, required Object total}) => 'Page ${page} of ${total}',
			'eventGuide.welcome.title' => 'Welcome to FlutterKaigi 2026',
			'eventGuide.welcome.body' => 'Here are three features you\'ll use at the event',
			'eventGuide.sessions.title' => 'Bookmark sessions',
			'eventGuide.sessions.body' => 'After a session ends, you can send\nfeedback from its details screen',
			'eventGuide.sessions.sampleTime' => '11:00 – 11:40',
			'eventGuide.sessions.sampleRoom' => 'Hall A',
			'eventGuide.sessions.afterSession' => 'After the session',
			'eventGuide.venueEvents.title' => 'Connect with attendees and sponsors',
			'eventGuide.venueEvents.body' => 'Start the stamp rally and profile exchange\nfrom “Join Venue Events”',
			'eventGuide.venueEvents.eventTab' => 'Event tab',
			'eventGuide.quiz.title' => 'Quiz on Day 2',
			'eventGuide.quiz.body' => 'After registering, check in with\nthe QR code on the screen',
			'eventGuide.quiz.checkInOpens' => 'Check-in opens',
			'eventGuide.quiz.firstRound' => 'First round',
			'eventGuide.quiz.secondRound' => 'Second round',
			'eventGuide.quiz.firstRoundTime' => '15:30',
			'eventGuide.quiz.secondRoundTime' => '16:30',
			'stampRally.title' => 'Stamp Rally',
			'stampRally.signInRequired' => 'Sign in to collect stamps',
			'stampRally.description' => 'Scan the QR codes at sponsor booths to collect stamps',
			'stampRally.scanButton' => 'Scan QR code',
			'stampRally.sponsorsButton' => 'View stamps by sponsor',
			'stampRally.sponsorsTitle' => 'Stamps by sponsor',
			'stampRally.sponsorsDescription' => 'See which sponsors you have collected stamps from',
			'stampRally.sponsorsSignInRequired' => 'Sign in to see your stamp collection by sponsor',
			'stampRally.sponsorsEmpty' => 'No participating sponsors yet',
			'stampRally.sponsorUnavailable' => ({required Object id}) => 'Sponsor (${id})',
			'stampRally.sponsorAcquiredAt' => ({required Object date}) => 'Collected at ${date}',
			'stampRally.lumaTicketButton' => 'Open ticket in Luma',
			'stampRally.lumaTicketDescription' => 'Show your Luma ticket QR code to the staff when collecting prizes',
			'stampRally.closed' => 'Stamps are not available right now. Prizes and the crane game are still available',
			'stampRally.stampCount' => ({required Object n, required Object total}) => '${n} / ${total}',
			'stampRally.stampCountSemantic' => ({required Object n, required Object total}) => '${n} of ${total} stamps collected',
			'stampRally.nextCheckpoint' => ({required Object n, required Object number}) => '${n} more for prize #${number}',
			'stampRally.allCheckpoints' => 'You have reached every prize',
			'stampRally.checkpointLabel' => ({required Object number, required Object required}) => '#${number} (${required} stamps)',
			'stampRally.checkpointLocked' => 'Not yet',
			'stampRally.checkpointAchieved' => 'Ready to redeem',
			'stampRally.checkpointRedeemed' => ({required Object date}) => 'Redeemed ${date}',
			'stampRally.thanksCardTitle' => 'Crane game',
			'stampRally.thanksCardDescription' => 'Collect thanks cards at the venue to play the crane game once',
			'stampRally.thanksCardNotRedeemed' => 'Not played',
			'stampRally.thanksCardRedeemed' => ({required Object date}) => 'Played ${date}',
			'stampRally.roadmapTitle' => 'Stamps',
			'stampRally.stampSlotSemantic' => ({required Object n, required Object status}) => 'Stamp ${n}, ${status}',
			'stampRally.acquired' => 'Collected',
			'stampRally.notAcquired' => 'Not collected',
			'stampRally.scanTitle' => 'Scan QR code',
			'stampRally.scanHint' => 'Fit the QR code at a sponsor booth or the prize counter inside the frame',
			'stampRally.scanInvalid' => 'This is not a stamp rally QR code',
			'stampRally.scanCameraError' => 'The camera is unavailable. Allow camera access in Settings',
			'stampRally.resultTitle' => 'Stamp Rally',
			'stampRally.processing' => 'Checking…',
			'stampRally.stampAcquiredTitle' => 'Stamp collected!',
			'stampRally.stampAlreadyTitle' => 'You already have this stamp',
			'stampRally.checkpointReached' => ({required Object number}) => 'You reached prize #${number}!',
			'stampRally.rewardTitle' => 'Prize redemption',
			'stampRally.rewardRedeemedTitle' => ({required Object numbers}) => 'You can receive prize ${numbers}',
			'stampRally.rewardNoneTitle' => 'No new prizes to redeem',
			'stampRally.rewardNoneBody' => ({required Object n}) => 'You have ${n} stamps',
			'stampRally.rewardStaffNote' => 'Show this screen to the staff',
			'stampRally.rewardRedeemedAt' => ({required Object number, required Object date}) => '#${number} redeemed ${date}',
			'stampRally.thanksCardResultTitle' => 'You can play the crane game',
			'stampRally.thanksCardAlreadyTitle' => 'You have already played the crane game',
			'stampRally.thanksCardResultAt' => ({required Object date}) => 'Checked in ${date}',
			'stampRally.invalidTitle' => 'Invalid QR code',
			'stampRally.invalidBody' => 'Check that this is a stamp rally QR code',
			'stampRally.closedTitle' => 'Stamps are not available right now',
			'stampRally.networkError' => 'Could not connect. Try again somewhere with a better signal',
			'stampRally.failed' => 'Something went wrong',
			'stampRally.sessionExpired' => 'Please sign in again',
			'stampRally.permissionDenied' => 'This account cannot take part',
			'stampRally.retry' => 'Try again',
			'stampRally.viewCard' => 'View stamp rally',
			'exchange.title' => 'Profile Exchange',
			'exchange.qrDescription' => 'Show this QR code to another attendee and have them scan it to exchange profiles',
			'exchange.qrSemanticLabel' => 'Profile exchange QR code',
			'exchange.qrExpiresAt' => ({required Object date}) => 'Valid until ${date}',
			'exchange.scanButton' => 'Scan a QR code',
			'exchange.listButton' => 'View exchanged profiles',
			'exchange.signInRequired' => 'Sign in to show your QR code',
			'exchange.profileRequired' => 'Create a profile to show your QR code',
			'exchange.profileRequiredAction' => 'Create profile',
			'exchange.scanTitle' => 'Scan a QR code',
			'exchange.scanHint' => 'Line up the other attendee\'s QR code within the frame',
			'exchange.scanCameraError' => 'Camera unavailable. Please allow camera access in Settings',
			'exchange.scanInvalid' => 'Could not read this code. Make sure it\'s a profile exchange QR code',
			'exchange.scanSelf' => 'You can\'t scan your own QR code',
			'exchange.scanSucceeded' => 'Profile exchanged',
			'exchange.scanAlreadyExists' => 'Already exchanged',
			'exchange.scanFailed' => 'Could not exchange profiles',
			'exchange.listTitle' => 'Exchanged Profiles',
			'exchange.listEmpty' => 'No exchanges yet',
			'exchange.listEmptyBody' => 'Scan a QR code to exchange profiles with other attendees',
			'exchange.profileUnavailable' => 'This profile is no longer available',
			'exchange.deleteTooltip' => 'Delete',
			'exchange.deleteConfirmTitle' => 'Delete this exchange?',
			'exchange.deleteConfirmBody' => 'This only removes it from your own list. The other attendee\'s list is unaffected.',
			'exchange.deleteConfirmAction' => 'Delete',
			'exchange.deleteCancel' => 'Cancel',
			'exchange.deleteFailed' => 'Could not delete the exchange',
			'exchange.noteAddTooltip' => 'Add a note',
			'exchange.noteEditTooltip' => 'Edit note',
			'exchange.noteEditTitle' => 'Note',
			'exchange.noteEditHint' => 'Visible only to you',
			'exchange.noteLabel' => 'Note',
			'exchange.noteSave' => 'Save',
			'exchange.noteCancel' => 'Cancel',
			'exchange.noteSaveFailed' => 'Could not save the note',
			'exchange.codeSectionTitle' => 'Exchange with a code',
			'exchange.codeSectionDescription' => 'If the camera isn\'t available, share and enter a 6-digit code instead. The same code works for everyone until it expires',
			'exchange.myCodeSemanticLabel' => 'Profile exchange 6-digit code',
			'exchange.myCodeExpiresAt' => ({required Object date}) => 'Valid until ${date}',
			'exchange.myCodeExpired' => 'This code has expired',
			'exchange.myCodeRefresh' => 'Get a new code',
			'exchange.myCodeCopy' => 'Copy code',
			'exchange.myCodeCopied' => 'Code copied',
			'exchange.enterCodeLabel' => 'Enter the other attendee\'s code',
			'exchange.enterCodeHint' => '123456',
			'exchange.enterCodeButton' => 'Exchange',
			'exchange.enterCodeInvalidFormat' => 'Enter a 6-digit code',
			'exchange.redeemInvalid' => 'This code wasn\'t found, or it has expired',
			'exchange.redeemSelf' => 'You can\'t enter your own code',
			'exchange.redeemRateLimited' => 'Too many attempts. Please try again in a few minutes',
			'exchange.shareLinkSignInRequired' => 'Sign in to exchange profiles with them',
			'exchange.shareLinkProfileRequired' => 'Create a profile to exchange profiles with them',
			'exchange.shareLinkInvalidTitle' => 'This link isn\'t valid',
			'exchange.shareLinkInvalidBody' => 'Make sure it\'s a profile exchange link',
			'exchange.shareLinkExpiredTitle' => 'This link has expired',
			'exchange.shareLinkExpiredBody' => 'Ask the other attendee to share their QR code or link again',
			'exchange.shareLinkSelfTitle' => 'This is your own share link',
			'exchange.shareLinkSelfBody' => 'Other attendees who open this link can exchange profiles with you',
			'exchange.shareLinkGoHome' => 'Back to home',
			'exchange.shareLinkViewList' => 'View exchanged profiles',
			'supportLt.title' => 'Support LT Registration',
			'supportLt.description' => 'Scan the QR code shown at the venue to register your participation in Support LT',
			'supportLt.scanButton' => 'Scan the QR code',
			'supportLt.scanTitle' => 'Scan the QR code',
			'supportLt.scanHint' => 'Line up the QR code shown at the venue within the frame',
			'supportLt.scanCameraError' => 'Camera unavailable. Allow camera access in Settings, or enter the 6-digit code on the previous screen',
			'supportLt.scanInvalid' => 'Could not read this code. Make sure it\'s the Support LT registration QR code',
			'supportLt.linkInvalid' => 'This link isn\'t valid. Scan the QR code at the venue again',
			'supportLt.codeSectionTitle' => 'If you can\'t scan the QR code',
			'supportLt.codeSectionDescription' => 'Enter the 6-digit code provided by the organizers',
			'supportLt.codeLabel' => 'Registration code',
			'supportLt.register' => 'Register participation',
			'supportLt.submitting' => 'Registering…',
			'supportLt.registeredTitle' => 'Registration complete',
			'supportLt.registeredBody' => 'Enjoy Support LT',
			'supportLt.backToAccount' => 'Back to account',
			'supportLt.signInRequired' => 'Sign in to register your participation in Support LT',
			'supportLt.invalidFormat' => 'Enter a 6-digit code',
			'supportLt.invalidCode' => 'This code is incorrect. Scan the QR code at the venue again or ask the organizers',
			'supportLt.rateLimited' => 'Too many attempts. Please try again in a few minutes',
			'supportLt.networkError' => 'A network error occurred. Check your connection and try again',
			'supportLt.sessionExpired' => 'Your sign-in session has expired. Please sign in again',
			'supportLt.permissionDenied' => 'Registration is not permitted. Please ask the organizers',
			'supportLt.registrationFailed' => 'Could not register your participation. Please try again',
			'countryRegion.asia' => 'Asia',
			_ => null,
		} ?? switch (path) {
			'countryRegion.oceania' => 'Oceania',
			'countryRegion.americas' => 'Americas',
			'countryRegion.europe' => 'Europe',
			'countryRegion.africa' => 'Africa',
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
			'common.retry' => 'Retry',
			'quiz.title' => 'Quiz',
			'quiz.list.empty' => 'No quizzes yet',
			'quiz.list.error' => 'Failed to load quizzes',
			'quiz.list.status.preparing' => 'Coming soon',
			'quiz.list.status.registration' => 'Open for entry',
			'quiz.list.status.entryClosed' => 'Registration closed',
			'quiz.list.status.inProgress' => 'In progress',
			'quiz.list.status.finished' => 'Results',
			'quiz.signInRequired.inPage' => 'Sign in to take part in the quiz',
			'quiz.errors.signInFailed' => 'Failed to sign in',
			'quiz.errors.eventLoadFailed' => 'Failed to load the event',
			'quiz.preparing.title' => 'The quiz is being prepared',
			'quiz.preparing.description' => 'Once it is announced, you can join from this screen.',
			'quiz.registration.subtitle' => 'You can join only one round.',
			'quiz.registration.participantCount' => 'Participants:',
			'quiz.registration.participantUnit' => '',
			'quiz.registration.capacity' => ({required Object max}) => '/ ${max}',
			'quiz.registration.join' => 'Join',
			'quiz.registration.full' => ({required Object max}) => 'Full capacity (${max} participants) reached',
			'quiz.registration.failed' => 'Could not register. Please try again later.',
			'quiz.registration.alreadyParticipated' => 'You have already registered for another round and cannot join this one.',
			'quiz.registration.closed' => 'Registration for this round has closed.',
			'quiz.registration.unavailable' => 'Registration could not be confirmed. Check your connection and try again.',
			'quiz.registration.accountUnavailable' => 'This account cannot join. Please contact event staff.',
			'quiz.registration.flow.title' => 'How it works',
			'quiz.registration.flow.step1Title' => 'Join',
			'quiz.registration.flow.step2Title' => 'Check in at the venue',
			'quiz.registration.flow.step2Body' => 'Scan the QR code on the screen',
			'quiz.registration.flow.step3Title' => 'Select your team',
			'quiz.registration.flow.step3Body' => 'Choose the table (A–T) the staff assigned you',
			'quiz.registration.flow.step4Title' => 'Answer as a team',
			'quiz.registration.flow.step4Body' => '10 points per question. Answer every question from one sponsor correctly to win the Sponsor Award.',
			'quiz.waiting.title' => 'Registration confirmed',
			'quiz.waiting.description' => 'When check-in opens, scan the QR code on the venue screen.',
			'quiz.progress.join' => 'Join',
			'quiz.progress.checkIn' => 'Check in',
			'quiz.progress.selectTeam' => 'Choose team',
			'quiz.progress.semantic' => ({required Object current, required Object total}) => 'Step ${current} of ${total}',
			'quiz.checkIn.title' => 'Check-in',
			'quiz.checkIn.instructions' => 'Scan the QR code shown on the venue screen.',
			'quiz.checkIn.scanButton' => 'Scan the QR code',
			'quiz.checkIn.scanTitle' => 'Scan the QR code',
			'quiz.checkIn.scanHint' => 'Line up the QR code shown on the venue screen within the frame',
			'quiz.checkIn.scanCameraError' => 'Camera unavailable. Allow camera access in Settings, or enter the 6-digit check-in code on the previous screen',
			'quiz.checkIn.scanInvalid' => 'Could not read this code. Make sure it\'s the quiz check-in QR code',
			'quiz.checkIn.scanOtherEvent' => 'This QR code is for another round. Scan the QR code for the round you registered for',
			'quiz.checkIn.codeSectionTitle' => 'If you can\'t scan the QR code',
			'quiz.checkIn.codeLabel' => 'Check-in code',
			'quiz.checkIn.submit' => 'Check in',
			'quiz.checkIn.submitting' => 'Checking…',
			'quiz.checkIn.invalidFormat' => 'Enter a 6-digit code',
			'quiz.checkIn.linkInvalid' => 'This link isn\'t valid. Scan the QR code at the venue again',
			'quiz.checkIn.wrongCode' => 'That code is incorrect. Check the 6-digit code on the screen and enter it again.',
			'quiz.checkIn.rateLimited' => 'Too many attempts. Wait about a minute and try again',
			'quiz.checkIn.closed' => 'Check-in has closed. Please contact event staff.',
			'quiz.checkIn.notRegistered' => 'Your registration was canceled. To take part, please ask a staff member.',
			'quiz.checkIn.unavailable' => 'Could not confirm your check-in. Check your connection and try again.',
			'quiz.checkIn.failed' => 'Couldn\'t check you in. Update the app to the latest version, sign in again, and try again.',
			'quiz.selection.title' => 'Select your team',
			'quiz.selection.instructions' => 'Sit at the table the staff assigned you, then select the team shown on that table.',
			'quiz.selection.unselected' => 'Not decided yet',
			'quiz.selection.current' => ({required Object team}) => 'Your team is ${team}',
			'quiz.selection.option' => ({required Object team, required Object count}) => '${team} (${count} people)',
			'quiz.selection.confirm' => 'Confirm this team',
			'quiz.selection.sending' => 'Sending…',
			'quiz.selection.changeHint' => 'You can change teams while selection is open.',
			'quiz.selection.closed' => 'Team selection has closed. Please wait for the questions.',
			'quiz.selection.closedUnselected' => 'Team selection has closed. Please contact event staff.',
			'quiz.selection.changed' => 'Your team was changed. Check your current team and select again.',
			'quiz.selection.failed' => 'Couldn\'t confirm your selection. Check your connection and tap "Confirm this team" again.',
			'quiz.team.yourTable' => 'Your team',
			'quiz.team.gatherHint' => 'Please wait for the question.',
			'quiz.team.badge' => ({required Object name}) => 'Team ${name}',
			'quiz.team.members' => ({required Object count}) => 'Members · ${count}',
			'quiz.team.you' => 'You',
			'quiz.rules.title' => 'Quiz rules',
			'quiz.rules.teamAnswerTitle' => 'One answer per team',
			'quiz.rules.teamAnswerBody' => 'Anyone on your team can change it until time\'s up. The last accepted answer counts.',
			'quiz.rules.scoringTitle' => '10 points per question',
			'quiz.rules.scoringBody' => 'Tied teams share the same rank.',
			'quiz.rules.sponsorAwardTitle' => 'Sponsor Award',
			'quiz.rules.sponsorAwardBody' => 'Awarded to teams that answer every question from the same sponsor correctly.',
			'quiz.entryClosed.title' => 'Entry is closed',
			'quiz.entryClosed.description' => 'Results will be shown on this screen.',
			'quiz.question.number' => ({required Object n}) => 'Question ${n}',
			'quiz.question.sponsoredBy' => ({required Object name}) => '${name}\'s question',
			'quiz.question.secondsUnit' => 's',
			'quiz.question.locked' => 'Answers are closed',
			'quiz.question.submitFailed' => 'Could not submit. The question may have closed.',
			'quiz.question.answeredBy' => ({required Object name}) => 'Selected by ${name}',
			'quiz.question.member' => 'a member',
			'quiz.question.reading' => 'The question is being read. Please wait for answers to open.',
			'quiz.question.synchronizing' => 'Checking the remaining time…',
			'quiz.question.connectionUnavailable' => 'Connection unavailable. Check your connection and try again.',
			'quiz.question.cached' => 'Your team\'s latest answer couldn\'t be confirmed.',
			'quiz.question.tapHint' => 'The option you tap becomes your team\'s answer.',
			'quiz.question.sending' => 'Sending your answer…',
			'quiz.question.accepted' => 'Accepted as your team\'s answer',
			'quiz.question.changeHint' => 'Anyone on your team can change it until time\'s up.',
			'quiz.question.submitUnconfirmed' => 'Acceptance could not be confirmed. Check your connection and the current team answer, and retry before the deadline.',
			'quiz.suspense.title' => 'Time\'s up!',
			'quiz.suspense.description' => 'Waiting for the answer reveal',
			'quiz.revealed.title' => 'Answer reveal',
			'quiz.revealed.correct' => 'Correct!',
			'quiz.revealed.wrong' => 'Not this time…',
			'quiz.revealed.correctLabel' => 'Correct',
			'quiz.revealed.wrongLabel' => 'Incorrect',
			'quiz.revealed.yourAnswer' => 'Your team\'s answer',
			'quiz.revealed.teamScore' => ({required Object score}) => 'Total: ${score} pts',
			'quiz.revealed.gain' => ({required Object points}) => '+${points} pts',
			'quiz.result.title' => 'Final results',
			'quiz.result.table' => ({required Object name}) => 'Team ${name}',
			'quiz.result.points' => ({required Object score}) => '${score} pts',
			'quiz.result.yourTeam' => 'Your team',
			'quiz.result.rank' => ({required Object rank}) => '#${rank}',
			'quiz.result.ranking' => 'Ranking',
			'quiz.result.tieNote' => 'If teams are tied, how winners are decided will be announced at the venue.',
			'quiz.result.award.title' => 'Sponsor Award',
			'quiz.result.award.perfect' => ({required Object sponsor}) => 'All ${sponsor} questions correct',
			'quiz.result.award.voucher' => 'Event staff will hand you a prize voucher.',
			'quiz.result.award.voucherHint' => 'Please wait for instructions from the staff.',
			'quiz.result.error' => 'Failed to load results',
			'forceUpdate.title' => 'Update Required',
			'forceUpdate.message' => 'A new version of the app is available. Please update to the latest version.',
			'forceUpdate.updateButton' => 'Update',
			'pushNotification.open' => 'Open',
			_ => null,
		};
	}
}
