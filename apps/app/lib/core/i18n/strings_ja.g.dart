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
	late final Translations$quiz$ja quiz = Translations$quiz$ja.internal(_root);
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

// Path: quiz
class Translations$quiz$ja {
	Translations$quiz$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'クイズ大会'
	String get title => 'クイズ大会';

	/// ja: 'スポンサー提供のクイズに参加'
	String get entrySubtitle => 'スポンサー提供のクイズに参加';

	late final Translations$quiz$list$ja list = Translations$quiz$list$ja.internal(_root);
	late final Translations$quiz$errors$ja errors = Translations$quiz$errors$ja.internal(_root);
	late final Translations$quiz$preparing$ja preparing = Translations$quiz$preparing$ja.internal(_root);
	late final Translations$quiz$registration$ja registration = Translations$quiz$registration$ja.internal(_root);
	late final Translations$quiz$waiting$ja waiting = Translations$quiz$waiting$ja.internal(_root);
	late final Translations$quiz$team$ja team = Translations$quiz$team$ja.internal(_root);
	late final Translations$quiz$entryClosed$ja entryClosed = Translations$quiz$entryClosed$ja.internal(_root);
	late final Translations$quiz$question$ja question = Translations$quiz$question$ja.internal(_root);
	late final Translations$quiz$suspense$ja suspense = Translations$quiz$suspense$ja.internal(_root);
	late final Translations$quiz$revealed$ja revealed = Translations$quiz$revealed$ja.internal(_root);
	late final Translations$quiz$result$ja result = Translations$quiz$result$ja.internal(_root);
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

// Path: quiz.list
class Translations$quiz$list$ja {
	Translations$quiz$list$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'クイズはまだありません'
	String get empty => 'クイズはまだありません';

	/// ja: 'クイズ一覧を取得できませんでした'
	String get error => 'クイズ一覧を取得できませんでした';

	late final Translations$quiz$list$status$ja status = Translations$quiz$list$status$ja.internal(_root);
}

// Path: quiz.errors
class Translations$quiz$errors$ja {
	Translations$quiz$errors$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'サインインに失敗しました'
	String get signInFailed => 'サインインに失敗しました';

	/// ja: 'イベント情報の取得に失敗しました'
	String get eventLoadFailed => 'イベント情報の取得に失敗しました';
}

// Path: quiz.preparing
class Translations$quiz$preparing$ja {
	Translations$quiz$preparing$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'クイズは開催準備中です'
	String get title => 'クイズは開催準備中です';

	/// ja: '開始のアナウンスがあったら この画面から参加できます。'
	String get description => '開始のアナウンスがあったら この画面から参加できます。';
}

// Path: quiz.registration
class Translations$quiz$registration$ja {
	Translations$quiz$registration$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'テーブル対抗のチーム戦。ニックネームで参加しよう！'
	String get subtitle => 'テーブル対抗のチーム戦。ニックネームで参加しよう！';

	/// ja: '現在の参加人数'
	String get participantCount => '現在の参加人数';

	/// ja: '人'
	String get participantUnit => '人';

	/// ja: 'ニックネーム'
	String get nickname => 'ニックネーム';

	/// ja: '1〜20文字'
	String get nicknameHint => '1〜20文字';

	/// ja: '受付コード'
	String get entryCode => '受付コード';

	/// ja: '6桁の数字'
	String get entryCodeHint => '6桁の数字';

	/// ja: '会場の受付で案内しているコードを入力してください'
	String get entryCodeHelper => '会場の受付で案内しているコードを入力してください';

	/// ja: '参加する'
	String get join => '参加する';

	/// ja: '定員（$max 人）に達しました'
	String full({required Object max}) => '定員（${max} 人）に達しました';

	/// ja: '登録できませんでした。時間をおいて再度お試しください。'
	String get failed => '登録できませんでした。時間をおいて再度お試しください。';

	/// ja: '登録できませんでした。受付コードが正しいか確認してください。'
	String get codeMismatch => '登録できませんでした。受付コードが正しいか確認してください。';
}

// Path: quiz.waiting
class Translations$quiz$waiting$ja {
	Translations$quiz$waiting$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '登録完了！'
	String get title => '登録完了！';

