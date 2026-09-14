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
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

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
	@override late final _Translations$auth$en auth = _Translations$auth$en._(_root);
	@override late final _Translations$profile$en profile = _Translations$profile$en._(_root);
	@override late final _Translations$snsPost$en snsPost = _Translations$snsPost$en._(_root);
	@override late final _Translations$mission$en mission = _Translations$mission$en._(_root);
	@override late final _Translations$exchange$en exchange = _Translations$exchange$en._(_root);
	@override late final _Translations$supportLt$en supportLt = _Translations$supportLt$en._(_root);
	@override late final _Translations$countryRegion$en countryRegion = _Translations$countryRegion$en._(_root);
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
	@override String get other => 'Other';
	@override String get officialWebsite => 'Official Website';
	@override String get codeOfConduct => 'Code of Conduct';
	@override String get privacyPolicy => 'Privacy Policy';
	@override String get exclusionPolicy => 'Exclusion of Anti-Social Forces';
	@override String get contact => 'Contact';
	@override String get sourceCode => 'View Source Code';
	@override String get staffMembers => 'Staff';
	@override String get ossLicenses => 'OSS Licenses';
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
	@override String progress({required Object n}) => '${n} of 3 missions complete';
	@override String get ltTitle => 'Join Support LT';
	@override String get ltDescription => 'Supporters and speakers register with the code at the venue';
	@override String get exchangeTitle => 'Exchange profiles';
	@override String get exchangeDescription => 'Meet at least 3 people, including someone from a different country or region';
	@override String exchangeCount({required Object n}) => '${n} / 3 people met';
	@override String get differentCountry => 'Met someone from a different country or region';
	@override String get profileRequired => 'Add your country or region to your profile';
	@override String get snsTitle => 'Share a photo on SNS';
	@override String get snsDescription => 'Post a photo with an eligible attendee and register its URL and category';
	@override String get presentationHint => 'Show this screen to the staff\nwhen joining the final event.';
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
	@override String get signInAction => 'Sign in';
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
}

