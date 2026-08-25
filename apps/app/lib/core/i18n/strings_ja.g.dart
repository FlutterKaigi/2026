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
	late final Translations$links$ja links = Translations$links$ja.internal(_root);
	late final Translations$navigation$ja navigation = Translations$navigation$ja.internal(_root);
	late final Translations$news$ja news = Translations$news$ja.internal(_root);
	late final Translations$sponsors$ja sponsors = Translations$sponsors$ja.internal(_root);
	late final Translations$trademarks$ja trademarks = Translations$trademarks$ja.internal(_root);
	late final Translations$sessionTimetable$ja sessionTimetable = Translations$sessionTimetable$ja.internal(_root);
	late final Translations$sessionSearch$ja sessionSearch = Translations$sessionSearch$ja.internal(_root);
	late final Translations$sessionDetails$ja sessionDetails = Translations$sessionDetails$ja.internal(_root);
	late final Translations$sessionBookmark$ja sessionBookmark = Translations$sessionBookmark$ja.internal(_root);
	late final Translations$bookmarkedSessions$ja bookmarkedSessions = Translations$bookmarkedSessions$ja.internal(_root);
	late final Translations$eventInfo$ja eventInfo = Translations$eventInfo$ja.internal(_root);
	late final Translations$auth$ja auth = Translations$auth$ja.internal(_root);
	late final Translations$profile$ja profile = Translations$profile$ja.internal(_root);
	late final Translations$countryRegion$ja countryRegion = Translations$countryRegion$ja.internal(_root);
	late final Translations$settings$ja settings = Translations$settings$ja.internal(_root);
	late final Translations$licenses$ja licenses = Translations$licenses$ja.internal(_root);
	late final Translations$error$ja error = Translations$error$ja.internal(_root);
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

// Path: links
class Translations$links$ja {
	Translations$links$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'リンクを開けませんでした'
	String get openError => 'リンクを開けませんでした';
}

// Path: navigation
class Translations$navigation$ja {
	Translations$navigation$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'セッション'
	String get sessions => 'セッション';

	/// ja: 'スポンサー'
	String get sponsors => 'スポンサー';

	/// ja: 'イベント'
	String get info => 'イベント';

	/// ja: 'アカウント'
	String get account => 'アカウント';
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
}

// Path: sponsors
class Translations$sponsors$ja {
	Translations$sponsors$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'スポンサー'
	String get title => 'スポンサー';

	/// ja: 'スポンサー詳細'
	String get detailTitle => 'スポンサー詳細';

	/// ja: 'FlutterKaigi 2026 を支えてくださるスポンサーの皆様'
	String get subtitle => 'FlutterKaigi 2026 を支えてくださるスポンサーの皆様';

	/// ja: 'スポンサーはまだ公開されていません'
	String get empty => 'スポンサーはまだ公開されていません';

	/// ja: 'スポンサーが見つかりませんでした'
	String get notFound => 'スポンサーが見つかりませんでした';

	/// ja: '$name のロゴ'
	String logoSemanticLabel({required Object name}) => '${name} のロゴ';

	/// ja: '$name の GitHub を見る'
	String githubCardSemanticLabel({required Object name}) => '${name} の GitHub を見る';

	/// ja: '$name の X を見る'
	String xCardSemanticLabel({required Object name}) => '${name} の X を見る';

	/// ja: '$name のリンクを開く'
	String externalCardSemanticLabel({required Object name}) => '${name} のリンクを開く';

	/// ja: '$tier スポンサー'
	String tierBadge({required Object tier}) => '${tier} スポンサー';

	/// ja: 'Job Boards'
	String get jobBoards => 'Job Boards';

	/// ja: '採用情報'
	String get jobBoardCta => '採用情報';

	/// ja: '採用サイト'
	String get recruitCta => '採用サイト';

	/// ja: 'Connect'
	String get connect => 'Connect';
}

// Path: trademarks
class Translations$trademarks$ja {
	Translations$trademarks$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'Flutter および関連するロゴは Google LLC の商標です。FlutterKaigi は Google LLC の承認または提携を受けておりません。'
	String get flutterAffiliation => 'Flutter および関連するロゴは Google LLC の商標です。FlutterKaigi は Google LLC の承認または提携を受けておりません。';

	/// ja: 'Flutter の名称およびロゴは Google LLC の商標です。'
	String get flutterNameAndLogo => 'Flutter の名称およびロゴは Google LLC の商標です。';

	/// ja: 'RevCommは、株式会社 RevComm の登録商標または商標です。'
	String get revComm => 'RevCommは、株式会社 RevComm の登録商標または商標です。';
}

// Path: sessionTimetable
class Translations$sessionTimetable$ja {
	Translations$sessionTimetable$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'タイムテーブル'
	String get title => 'タイムテーブル';

	/// ja: '$day日目 ($date)'
	String dayButtonLabel({required Object day, required Object date}) => '${day}日目 (${date})';

	late final Translations$sessionTimetable$view$ja view = Translations$sessionTimetable$view$ja.internal(_root);

	/// ja: 'タイムテーブルはまだ公開されていません'
	String get empty => 'タイムテーブルはまだ公開されていません';

	/// ja: 'この日の予定はありません'
	String get emptyFiltered => 'この日の予定はありません';