	/// ja: 'チーム発表までしばらくお待ちください'
	String get description => 'チーム発表までしばらくお待ちください';
}

// Path: quiz.team
class Translations$quiz$team$ja {
	Translations$quiz$team$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'あなたのテーブルは'
	String get yourTable => 'あなたのテーブルは';

	/// ja: 'テーブル'
	String get table => 'テーブル';

	/// ja: 'チーム'
	String get teamLabel => 'チーム';

	/// ja: 'テーブルに集まって次の出題を待とう！'
	String get gatherHint => 'テーブルに集まって次の出題を待とう！';

	/// ja: 'テーブル $table・$name'
	String badge({required Object table, required Object name}) => 'テーブル ${table}・${name}';
}

// Path: quiz.entryClosed
class Translations$quiz$entryClosed$ja {
	Translations$quiz$entryClosed$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '参加受付は終了しました'
	String get title => '参加受付は終了しました';

	/// ja: 'クイズ大会は進行中です。 結果発表はこの画面でご覧いただけます。'
	String get description => 'クイズ大会は進行中です。 結果発表はこの画面でご覧いただけます。';
}

// Path: quiz.question
class Translations$quiz$question$ja {
	Translations$quiz$question$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '提供: $name'
	String sponsoredBy({required Object name}) => '提供: ${name}';

	/// ja: '秒'
	String get secondsUnit => '秒';

	/// ja: '回答を締め切りました'
	String get locked => '回答を締め切りました';

	/// ja: '送信できませんでした。締め切られた可能性があります。'
	String get submitFailed => '送信できませんでした。締め切られた可能性があります。';

	/// ja: '$name が選択'
	String answeredBy({required Object name}) => '${name} が選択';

	/// ja: 'メンバー'
	String get member => 'メンバー';
}

// Path: quiz.suspense
class Translations$quiz$suspense$ja {
	Translations$quiz$suspense$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '回答締切！'
	String get title => '回答締切！';

	/// ja: '正解発表をお待ちください'
	String get description => '正解発表をお待ちください';
}

// Path: quiz.revealed
class Translations$quiz$revealed$ja {
	Translations$quiz$revealed$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '正解発表'
	String get title => '正解発表';

	/// ja: '正解！'
	String get correct => '正解！';

	/// ja: '残念…'
	String get wrong => '残念…';

	/// ja: 'あなたのチームの回答'
	String get yourAnswer => 'あなたのチームの回答';

	/// ja: '現在のチームスコア: $score 点'
	String teamScore({required Object score}) => '現在のチームスコア: ${score} 点';
}

// Path: quiz.result
class Translations$quiz$result$ja {
	Translations$quiz$result$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '最終結果'
	String get title => '最終結果';

	/// ja: 'テーブル $table'
	String table({required Object table}) => 'テーブル ${table}';

	/// ja: '$score 点'
	String points({required Object score}) => '${score} 点';

	/// ja: 'あなたのチーム'
	String get yourTeam => 'あなたのチーム';

	/// ja: '$rank 位 / $name（$score 点）'
	String yourTeamRanked({required Object rank, required Object name, required Object score}) => '${rank} 位 / ${name}（${score} 点）';

	/// ja: '$name（$score 点）'
	String yourTeamUnranked({required Object name, required Object score}) => '${name}（${score} 点）';

	/// ja: '$sponsor のブースへ景品を受け取りに行こう！'
	String perfect({required Object sponsor}) => '${sponsor} のブースへ景品を受け取りに行こう！';

	/// ja: '結果の取得に失敗しました'
	String get error => '結果の取得に失敗しました';
}

// Path: quiz.list.status
class Translations$quiz$list$status$ja {
	Translations$quiz$list$status$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '開催準備中'
	String get preparing => '開催準備中';

	/// ja: '参加受付中'
	String get registration => '参加受付中';

	/// ja: '受付終了'
	String get entryClosed => '受付終了';

	/// ja: '進行中'
	String get inProgress => '進行中';