// Path: supportLt
class _Translations$supportLt$en extends Translations$supportLt$ja {
	_Translations$supportLt$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Support LT Registration';
	@override String get description => 'Enter the 6-digit code provided by the organizers to register your participation in Support LT';
	@override String get codeLabel => 'Registration code';
	@override String get register => 'Register participation';
	@override String get submitting => 'Registering…';
	@override String get registeredTitle => 'Registration complete';
	@override String get registeredBody => 'Enjoy Support LT';
	@override String get registeredStatus => 'Registered';
	@override String get backToAccount => 'Back to account';
	@override String get signInRequired => 'Sign in to register your participation in Support LT';
	@override String get invalidFormat => 'Enter a 6-digit code';
	@override String get invalidCode => 'This code is incorrect. Check the code provided by the organizers';
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

// Path: auth.signIn
class _Translations$auth$signIn$en extends Translations$auth$signIn$ja {
	_Translations$auth$signIn$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get required => 'Sign in required';
	@override String get description => 'Choose how you want to sign in to the FlutterKaigi 2026 app';
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
	@override String get signOutError => 'Could not sign out';
	@override String get noEmail => 'No email address';
	@override String get delete => 'Delete account';
	@override String get deleteConfirmTitle => 'Delete your account?';
	@override String get deleteConfirmBody => 'Your account will be permanently deleted and cannot be restored. Re-authentication is required before deletion.';
	@override String get deleteConfirmAction => 'Delete';
	@override String get deletePasswordTitle => 'Confirm your password';
	@override String get deletePasswordBody => 'Enter your current password to delete your account.';
	@override String get mission => 'Missions';
	@override String get missionDescription => 'Judged by your participation in Support LT, profile exchange and SNS posts';
	@override String get joinEvent => 'Join the event';
	@override String get quiz => 'Quiz';
	@override String get lightningTalks => 'Join Support LT';
	@override String get profileExchange => 'Profile exchange';
	@override String get snsPost => 'Register SNS post';
	@override String get comingSoon => 'This feature is coming soon';
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
			'eventInfo.other' => 'Other',
			'eventInfo.officialWebsite' => 'Official Website',
			'eventInfo.codeOfConduct' => 'Code of Conduct',
			'eventInfo.privacyPolicy' => 'Privacy Policy',
			'eventInfo.exclusionPolicy' => 'Exclusion of Anti-Social Forces',
			'eventInfo.contact' => 'Contact',
			'eventInfo.sourceCode' => 'View Source Code',
			'eventInfo.staffMembers' => 'Staff',
			'eventInfo.ossLicenses' => 'OSS Licenses',
			'auth.signIn.required' => 'Sign in required',
			'auth.signIn.description' => 'Choose how you want to sign in to the FlutterKaigi 2026 app',
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
			'auth.account.signOutError' => 'Could not sign out',
			'auth.account.noEmail' => 'No email address',
			'auth.account.delete' => 'Delete account',
			'auth.account.deleteConfirmTitle' => 'Delete your account?',
			'auth.account.deleteConfirmBody' => 'Your account will be permanently deleted and cannot be restored. Re-authentication is required before deletion.',
			'auth.account.deleteConfirmAction' => 'Delete',
			'auth.account.deletePasswordTitle' => 'Confirm your password',
			'auth.account.deletePasswordBody' => 'Enter your current password to delete your account.',
			'auth.account.mission' => 'Missions',
			'auth.account.missionDescription' => 'Judged by your participation in Support LT, profile exchange and SNS posts',
			'auth.account.joinEvent' => 'Join the event',
			'auth.account.quiz' => 'Quiz',
			'auth.account.lightningTalks' => 'Join Support LT',
			'auth.account.profileExchange' => 'Profile exchange',
			'auth.account.snsPost' => 'Register SNS post',
			'auth.account.comingSoon' => 'This feature is coming soon',
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
			'mission.progress' => ({required Object n}) => '${n} of 3 missions complete',
			'mission.ltTitle' => 'Join Support LT',
			'mission.ltDescription' => 'Supporters and speakers register with the code at the venue',
			'mission.exchangeTitle' => 'Exchange profiles',
			'mission.exchangeDescription' => 'Meet at least 3 people, including someone from a different country or region',
			'mission.exchangeCount' => ({required Object n}) => '${n} / 3 people met',
			'mission.differentCountry' => 'Met someone from a different country or region',
			'mission.profileRequired' => 'Add your country or region to your profile',
			'mission.snsTitle' => 'Share a photo on SNS',
			'mission.snsDescription' => 'Post a photo with an eligible attendee and register its URL and category',
			'mission.presentationHint' => 'Show this screen to the staff\nwhen joining the final event.',
			'exchange.title' => 'Profile Exchange',
			'exchange.qrDescription' => 'Show this QR code to another attendee and have them scan it to exchange profiles',
			'exchange.qrSemanticLabel' => 'Profile exchange QR code',
			'exchange.qrExpiresAt' => ({required Object date}) => 'Valid until ${date}',
			'exchange.scanButton' => 'Scan a QR code',
			'exchange.listButton' => 'View exchanged profiles',
			'exchange.signInRequired' => 'Sign in to show your QR code',
			'exchange.signInAction' => 'Sign in',
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
			'supportLt.title' => 'Support LT Registration',
			'supportLt.description' => 'Enter the 6-digit code provided by the organizers to register your participation in Support LT',
			'supportLt.codeLabel' => 'Registration code',
			'supportLt.register' => 'Register participation',
			'supportLt.submitting' => 'Registering…',
			'supportLt.registeredTitle' => 'Registration complete',
			'supportLt.registeredBody' => 'Enjoy Support LT',
			'supportLt.registeredStatus' => 'Registered',
			'supportLt.backToAccount' => 'Back to account',
			'supportLt.signInRequired' => 'Sign in to register your participation in Support LT',
			'supportLt.invalidFormat' => 'Enter a 6-digit code',
			'supportLt.invalidCode' => 'This code is incorrect. Check the code provided by the organizers',
			'supportLt.rateLimited' => 'Too many attempts. Please try again in a few minutes',
			'supportLt.networkError' => 'A network error occurred. Check your connection and try again',
			'supportLt.sessionExpired' => 'Your sign-in session has expired. Please sign in again',
			'supportLt.permissionDenied' => 'Registration is not permitted. Please ask the organizers',
			'supportLt.registrationFailed' => 'Could not register your participation. Please try again',
			'countryRegion.asia' => 'Asia',
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
			_ => null,
		};
	}
}