	late final Translations$sessionTimetable$venue$ja venue = Translations$sessionTimetable$venue$ja.internal(_root);
	late final Translations$sessionTimetable$speaker$ja speaker = Translations$sessionTimetable$speaker$ja.internal(_root);
	late final Translations$sessionTimetable$type$ja type = Translations$sessionTimetable$type$ja.internal(_root);
}

// Path: sessionSearch
class Translations$sessionSearch$ja {
	Translations$sessionSearch$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'セッションを検索'
	String get title => 'セッションを検索';

	/// ja: 'タイトル・概要・登壇者を検索'
	String get hint => 'タイトル・概要・登壇者を検索';

	/// ja: '検索条件をクリア'
	String get clear => '検索条件をクリア';

	/// ja: 'すべての日程'
	String get allDates => 'すべての日程';

	/// ja: 'すべての種類'
	String get allTypes => 'すべての種類';

	/// ja: 'すべての言語'
	String get allLanguages => 'すべての言語';

	/// ja: '日程で絞り込み'
	String get dateFilter => '日程で絞り込み';

	/// ja: '種類で絞り込み'
	String get typeFilter => '種類で絞り込み';

	/// ja: '言語で絞り込み'
	String get languageFilter => '言語で絞り込み';

	/// ja: '日程'
	String get dateChip => '日程';

	/// ja: '種類'
	String get typeChip => '種類';

	/// ja: '言語'
	String get languageChip => '言語';

	/// ja: 'セッションを探す'
	String get promptTitle => 'セッションを探す';

	/// ja: 'キーワードを入力するか、日程・種類・言語を選択してください'
	String get promptBody => 'キーワードを入力するか、日程・種類・言語を選択してください';

	/// ja: 'セッションが見つかりません'
	String get emptyTitle => 'セッションが見つかりません';

	/// ja: 'キーワードや絞り込み条件を変更してみてください'
	String get emptyBody => 'キーワードや絞り込み条件を変更してみてください';

	/// ja: '(one) {$n件のセッション} (other) {$n件のセッション}'
	String resultCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		one: '${n}件のセッション',
		other: '${n}件のセッション',
	);
}

// Path: sessionDetails
class Translations$sessionDetails$ja {
	Translations$sessionDetails$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'セッション詳細'
	String get title => 'セッション詳細';

	/// ja: '概要'
	String get description => '概要';

	/// ja: '日時・会場'
	String get schedule => '日時・会場';

	/// ja: '登壇者'
	String get speakers => '登壇者';

	/// ja: 'リンク'
	String get links => 'リンク';

	/// ja: 'Sessionize'
	String get sessionize => 'Sessionize';

	/// ja: '共有'
	String get share => '共有';

	/// ja: 'セッションが見つかりませんでした'
	String get notFound => 'セッションが見つかりませんでした';
}

// Path: sessionBookmark
class Translations$sessionBookmark$ja {
	Translations$sessionBookmark$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'ブックマークしたセッション'
	String get openBookmarked => 'ブックマークしたセッション';

	/// ja: 'ブックマークに追加'
	String get add => 'ブックマークに追加';

	/// ja: 'ブックマークから削除'
	String get remove => 'ブックマークから削除';

	/// ja: 'ブックマークを更新できませんでした'
	String get updateFailed => 'ブックマークを更新できませんでした';
}

// Path: bookmarkedSessions
class Translations$bookmarkedSessions$ja {
	Translations$bookmarkedSessions$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'ブックマークしたセッション'
	String get title => 'ブックマークしたセッション';

	/// ja: 'ブックマークしたセッションはありません'
	String get emptyTitle => 'ブックマークしたセッションはありません';

	/// ja: '気になるセッションをブックマークすると、ここからすぐに見つけられます'
	String get emptyBody => '気になるセッションをブックマークすると、ここからすぐに見つけられます';

	/// ja: 'タイムテーブルを開く'
	String get openSessions => 'タイムテーブルを開く';
}

// Path: eventInfo
class Translations$eventInfo$ja {
	Translations$eventInfo$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'イベント概要'
	String get title => 'イベント概要';

	/// ja: '最新のお知らせ'
	String get newsTitle => '最新のお知らせ';

	/// ja: 'FlutterKaigi 2026 の最新情報を確認'
	String get newsSubtitle => 'FlutterKaigi 2026 の最新情報を確認';

	/// ja: 'FlutterKaigi 2026 ロゴ'
	String get logoSemanticLabel => 'FlutterKaigi 2026 ロゴ';

	/// ja: '会って、話して、熱くなる。'
	String get tagline => '会って、話して、熱くなる。';

	/// ja: '〜Assemble〜'
	String get themeName => '〜Assemble〜';

	/// ja: '2026年、日本国内で Flutter をメインに扱う技術カンファレンス。Flutter や Dart の知見を共有し、参加者同士がつながる2日間です。'
	String get description => '2026年、日本国内で Flutter をメインに扱う技術カンファレンス。Flutter や Dart の知見を共有し、参加者同士がつながる2日間です。';

	/// ja: '日程'
	String get dateLabel => '日程';

	/// ja: '2026年10月29日(木) – 30日(金)'
	String get date => '2026年10月29日(木) – 30日(金)';