	/// ja: '結果発表'
	String get finished => '結果発表';
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
			'notFound.title' => 'ページが見つかりません',
			'notFound.description' => 'お探しのページは存在しないか、移動した可能性があります。',
			'common.retry' => '再試行',
			'quiz.title' => 'クイズ大会',
			'quiz.entrySubtitle' => 'スポンサー提供のクイズに参加',
			'quiz.list.empty' => 'クイズはまだありません',
			'quiz.list.error' => 'クイズ一覧を取得できませんでした',
			'quiz.list.status.preparing' => '開催準備中',
			'quiz.list.status.registration' => '参加受付中',
			'quiz.list.status.entryClosed' => '受付終了',
			'quiz.list.status.inProgress' => '進行中',
			'quiz.list.status.finished' => '結果発表',
			'quiz.errors.signInFailed' => 'サインインに失敗しました',
			'quiz.errors.eventLoadFailed' => 'イベント情報の取得に失敗しました',
			'quiz.preparing.title' => 'クイズは開催準備中です',
			'quiz.preparing.description' => '開始のアナウンスがあったら この画面から参加できます。',
			'quiz.registration.subtitle' => 'テーブル対抗のチーム戦。ニックネームで参加しよう！',
			'quiz.registration.participantCount' => '現在の参加人数',
			'quiz.registration.participantUnit' => '人',
			'quiz.registration.nickname' => 'ニックネーム',
			'quiz.registration.nicknameHint' => '1〜20文字',
			'quiz.registration.entryCode' => '受付コード',
			'quiz.registration.entryCodeHint' => '6桁の数字',
			'quiz.registration.entryCodeHelper' => '会場の受付で案内しているコードを入力してください',
			'quiz.registration.join' => '参加する',
			'quiz.registration.full' => ({required Object max}) => '定員（${max} 人）に達しました',
			'quiz.registration.failed' => '登録できませんでした。時間をおいて再度お試しください。',
			'quiz.registration.codeMismatch' => '登録できませんでした。受付コードが正しいか確認してください。',
			'quiz.waiting.title' => '登録完了！',
			'quiz.waiting.description' => 'チーム発表までしばらくお待ちください',
			'quiz.team.yourTable' => 'あなたのテーブルは',
			'quiz.team.table' => 'テーブル',
			'quiz.team.teamLabel' => 'チーム',
			'quiz.team.gatherHint' => 'テーブルに集まって次の出題を待とう！',
			'quiz.team.badge' => ({required Object table, required Object name}) => 'テーブル ${table}・${name}',
			'quiz.entryClosed.title' => '参加受付は終了しました',
			'quiz.entryClosed.description' => 'クイズ大会は進行中です。 結果発表はこの画面でご覧いただけます。',
			'quiz.question.sponsoredBy' => ({required Object name}) => '提供: ${name}',
			'quiz.question.secondsUnit' => '秒',
			'quiz.question.locked' => '回答を締め切りました',
			'quiz.question.submitFailed' => '送信できませんでした。締め切られた可能性があります。',
			'quiz.question.answeredBy' => ({required Object name}) => '${name} が選択',
			'quiz.question.member' => 'メンバー',
			'quiz.suspense.title' => '回答締切！',
			'quiz.suspense.description' => '正解発表をお待ちください',
			'quiz.revealed.title' => '正解発表',
			'quiz.revealed.correct' => '正解！',
			'quiz.revealed.wrong' => '残念…',
			'quiz.revealed.yourAnswer' => 'あなたのチームの回答',
			'quiz.revealed.teamScore' => ({required Object score}) => '現在のチームスコア: ${score} 点',
			'quiz.result.title' => '最終結果',
			'quiz.result.table' => ({required Object table}) => 'テーブル ${table}',
			'quiz.result.points' => ({required Object score}) => '${score} 点',
			'quiz.result.yourTeam' => 'あなたのチーム',
			'quiz.result.yourTeamRanked' => ({required Object rank, required Object name, required Object score}) => '${rank} 位 / ${name}（${score} 点）',
			'quiz.result.yourTeamUnranked' => ({required Object name, required Object score}) => '${name}（${score} 点）',
			'quiz.result.perfect' => ({required Object sponsor}) => '${sponsor} のブースへ景品を受け取りに行こう！',
			'quiz.result.error' => '結果の取得に失敗しました',
			_ => null,
		};
	}
}
