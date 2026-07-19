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
	@override late final _Translations$eventInfo$en eventInfo = _Translations$eventInfo$en._(_root);
	@override late final _Translations$notFound$en notFound = _Translations$notFound$en._(_root);
	@override late final _Translations$common$en common = _Translations$common$en._(_root);
	@override late final _Translations$quiz$en quiz = _Translations$quiz$en._(_root);
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

// Path: quiz
class _Translations$quiz$en extends Translations$quiz$ja {
	_Translations$quiz$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Quiz';
	@override String get entrySubtitle => 'Join sponsor-provided quizzes';
	@override late final _Translations$quiz$list$en list = _Translations$quiz$list$en._(_root);
	@override late final _Translations$quiz$errors$en errors = _Translations$quiz$errors$en._(_root);
	@override late final _Translations$quiz$preparing$en preparing = _Translations$quiz$preparing$en._(_root);
	@override late final _Translations$quiz$registration$en registration = _Translations$quiz$registration$en._(_root);
	@override late final _Translations$quiz$waiting$en waiting = _Translations$quiz$waiting$en._(_root);
	@override late final _Translations$quiz$team$en team = _Translations$quiz$team$en._(_root);
	@override late final _Translations$quiz$entryClosed$en entryClosed = _Translations$quiz$entryClosed$en._(_root);
	@override late final _Translations$quiz$question$en question = _Translations$quiz$question$en._(_root);
	@override late final _Translations$quiz$suspense$en suspense = _Translations$quiz$suspense$en._(_root);
	@override late final _Translations$quiz$revealed$en revealed = _Translations$quiz$revealed$en._(_root);
	@override late final _Translations$quiz$result$en result = _Translations$quiz$result$en._(_root);
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

// Path: quiz.list
class _Translations$quiz$list$en extends Translations$quiz$list$ja {
	_Translations$quiz$list$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get empty => 'No quizzes yet';
	@override String get error => 'Failed to load quizzes';
	@override late final _Translations$quiz$list$status$en status = _Translations$quiz$list$status$en._(_root);
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
	@override String get subtitle => 'A table-versus-table team battle. Join with a nickname!';
	@override String get participantCount => 'Participants:';
	@override String get participantUnit => '';
	@override String get nickname => 'Nickname';
	@override String get nicknameHint => '1–20 characters';
	@override String get entryCode => 'Entry code';
	@override String get entryCodeHint => '6-digit number';
	@override String get entryCodeHelper => 'Enter the code shown at the on-site reception desk';
	@override String get join => 'Join';
	@override String full({required Object max}) => 'Full capacity (${max} participants) reached';
	@override String get failed => 'Could not register. Please try again later.';
	@override String get codeMismatch => 'Could not register. Please check the entry code.';
}

// Path: quiz.waiting
class _Translations$quiz$waiting$en extends Translations$quiz$waiting$ja {
	_Translations$quiz$waiting$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'You\'re in!';
	@override String get description => 'Please wait for the team announcement';
}

// Path: quiz.team
class _Translations$quiz$team$en extends Translations$quiz$team$ja {
	_Translations$quiz$team$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get yourTable => 'Your table is';
	@override String get table => 'Table';
	@override String get teamLabel => 'Team';
	@override String get gatherHint => 'Gather at your table and wait for the next question!';
	@override String badge({required Object table, required Object name}) => 'Table ${table}・${name}';
}

// Path: quiz.entryClosed
class _Translations$quiz$entryClosed$en extends Translations$quiz$entryClosed$ja {
	_Translations$quiz$entryClosed$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Entry is closed';
	@override String get description => 'The quiz is in progress. Results will be shown on this screen.';
}

// Path: quiz.question
class _Translations$quiz$question$en extends Translations$quiz$question$ja {
	_Translations$quiz$question$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String sponsoredBy({required Object name}) => 'Sponsored by ${name}';
	@override String get secondsUnit => 's';
	@override String get locked => 'Answers are closed';
	@override String get submitFailed => 'Could not submit. The question may have closed.';
	@override String answeredBy({required Object name}) => 'Selected by ${name}';
	@override String get member => 'a member';
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
	@override String get yourAnswer => 'Your team\'s answer';
	@override String teamScore({required Object score}) => 'Current team score: ${score} pts';
}

// Path: quiz.result
class _Translations$quiz$result$en extends Translations$quiz$result$ja {
	_Translations$quiz$result$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Final results';
	@override String table({required Object table}) => 'Table ${table}';
	@override String points({required Object score}) => '${score} pts';
	@override String get yourTeam => 'Your team';
	@override String yourTeamRanked({required Object rank, required Object name, required Object score}) => '#${rank} / ${name} (${score} pts)';
	@override String yourTeamUnranked({required Object name, required Object score}) => '${name} (${score} pts)';
	@override String perfect({required Object sponsor}) => 'Visit the ${sponsor} booth to claim your prize!';
	@override String get error => 'Failed to load results';
}

// Path: quiz.list.status
class _Translations$quiz$list$status$en extends Translations$quiz$list$status$ja {
	_Translations$quiz$list$status$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get preparing => 'Coming soon';
	@override String get registration => 'Open for entry';
	@override String get entryClosed => 'Entry closed';
	@override String get inProgress => 'In progress';
	@override String get finished => 'Results';
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
			'navigation.info' => 'Event Info',
			'news.title' => 'News',
			'news.empty' => 'There is no news yet',
			'news.error' => 'Failed to load news',
			'eventInfo.title' => 'Event Info',
			'eventInfo.version' => 'Version',
			'eventInfo.themeMode.title' => 'Theme',
			'eventInfo.themeMode.system' => 'System',
			'eventInfo.themeMode.light' => 'Light',
			'eventInfo.themeMode.dark' => 'Dark',
			'notFound.title' => 'Page not found',
			'notFound.description' => 'The page you are looking for does not exist or may have moved.',
			'common.retry' => 'Retry',
			'quiz.title' => 'Quiz',
			'quiz.entrySubtitle' => 'Join sponsor-provided quizzes',
			'quiz.list.empty' => 'No quizzes yet',
			'quiz.list.error' => 'Failed to load quizzes',
			'quiz.list.status.preparing' => 'Coming soon',
			'quiz.list.status.registration' => 'Open for entry',
			'quiz.list.status.entryClosed' => 'Entry closed',
			'quiz.list.status.inProgress' => 'In progress',
			'quiz.list.status.finished' => 'Results',
			'quiz.errors.signInFailed' => 'Failed to sign in',
			'quiz.errors.eventLoadFailed' => 'Failed to load the event',
			'quiz.preparing.title' => 'The quiz is being prepared',
			'quiz.preparing.description' => 'Once it is announced, you can join from this screen.',
			'quiz.registration.subtitle' => 'A table-versus-table team battle. Join with a nickname!',
			'quiz.registration.participantCount' => 'Participants:',
			'quiz.registration.participantUnit' => '',
			'quiz.registration.nickname' => 'Nickname',
			'quiz.registration.nicknameHint' => '1–20 characters',
			'quiz.registration.entryCode' => 'Entry code',
			'quiz.registration.entryCodeHint' => '6-digit number',
			'quiz.registration.entryCodeHelper' => 'Enter the code shown at the on-site reception desk',
			'quiz.registration.join' => 'Join',
			'quiz.registration.full' => ({required Object max}) => 'Full capacity (${max} participants) reached',
			'quiz.registration.failed' => 'Could not register. Please try again later.',
			'quiz.registration.codeMismatch' => 'Could not register. Please check the entry code.',
			'quiz.waiting.title' => 'You\'re in!',
			'quiz.waiting.description' => 'Please wait for the team announcement',
			'quiz.team.yourTable' => 'Your table is',
			'quiz.team.table' => 'Table',
			'quiz.team.teamLabel' => 'Team',
			'quiz.team.gatherHint' => 'Gather at your table and wait for the next question!',
			'quiz.team.badge' => ({required Object table, required Object name}) => 'Table ${table}・${name}',
			'quiz.entryClosed.title' => 'Entry is closed',
			'quiz.entryClosed.description' => 'The quiz is in progress. Results will be shown on this screen.',
			'quiz.question.sponsoredBy' => ({required Object name}) => 'Sponsored by ${name}',
			'quiz.question.secondsUnit' => 's',
			'quiz.question.locked' => 'Answers are closed',
			'quiz.question.submitFailed' => 'Could not submit. The question may have closed.',
			'quiz.question.answeredBy' => ({required Object name}) => 'Selected by ${name}',
			'quiz.question.member' => 'a member',
			'quiz.suspense.title' => 'Time\'s up!',
			'quiz.suspense.description' => 'Waiting for the answer reveal',
			'quiz.revealed.title' => 'Answer reveal',
			'quiz.revealed.correct' => 'Correct!',
			'quiz.revealed.wrong' => 'Not this time…',
			'quiz.revealed.yourAnswer' => 'Your team\'s answer',
			'quiz.revealed.teamScore' => ({required Object score}) => 'Current team score: ${score} pts',
			'quiz.result.title' => 'Final results',
			'quiz.result.table' => ({required Object table}) => 'Table ${table}',
			'quiz.result.points' => ({required Object score}) => '${score} pts',
			'quiz.result.yourTeam' => 'Your team',
			'quiz.result.yourTeamRanked' => ({required Object rank, required Object name, required Object score}) => '#${rank} / ${name} (${score} pts)',
			'quiz.result.yourTeamUnranked' => ({required Object name, required Object score}) => '${name} (${score} pts)',
			'quiz.result.perfect' => ({required Object sponsor}) => 'Visit the ${sponsor} booth to claim your prize!',
			'quiz.result.error' => 'Failed to load results',
			_ => null,
		};
	}
}