	/// ja: '会場'
	String get venueLabel => '会場';

	/// ja: '浜松町コンベンションホール'
	String get venue => '浜松町コンベンションホール';

	/// ja: '地図を見る'
	String get viewMap => '地図を見る';

	/// ja: 'その他'
	String get other => 'その他';

	/// ja: '公式Webサイト'
	String get officialWebsite => '公式Webサイト';

	/// ja: '行動規範'
	String get codeOfConduct => '行動規範';

	/// ja: 'プライバシーポリシー'
	String get privacyPolicy => 'プライバシーポリシー';

	/// ja: '反社会的勢力排除に関する基本方針'
	String get exclusionPolicy => '反社会的勢力排除に関する基本方針';

	/// ja: 'お問い合わせ'
	String get contact => 'お問い合わせ';

	/// ja: 'ソースコードを見る'
	String get sourceCode => 'ソースコードを見る';

	/// ja: 'OSSライセンス'
	String get ossLicenses => 'OSSライセンス';
}

// Path: auth
class Translations$auth$ja {
	Translations$auth$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$auth$signIn$ja signIn = Translations$auth$signIn$ja.internal(_root);
	late final Translations$auth$email$ja email = Translations$auth$email$ja.internal(_root);
	late final Translations$auth$account$ja account = Translations$auth$account$ja.internal(_root);
	late final Translations$auth$error$ja error = Translations$auth$error$ja.internal(_root);
}

// Path: profile
class Translations$profile$ja {
	Translations$profile$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'プロフィール'
	String get title => 'プロフィール';

	/// ja: 'プロフィールを編集'
	String get editTitle => 'プロフィールを編集';

	/// ja: 'プロフィールを作成'
	String get createTitle => 'プロフィールを作成';

	/// ja: 'プロフィールを登録しましょう'
	String get promptTitle => 'プロフィールを登録しましょう';

	/// ja: '出身国・地域や SNS を登録すると、会場での参加者同士のプロフィール交換に使えます。'
	String get promptBody => '出身国・地域や SNS を登録すると、会場での参加者同士のプロフィール交換に使えます。';

	/// ja: 'プロフィールを作成'
	String get create => 'プロフィールを作成';

	/// ja: 'プロフィールを編集'
	String get edit => 'プロフィールを編集';

	/// ja: '保存'
	String get save => '保存';

	/// ja: 'プロフィールを保存しました'
	String get saved => 'プロフィールを保存しました';

	/// ja: 'プロフィールを保存できませんでした'
	String get saveFailed => 'プロフィールを保存できませんでした';

	/// ja: 'プロフィールはサインインしている他の参加者に公開されます'
	String get visibilityNote => 'プロフィールはサインインしている他の参加者に公開されます';

	/// ja: 'プロフィール画像'
	String get avatarSemanticLabel => 'プロフィール画像';

	/// ja: '表示名'
	String get displayNameLabel => '表示名';

	/// ja: '表示名を入力してください'
	String get displayNameRequired => '表示名を入力してください';

	/// ja: '出身国・地域'
	String get countryLabel => '出身国・地域';

	/// ja: '選択してください'
	String get countryPlaceholder => '選択してください';

	/// ja: '出身国・地域を選択してください'
	String get countryRequired => '出身国・地域を選択してください';

	/// ja: '国名・地域名で検索'
	String get countrySearchHint => '国名・地域名で検索';

	/// ja: '「$query」に一致する国・地域が見つかりません'
	String countryNoResults({required Object query}) => '「${query}」に一致する国・地域が見つかりません';

	/// ja: '英語名やISOコードでも検索できます'
	String get countryNoResultsHint => '英語名やISOコードでも検索できます';

	/// ja: 'SNS'
	String get snsLinksLabel => 'SNS';

	/// ja: 'X や GitHub などのリンクを追加できます'
	String get snsLinksEmpty => 'X や GitHub などのリンクを追加できます';

	/// ja: 'SNSリンクを追加'
	String get addSnsLink => 'SNSリンクを追加';

	/// ja: 'このリンクを削除'
	String get removeSnsLink => 'このリンクを削除';

	/// ja: 'サービス'
	String get snsPlatformLabel => 'サービス';

	/// ja: 'URL'
	String get snsUrlLabel => 'URL';

	/// ja: 'URL を入力してください'
	String get snsUrlRequired => 'URL を入力してください';

	/// ja: 'https:// から始まる URL を入力してください'
	String get snsUrlInvalid => 'https:// から始まる URL を入力してください';

	/// ja: 'SNSリンクは $n 件まで登録できます'
	String snsLinksMax({required Object n}) => 'SNSリンクは ${n} 件まで登録できます';

	/// ja: 'その他'
	String get snsPlatformOther => 'その他';

	/// ja: '自己紹介'
	String get bioLabel => '自己紹介';

	/// ja: '普段の仕事や、今日話したいことなど'
	String get bioHint => '普段の仕事や、今日話したいことなど';

	/// ja: '編集内容を破棄しますか?'
	String get discardTitle => '編集内容を破棄しますか?';

	/// ja: '保存していない変更は失われます。'
	String get discardBody => '保存していない変更は失われます。';

	/// ja: '破棄する'
	String get discardAction => '破棄する';

	/// ja: '編集を続ける'
	String get keepEditing => '編集を続ける';
}

// Path: countryRegion
class Translations$countryRegion$ja {
	Translations$countryRegion$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'アジア'
	String get asia => 'アジア';

	/// ja: 'オセアニア'
	String get oceania => 'オセアニア';

	/// ja: '北米・中南米'
	String get americas => '北米・中南米';

	/// ja: 'ヨーロッパ'
	String get europe => 'ヨーロッパ';

	/// ja: 'アフリカ'
	String get africa => 'アフリカ';
}

// Path: settings
class Translations$settings$ja {
	Translations$settings$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '設定'
	String get title => '設定';

	/// ja: '表示設定'
	String get appearance => '表示設定';

	/// ja: 'アプリ情報'
	String get appInfo => 'アプリ情報';

	/// ja: 'バージョン'
	String get version => 'バージョン';

	/// ja: '設定を保存できませんでした'
	String get saveError => '設定を保存できませんでした';

	late final Translations$settings$themeMode$ja themeMode = Translations$settings$themeMode$ja.internal(_root);
	late final Translations$settings$language$ja language = Translations$settings$language$ja.internal(_root);
}

// Path: licenses
class Translations$licenses$ja {
	Translations$licenses$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'ライセンス'
	String get title => 'ライセンス';

	/// ja: 'パッケージを検索'
	String get searchHint => 'パッケージを検索';

	/// ja: '検索をクリア'
	String get clearSearch => '検索をクリア';

	/// ja: '(one) {ライセンス: $n件} (other) {ライセンス: $n件}'
	String licenseCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		one: 'ライセンス: ${n}件',
		other: 'ライセンス: ${n}件',
	);

	/// ja: 'ライセンスが見つかりませんでした'
	String get notFound => 'ライセンスが見つかりませんでした';
}

// Path: error
class Translations$error$ja {
	Translations$error$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'データを読み込めませんでした'
	String get title => 'データを読み込めませんでした';

	/// ja: '通信状況を確認して、もう一度お試しください。'
	String get message => '通信状況を確認して、もう一度お試しください。';

	/// ja: 'この情報を表示する権限がありません。FlutterKaigi スタッフへお問い合わせください。'
	String get permissionDenied => 'この情報を表示する権限がありません。FlutterKaigi スタッフへお問い合わせください。';

	/// ja: '通信状況を確認して、しばらくしてからもう一度お試しください。'
	String get unavailable => '通信状況を確認して、しばらくしてからもう一度お試しください。';

	/// ja: '読み込みに時間がかかっています。もう一度お試しください。'
	String get timeout => '読み込みに時間がかかっています。もう一度お試しください。';

	/// ja: '再試行'
	String get retry => '再試行';

	/// ja: '困った表情のダシュマル'
	String get imageSemanticLabel => '困った表情のダシュマル';
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
	late final Translations$quiz$signInRequired$ja signInRequired = Translations$quiz$signInRequired$ja.internal(_root);
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

// Path: sessionTimetable.view
class Translations$sessionTimetable$view$ja {
	Translations$sessionTimetable$view$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '会場別タイムラインに切り替え'
	String get openRooms => '会場別タイムラインに切り替え';

	/// ja: 'リスト表示に切り替え'
	String get openList => 'リスト表示に切り替え';

	/// ja: '共通'
	String get shared => '共通';
}

// Path: sessionTimetable.venue
class Translations$sessionTimetable$venue$ja {
	Translations$sessionTimetable$venue$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '会場未定'
	String get unknown => '会場未定';
}

// Path: sessionTimetable.speaker
class Translations$sessionTimetable$speaker$ja {
	Translations$sessionTimetable$speaker$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '登壇者未定'
	String get none => '登壇者未定';
}

// Path: sessionTimetable.type
class Translations$sessionTimetable$type$ja {
	Translations$sessionTimetable$type$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'セッション'
	String get regular => 'セッション';

	/// ja: 'LT'
	String get lightningTalk => 'LT';

	/// ja: '初心者向けLT'
	String get beginnersLightningTalk => '初心者向けLT';

	/// ja: 'イベント'
	String get event => 'イベント';
}

// Path: auth.signIn
class Translations$auth$signIn$ja {
	Translations$auth$signIn$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'サインインが必要です'
	String get required => 'サインインが必要です';

	/// ja: 'FlutterKaigi 2026 アプリで利用するサインイン方法を選択してください'
	String get description => 'FlutterKaigi 2026 アプリで利用するサインイン方法を選択してください';

	/// ja: 'Google でサインイン'
	String get withGoogle => 'Google でサインイン';

	/// ja: 'Appleでサインイン'
	String get withApple => 'Appleでサインイン';

	/// ja: 'メールアドレスでサインイン'
	String get withEmail => 'メールアドレスでサインイン';
}

// Path: auth.email
class Translations$auth$email$ja {
	Translations$auth$email$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'メールアドレスでサインイン'
	String get title => 'メールアドレスでサインイン';

	/// ja: 'メールアドレス'
	String get emailLabel => 'メールアドレス';

	/// ja: 'パスワード'
	String get passwordLabel => 'パスワード';

	/// ja: 'メールアドレスを入力してください'
	String get emailRequired => 'メールアドレスを入力してください';

	/// ja: 'パスワードを入力してください'
	String get passwordRequired => 'パスワードを入力してください';

	/// ja: 'パスワードを表示'
	String get showPassword => 'パスワードを表示';

	/// ja: 'パスワードを隠す'
	String get hidePassword => 'パスワードを隠す';

	/// ja: 'サインイン'
	String get signInButton => 'サインイン';

	/// ja: 'アカウントを作成'
	String get createAccountButton => 'アカウントを作成';

	/// ja: 'アカウントを新規作成する'
	String get switchToCreateAccount => 'アカウントを新規作成する';

	/// ja: '既存のアカウントでサインインする'
	String get switchToSignIn => '既存のアカウントでサインインする';

	/// ja: 'パスワードを再設定する'
	String get forgotPassword => 'パスワードを再設定する';

	/// ja: 'パスワード再設定メールを送信しました'
	String get resetEmailSent => 'パスワード再設定メールを送信しました';
}

// Path: auth.account
class Translations$auth$account$ja {
	Translations$auth$account$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'アカウント'
	String get title => 'アカウント';

	/// ja: '参加する'
	String get features => '参加する';

	/// ja: 'サインイン中'
	String get signedIn => 'サインイン中';

	/// ja: 'サインアウト'
	String get signOut => 'サインアウト';

	/// ja: 'サインアウトできませんでした'
	String get signOutError => 'サインアウトできませんでした';

	/// ja: 'メールアドレス未設定'
	String get noEmail => 'メールアドレス未設定';

	/// ja: 'アカウントを削除'
	String get delete => 'アカウントを削除';

	/// ja: 'アカウントを削除しますか?'
	String get deleteConfirmTitle => 'アカウントを削除しますか?';

	/// ja: 'アカウントは完全に削除され、元に戻すことはできません。削除の前に再認証が必要です。'
	String get deleteConfirmBody => 'アカウントは完全に削除され、元に戻すことはできません。削除の前に再認証が必要です。';

	/// ja: '削除する'
	String get deleteConfirmAction => '削除する';

	/// ja: 'パスワードの確認'
	String get deletePasswordTitle => 'パスワードの確認';

	/// ja: 'アカウントを削除するには、現在のパスワードを入力してください。'
	String get deletePasswordBody => 'アカウントを削除するには、現在のパスワードを入力してください。';

	/// ja: 'ミッション'
	String get mission => 'ミッション';

	/// ja: 'LT大会・プロフィール交換・SNS投稿登録の参加状況で判定'
	String get missionDescription => 'LT大会・プロフィール交換・SNS投稿登録の参加状況で判定';

	/// ja: 'イベントに参加'
	String get joinEvent => 'イベントに参加';

	/// ja: 'クイズ大会'
	String get quiz => 'クイズ大会';

	/// ja: 'LT大会'
	String get lightningTalks => 'LT大会';

	/// ja: 'プロフィール交換'
	String get profileExchange => 'プロフィール交換';

	/// ja: 'SNS投稿登録'
	String get snsPost => 'SNS投稿登録';

	/// ja: 'この機能は準備中です'
	String get comingSoon => 'この機能は準備中です';

	/// ja: 'アカウントを削除しました'
	String get deleted => 'アカウントを削除しました';

	/// ja: 'キャンセル'
	String get cancel => 'キャンセル';
}

// Path: auth.error
class Translations$auth$error$ja {
	Translations$auth$error$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'メールアドレスの形式が正しくありません'
	String get invalidEmail => 'メールアドレスの形式が正しくありません';

	/// ja: 'このアカウントは利用できません'
	String get userDisabled => 'このアカウントは利用できません';

	/// ja: 'メールアドレスまたはパスワードが正しくありません'
	String get invalidCredential => 'メールアドレスまたはパスワードが正しくありません';

	/// ja: 'このメールアドレスは既に登録されています'
	String get emailAlreadyInUse => 'このメールアドレスは既に登録されています';

	/// ja: 'パスワードが簡単すぎます。より複雑なパスワードを設定してください'
	String get weakPassword => 'パスワードが簡単すぎます。より複雑なパスワードを設定してください';

	/// ja: '試行回数の上限に達しました。しばらくしてからもう一度お試しください'
	String get tooManyRequests => '試行回数の上限に達しました。しばらくしてからもう一度お試しください';

	/// ja: '通信に失敗しました。通信状況を確認してもう一度お試しください'
	String get network => '通信に失敗しました。通信状況を確認してもう一度お試しください';

	/// ja: '確認のため再認証が必要です。もう一度お試しください'
	String get requiresRecentLogin => '確認のため再認証が必要です。もう一度お試しください';

	/// ja: '再認証したアカウントがサインイン中のアカウントと一致しません'
	String get userMismatch => '再認証したアカウントがサインイン中のアカウントと一致しません';

	/// ja: 'Appleのトークン失効に失敗したため、アカウントを削除できませんでした。もう一度お試しください'
	String get appleTokenRevocationFailed => 'Appleのトークン失効に失敗したため、アカウントを削除できませんでした。もう一度お試しください';

	/// ja: '認証に失敗しました。もう一度お試しください'
	String get unknown => '認証に失敗しました。もう一度お試しください';
}

// Path: settings.themeMode
class Translations$settings$themeMode$ja {
	Translations$settings$themeMode$ja.internal(this._root);

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

// Path: settings.language
class Translations$settings$language$ja {
	Translations$settings$language$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '表示言語'
	String get title => '表示言語';

	/// ja: '日本語'
	String get japanese => '日本語';

	/// ja: 'English'
	String get english => 'English';
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

// Path: quiz.signInRequired
class Translations$quiz$signInRequired$ja {
	Translations$quiz$signInRequired$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'サインインが必要です'
	String get title => 'サインインが必要です';

	/// ja: 'クイズ大会は参加と回答の記録をアカウントに紐づけます。 アカウントタブからサインインしてご参加ください。'
	String get description => 'クイズ大会は参加と回答の記録をアカウントに紐づけます。 アカウントタブからサインインしてご参加ください。';

	/// ja: 'アカウントへ'
	String get button => 'アカウントへ';
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
			'links.openError' => 'リンクを開けませんでした',
			'navigation.sessions' => 'セッション',
			'navigation.sponsors' => 'スポンサー',
			'navigation.info' => 'イベント',
			'navigation.account' => 'アカウント',
			'news.title' => 'お知らせ',
			'news.empty' => 'お知らせはまだありません',
			'sponsors.title' => 'スポンサー',
			'sponsors.detailTitle' => 'スポンサー詳細',
			'sponsors.subtitle' => 'FlutterKaigi 2026 を支えてくださるスポンサーの皆様',
			'sponsors.empty' => 'スポンサーはまだ公開されていません',
			'sponsors.notFound' => 'スポンサーが見つかりませんでした',
			'sponsors.logoSemanticLabel' => ({required Object name}) => '${name} のロゴ',
			'sponsors.githubCardSemanticLabel' => ({required Object name}) => '${name} の GitHub を見る',
			'sponsors.xCardSemanticLabel' => ({required Object name}) => '${name} の X を見る',
			'sponsors.externalCardSemanticLabel' => ({required Object name}) => '${name} のリンクを開く',
			'sponsors.tierBadge' => ({required Object tier}) => '${tier} スポンサー',
			'sponsors.jobBoards' => 'Job Boards',
			'sponsors.jobBoardCta' => '採用情報',
			'sponsors.recruitCta' => '採用サイト',
			'sponsors.connect' => 'Connect',
			'trademarks.flutterAffiliation' => 'Flutter および関連するロゴは Google LLC の商標です。FlutterKaigi は Google LLC の承認または提携を受けておりません。',
			'trademarks.flutterNameAndLogo' => 'Flutter の名称およびロゴは Google LLC の商標です。',
			'trademarks.revComm' => 'RevCommは、株式会社 RevComm の登録商標または商標です。',
			'sessionTimetable.title' => 'タイムテーブル',
			'sessionTimetable.dayButtonLabel' => ({required Object day, required Object date}) => '${day}日目 (${date})',
			'sessionTimetable.view.openRooms' => '会場別タイムラインに切り替え',
			'sessionTimetable.view.openList' => 'リスト表示に切り替え',
			'sessionTimetable.view.shared' => '共通',
			'sessionTimetable.empty' => 'タイムテーブルはまだ公開されていません',
			'sessionTimetable.emptyFiltered' => 'この日の予定はありません',
			'sessionTimetable.venue.unknown' => '会場未定',
			'sessionTimetable.speaker.none' => '登壇者未定',
			'sessionTimetable.type.regular' => 'セッション',
			'sessionTimetable.type.lightningTalk' => 'LT',
			'sessionTimetable.type.beginnersLightningTalk' => '初心者向けLT',
			'sessionTimetable.type.event' => 'イベント',
			'sessionSearch.title' => 'セッションを検索',
			'sessionSearch.hint' => 'タイトル・概要・登壇者を検索',
			'sessionSearch.clear' => '検索条件をクリア',
			'sessionSearch.allDates' => 'すべての日程',
			'sessionSearch.allTypes' => 'すべての種類',
			'sessionSearch.allLanguages' => 'すべての言語',
			'sessionSearch.dateFilter' => '日程で絞り込み',
			'sessionSearch.typeFilter' => '種類で絞り込み',
			'sessionSearch.languageFilter' => '言語で絞り込み',
			'sessionSearch.dateChip' => '日程',
			'sessionSearch.typeChip' => '種類',
			'sessionSearch.languageChip' => '言語',
			'sessionSearch.promptTitle' => 'セッションを探す',
			'sessionSearch.promptBody' => 'キーワードを入力するか、日程・種類・言語を選択してください',
			'sessionSearch.emptyTitle' => 'セッションが見つかりません',
			'sessionSearch.emptyBody' => 'キーワードや絞り込み条件を変更してみてください',
			'sessionSearch.resultCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, one: '${n}件のセッション', other: '${n}件のセッション', ), 
			'sessionDetails.title' => 'セッション詳細',
			'sessionDetails.description' => '概要',
			'sessionDetails.schedule' => '日時・会場',
			'sessionDetails.speakers' => '登壇者',
			'sessionDetails.links' => 'リンク',
			'sessionDetails.sessionize' => 'Sessionize',
			'sessionDetails.share' => '共有',
			'sessionDetails.notFound' => 'セッションが見つかりませんでした',
			'sessionBookmark.openBookmarked' => 'ブックマークしたセッション',
			'sessionBookmark.add' => 'ブックマークに追加',
			'sessionBookmark.remove' => 'ブックマークから削除',
			'sessionBookmark.updateFailed' => 'ブックマークを更新できませんでした',
			'bookmarkedSessions.title' => 'ブックマークしたセッション',
			'bookmarkedSessions.emptyTitle' => 'ブックマークしたセッションはありません',
			'bookmarkedSessions.emptyBody' => '気になるセッションをブックマークすると、ここからすぐに見つけられます',
			'bookmarkedSessions.openSessions' => 'タイムテーブルを開く',
			'eventInfo.title' => 'イベント概要',
			'eventInfo.newsTitle' => '最新のお知らせ',
			'eventInfo.newsSubtitle' => 'FlutterKaigi 2026 の最新情報を確認',
			'eventInfo.logoSemanticLabel' => 'FlutterKaigi 2026 ロゴ',
			'eventInfo.tagline' => '会って、話して、熱くなる。',
			'eventInfo.themeName' => '〜Assemble〜',
			'eventInfo.description' => '2026年、日本国内で Flutter をメインに扱う技術カンファレンス。Flutter や Dart の知見を共有し、参加者同士がつながる2日間です。',
			'eventInfo.dateLabel' => '日程',
			'eventInfo.date' => '2026年10月29日(木) – 30日(金)',
			'eventInfo.venueLabel' => '会場',
			'eventInfo.venue' => '浜松町コンベンションホール',
			'eventInfo.viewMap' => '地図を見る',
			'eventInfo.other' => 'その他',
			'eventInfo.officialWebsite' => '公式Webサイト',
			'eventInfo.codeOfConduct' => '行動規範',
			'eventInfo.privacyPolicy' => 'プライバシーポリシー',
			'eventInfo.exclusionPolicy' => '反社会的勢力排除に関する基本方針',
			'eventInfo.contact' => 'お問い合わせ',
			'eventInfo.sourceCode' => 'ソースコードを見る',
			'eventInfo.ossLicenses' => 'OSSライセンス',
			'auth.signIn.required' => 'サインインが必要です',
			'auth.signIn.description' => 'FlutterKaigi 2026 アプリで利用するサインイン方法を選択してください',
			'auth.signIn.withGoogle' => 'Google でサインイン',
			'auth.signIn.withApple' => 'Appleでサインイン',
			'auth.signIn.withEmail' => 'メールアドレスでサインイン',
			'auth.email.title' => 'メールアドレスでサインイン',
			'auth.email.emailLabel' => 'メールアドレス',
			'auth.email.passwordLabel' => 'パスワード',
			'auth.email.emailRequired' => 'メールアドレスを入力してください',
			'auth.email.passwordRequired' => 'パスワードを入力してください',
			'auth.email.showPassword' => 'パスワードを表示',
			'auth.email.hidePassword' => 'パスワードを隠す',
			'auth.email.signInButton' => 'サインイン',
			'auth.email.createAccountButton' => 'アカウントを作成',
			'auth.email.switchToCreateAccount' => 'アカウントを新規作成する',
			'auth.email.switchToSignIn' => '既存のアカウントでサインインする',
			'auth.email.forgotPassword' => 'パスワードを再設定する',
			'auth.email.resetEmailSent' => 'パスワード再設定メールを送信しました',
			'auth.account.title' => 'アカウント',
			'auth.account.features' => '参加する',
			'auth.account.signedIn' => 'サインイン中',
			'auth.account.signOut' => 'サインアウト',
			'auth.account.signOutError' => 'サインアウトできませんでした',
			'auth.account.noEmail' => 'メールアドレス未設定',
			'auth.account.delete' => 'アカウントを削除',
			'auth.account.deleteConfirmTitle' => 'アカウントを削除しますか?',
			'auth.account.deleteConfirmBody' => 'アカウントは完全に削除され、元に戻すことはできません。削除の前に再認証が必要です。',
			'auth.account.deleteConfirmAction' => '削除する',
			'auth.account.deletePasswordTitle' => 'パスワードの確認',
			'auth.account.deletePasswordBody' => 'アカウントを削除するには、現在のパスワードを入力してください。',
			'auth.account.mission' => 'ミッション',
			'auth.account.missionDescription' => 'LT大会・プロフィール交換・SNS投稿登録の参加状況で判定',
			'auth.account.joinEvent' => 'イベントに参加',
			'auth.account.quiz' => 'クイズ大会',
			'auth.account.lightningTalks' => 'LT大会',
			'auth.account.profileExchange' => 'プロフィール交換',
			'auth.account.snsPost' => 'SNS投稿登録',
			'auth.account.comingSoon' => 'この機能は準備中です',
			'auth.account.deleted' => 'アカウントを削除しました',
			'auth.account.cancel' => 'キャンセル',
			'auth.error.invalidEmail' => 'メールアドレスの形式が正しくありません',
			'auth.error.userDisabled' => 'このアカウントは利用できません',
			'auth.error.invalidCredential' => 'メールアドレスまたはパスワードが正しくありません',
			'auth.error.emailAlreadyInUse' => 'このメールアドレスは既に登録されています',
			'auth.error.weakPassword' => 'パスワードが簡単すぎます。より複雑なパスワードを設定してください',
			'auth.error.tooManyRequests' => '試行回数の上限に達しました。しばらくしてからもう一度お試しください',
			'auth.error.network' => '通信に失敗しました。通信状況を確認してもう一度お試しください',
			'auth.error.requiresRecentLogin' => '確認のため再認証が必要です。もう一度お試しください',
			'auth.error.userMismatch' => '再認証したアカウントがサインイン中のアカウントと一致しません',
			'auth.error.appleTokenRevocationFailed' => 'Appleのトークン失効に失敗したため、アカウントを削除できませんでした。もう一度お試しください',
			'auth.error.unknown' => '認証に失敗しました。もう一度お試しください',
			'profile.title' => 'プロフィール',
			'profile.editTitle' => 'プロフィールを編集',
			'profile.createTitle' => 'プロフィールを作成',
			'profile.promptTitle' => 'プロフィールを登録しましょう',
			'profile.promptBody' => '出身国・地域や SNS を登録すると、会場での参加者同士のプロフィール交換に使えます。',
			'profile.create' => 'プロフィールを作成',
			'profile.edit' => 'プロフィールを編集',
			'profile.save' => '保存',
			'profile.saved' => 'プロフィールを保存しました',
			'profile.saveFailed' => 'プロフィールを保存できませんでした',
			'profile.visibilityNote' => 'プロフィールはサインインしている他の参加者に公開されます',
			'profile.avatarSemanticLabel' => 'プロフィール画像',
			'profile.displayNameLabel' => '表示名',
			'profile.displayNameRequired' => '表示名を入力してください',
			'profile.countryLabel' => '出身国・地域',
			'profile.countryPlaceholder' => '選択してください',
			'profile.countryRequired' => '出身国・地域を選択してください',
			'profile.countrySearchHint' => '国名・地域名で検索',
			'profile.countryNoResults' => ({required Object query}) => '「${query}」に一致する国・地域が見つかりません',
			'profile.countryNoResultsHint' => '英語名やISOコードでも検索できます',
			'profile.snsLinksLabel' => 'SNS',
			'profile.snsLinksEmpty' => 'X や GitHub などのリンクを追加できます',
			'profile.addSnsLink' => 'SNSリンクを追加',
			'profile.removeSnsLink' => 'このリンクを削除',
			'profile.snsPlatformLabel' => 'サービス',
			'profile.snsUrlLabel' => 'URL',
			'profile.snsUrlRequired' => 'URL を入力してください',
			'profile.snsUrlInvalid' => 'https:// から始まる URL を入力してください',
			'profile.snsLinksMax' => ({required Object n}) => 'SNSリンクは ${n} 件まで登録できます',
			'profile.snsPlatformOther' => 'その他',
			'profile.bioLabel' => '自己紹介',
			'profile.bioHint' => '普段の仕事や、今日話したいことなど',
			'profile.discardTitle' => '編集内容を破棄しますか?',
			'profile.discardBody' => '保存していない変更は失われます。',
			'profile.discardAction' => '破棄する',
			'profile.keepEditing' => '編集を続ける',
			'countryRegion.asia' => 'アジア',
			'countryRegion.oceania' => 'オセアニア',
			'countryRegion.americas' => '北米・中南米',
			'countryRegion.europe' => 'ヨーロッパ',
			'countryRegion.africa' => 'アフリカ',
			'settings.title' => '設定',
			'settings.appearance' => '表示設定',
			'settings.appInfo' => 'アプリ情報',
			'settings.version' => 'バージョン',
			'settings.saveError' => '設定を保存できませんでした',
			'settings.themeMode.title' => 'テーマ',
			'settings.themeMode.system' => 'システムに合わせる',
			'settings.themeMode.light' => 'ライト',
			'settings.themeMode.dark' => 'ダーク',
			'settings.language.title' => '表示言語',
			'settings.language.japanese' => '日本語',
			'settings.language.english' => 'English',
			'licenses.title' => 'ライセンス',
			'licenses.searchHint' => 'パッケージを検索',
			'licenses.clearSearch' => '検索をクリア',
			'licenses.licenseCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, one: 'ライセンス: ${n}件', other: 'ライセンス: ${n}件', ), 
			'licenses.notFound' => 'ライセンスが見つかりませんでした',
			'error.title' => 'データを読み込めませんでした',
			'error.message' => '通信状況を確認して、もう一度お試しください。',
			'error.permissionDenied' => 'この情報を表示する権限がありません。FlutterKaigi スタッフへお問い合わせください。',
			'error.unavailable' => '通信状況を確認して、しばらくしてからもう一度お試しください。',
			'error.timeout' => '読み込みに時間がかかっています。もう一度お試しください。',
			'error.retry' => '再試行',
			'error.imageSemanticLabel' => '困った表情のダシュマル',
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
			'quiz.signInRequired.title' => 'サインインが必要です',
			'quiz.signInRequired.description' => 'クイズ大会は参加と回答の記録をアカウントに紐づけます。 アカウントタブからサインインしてご参加ください。',
			'quiz.signInRequired.button' => 'アカウントへ',
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
