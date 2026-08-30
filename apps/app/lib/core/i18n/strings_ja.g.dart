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
	late final Translations$staffMembers$ja staffMembers = Translations$staffMembers$ja.internal(_root);
	late final Translations$trademarks$ja trademarks = Translations$trademarks$ja.internal(_root);
	late final Translations$sessionTimetable$ja sessionTimetable = Translations$sessionTimetable$ja.internal(_root);
	late final Translations$sessionSearch$ja sessionSearch = Translations$sessionSearch$ja.internal(_root);
	late final Translations$sessionDetails$ja sessionDetails = Translations$sessionDetails$ja.internal(_root);
	late final Translations$sessionBookmark$ja sessionBookmark = Translations$sessionBookmark$ja.internal(_root);
	late final Translations$bookmarkedSessions$ja bookmarkedSessions = Translations$bookmarkedSessions$ja.internal(_root);
	late final Translations$eventInfo$ja eventInfo = Translations$eventInfo$ja.internal(_root);
	late final Translations$auth$ja auth = Translations$auth$ja.internal(_root);
	late final Translations$profile$ja profile = Translations$profile$ja.internal(_root);
	late final Translations$exchange$ja exchange = Translations$exchange$ja.internal(_root);
	late final Translations$countryRegion$ja countryRegion = Translations$countryRegion$ja.internal(_root);
	late final Translations$settings$ja settings = Translations$settings$ja.internal(_root);
	late final Translations$licenses$ja licenses = Translations$licenses$ja.internal(_root);
	late final Translations$error$ja error = Translations$error$ja.internal(_root);
	late final Translations$notFound$ja notFound = Translations$notFound$ja.internal(_root);
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

// Path: staffMembers
class Translations$staffMembers$ja {
	Translations$staffMembers$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'スタッフ'
	String get title => 'スタッフ';

	/// ja: 'スタッフはまだ公開されていません'
	String get empty => 'スタッフはまだ公開されていません';

	/// ja: 'スタッフ情報を取得できませんでした'
	String get error => 'スタッフ情報を取得できませんでした';
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

	/// ja: 'セッションのフィードバックを送る'
	String get feedback => 'セッションのフィードバックを送る';

	/// ja: 'このセッションの感想をお聞かせください'
	String get feedbackDescription => 'このセッションの感想をお聞かせください';

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

	/// ja: 'スタッフ'
	String get staffMembers => 'スタッフ';

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

// Path: exchange
class Translations$exchange$ja {
	Translations$exchange$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$exchange$home$ja home = Translations$exchange$home$ja.internal(_root);
	late final Translations$exchange$code$ja code = Translations$exchange$code$ja.internal(_root);
	late final Translations$exchange$scan$ja scan = Translations$exchange$scan$ja.internal(_root);
	late final Translations$exchange$list$ja list = Translations$exchange$list$ja.internal(_root);
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

// Path: exchange.home
class Translations$exchange$home$ja {
	Translations$exchange$home$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'プロフィール交換'
	String get title => 'プロフィール交換';

	/// ja: 'プロフィール交換を利用するにはサインインしてください'
	String get signInRequired => 'プロフィール交換を利用するにはサインインしてください';

	/// ja: 'サインインする'
	String get signInAction => 'サインインする';

	/// ja: 'プロフィールを作成しましょう'
	String get profileRequiredTitle => 'プロフィールを作成しましょう';

	/// ja: 'プロフィール交換を利用するには、先にプロフィールを作成してください'
	String get profileRequiredBody => 'プロフィール交換を利用するには、先にプロフィールを作成してください';

	/// ja: 'プロフィールを作成'
	String get profileRequiredAction => 'プロフィールを作成';

	/// ja: '自分のQRコード'
	String get qrTitle => '自分のQRコード';

	/// ja: '相手にこのQRコードを読み取ってもらうと、プロフィールを交換できます'
	String get qrDescription => '相手にこのQRコードを読み取ってもらうと、プロフィールを交換できます';

	/// ja: '有効期限: $date まで'
	String qrExpiresAt({required Object date}) => '有効期限: ${date} まで';

	/// ja: 'オフラインのため、保存済みのQRコードを表示しています'
	String get qrOffline => 'オフラインのため、保存済みのQRコードを表示しています';

	/// ja: 'QRコードを発行できませんでした'
	String get qrLoadFailed => 'QRコードを発行できませんでした';

	/// ja: 'QRコードを再発行'
	String get refreshQr => 'QRコードを再発行';

	/// ja: 'QRコードを読み取る'
	String get scanAction => 'QRコードを読み取る';

	/// ja: '6桁コードを表示'
	String get showCodeAction => '6桁コードを表示';

	/// ja: '6桁コードを入力'
	String get enterCodeAction => '6桁コードを入力';

	/// ja: '交換した人一覧'
	String get listAction => '交換した人一覧';
}

// Path: exchange.code
class Translations$exchange$code$ja {
	Translations$exchange$code$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '6桁コード'
	String get showTitle => '6桁コード';

	/// ja: 'このコードを相手に伝えてください'
	String get showDescription => 'このコードを相手に伝えてください';

	/// ja: '残り $seconds 秒'
	String expiresIn({required Object seconds}) => '残り ${seconds} 秒';

	/// ja: 'コードの有効期限が切れました'
	String get expired => 'コードの有効期限が切れました';

	/// ja: 'コードを再発行'
	String get reissue => 'コードを再発行';

	/// ja: 'コードを発行できませんでした'
	String get issueFailed => 'コードを発行できませんでした';

	/// ja: '6桁コードを入力'
	String get enterTitle => '6桁コードを入力';

	/// ja: '相手から伝えられたコードを入力してください'
	String get enterDescription => '相手から伝えられたコードを入力してください';

	/// ja: '6桁の数字を入力してください'
	String get enterInvalidFormat => '6桁の数字を入力してください';

	/// ja: '交換する'
	String get submit => '交換する';

	/// ja: 'コードが見つからないか、有効期限が切れています'
	String get notFound => 'コードが見つからないか、有効期限が切れています';

	/// ja: 'コードの有効期限が切れています'
	String get expiredCode => 'コードの有効期限が切れています';

	/// ja: '自分のコードは利用できません'
	String get selfCode => '自分のコードは利用できません';

	/// ja: '試行回数が多すぎます。しばらくしてからお試しください'
	String get rateLimited => '試行回数が多すぎます。しばらくしてからお試しください';

	/// ja: 'コードを確認できませんでした。もう一度お試しください'
	String get genericError => 'コードを確認できませんでした。もう一度お試しください';
}

// Path: exchange.scan
class Translations$exchange$scan$ja {
	Translations$exchange$scan$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: 'QRコードを読み取る'
	String get title => 'QRコードを読み取る';

	/// ja: '相手のQRコードを枠内に写してください'
	String get hint => '相手のQRコードを枠内に写してください';

	/// ja: 'カメラを使用できません'
	String get permissionDeniedTitle => 'カメラを使用できません';

	/// ja: 'カメラの使用を許可すると、QRコードを読み取れます。許可できない場合は6桁コードをご利用ください。'
	String get permissionDeniedBody => 'カメラの使用を許可すると、QRコードを読み取れます。許可できない場合は6桁コードをご利用ください。';

	/// ja: '6桁コードを入力する'
	String get enterCodeInstead => '6桁コードを入力する';

	/// ja: 'プロフィールを交換しました'
	String get success => 'プロフィールを交換しました';

	/// ja: '自分のQRコードです'
	String get selfScan => '自分のQRコードです';

	/// ja: '不正なQRコードです'
	String get malformed => '不正なQRコードです';

	/// ja: '既に交換済みです'
	String get duplicate => '既に交換済みです';

	/// ja: '交換できませんでした。もう一度お試しください'
	String get genericError => '交換できませんでした。もう一度お試しください';
}

// Path: exchange.list
class Translations$exchange$list$ja {
	Translations$exchange$list$ja.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ja: '交換した人一覧'
	String get title => '交換した人一覧';

	/// ja: '(one) {$n 人と交換しました} (other) {$n 人と交換しました}'
	String countLabel({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		one: '${n} 人と交換しました',
		other: '${n} 人と交換しました',
	);

	/// ja: 'まだ誰とも交換していません'
	String get empty => 'まだ誰とも交換していません';

	/// ja: 'QRコードを読み取ると、ここに一覧が表示されます'
	String get emptyBody => 'QRコードを読み取ると、ここに一覧が表示されます';

	/// ja: '削除されたプロフィールです'
	String get deletedProfile => '削除されたプロフィールです';

	/// ja: '一覧から削除'
	String get deleteAction => '一覧から削除';

	/// ja: '一覧から削除しますか?'
	String get deleteConfirmTitle => '一覧から削除しますか?';

	/// ja: '相手の一覧からは削除されません。'
	String get deleteConfirmBody => '相手の一覧からは削除されません。';

	/// ja: '削除する'
	String get deleteConfirmAction => '削除する';

	/// ja: 'キャンセル'
	String get cancel => 'キャンセル';

	/// ja: 'メモ'
	String get noteLabel => 'メモ';

	/// ja: '会話の内容など、自分だけのメモを残せます'
	String get noteHint => '会話の内容など、自分だけのメモを残せます';

	/// ja: '保存'
	String get noteSave => '保存';

	/// ja: 'メモを保存しました'
	String get noteSaved => 'メモを保存しました';

	/// ja: 'メモを保存できませんでした'
	String get noteSaveFailed => 'メモを保存できませんでした';

	/// ja: 'リンクをコピー'
	String get copyLink => 'リンクをコピー';

	/// ja: 'リンクをコピーしました'
	String get linkCopied => 'リンクをコピーしました';

	/// ja: 'リンクを開けませんでした'
	String get openLinkFailed => 'リンクを開けませんでした';

	/// ja: '$date に交換'
	String exchangedAt({required Object date}) => '${date} に交換';
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
			'staffMembers.title' => 'スタッフ',
			'staffMembers.empty' => 'スタッフはまだ公開されていません',
			'staffMembers.error' => 'スタッフ情報を取得できませんでした',
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
			'sessionDetails.feedback' => 'セッションのフィードバックを送る',
			'sessionDetails.feedbackDescription' => 'このセッションの感想をお聞かせください',
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
			'eventInfo.staffMembers' => 'スタッフ',
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
			'exchange.home.title' => 'プロフィール交換',
			'exchange.home.signInRequired' => 'プロフィール交換を利用するにはサインインしてください',
			'exchange.home.signInAction' => 'サインインする',
			'exchange.home.profileRequiredTitle' => 'プロフィールを作成しましょう',
			'exchange.home.profileRequiredBody' => 'プロフィール交換を利用するには、先にプロフィールを作成してください',
			'exchange.home.profileRequiredAction' => 'プロフィールを作成',
			'exchange.home.qrTitle' => '自分のQRコード',
			'exchange.home.qrDescription' => '相手にこのQRコードを読み取ってもらうと、プロフィールを交換できます',
			'exchange.home.qrExpiresAt' => ({required Object date}) => '有効期限: ${date} まで',
			'exchange.home.qrOffline' => 'オフラインのため、保存済みのQRコードを表示しています',
			'exchange.home.qrLoadFailed' => 'QRコードを発行できませんでした',
			'exchange.home.refreshQr' => 'QRコードを再発行',
			'exchange.home.scanAction' => 'QRコードを読み取る',
			'exchange.home.showCodeAction' => '6桁コードを表示',
			'exchange.home.enterCodeAction' => '6桁コードを入力',
			'exchange.home.listAction' => '交換した人一覧',
			'exchange.code.showTitle' => '6桁コード',
			'exchange.code.showDescription' => 'このコードを相手に伝えてください',
			'exchange.code.expiresIn' => ({required Object seconds}) => '残り ${seconds} 秒',
			'exchange.code.expired' => 'コードの有効期限が切れました',
			'exchange.code.reissue' => 'コードを再発行',
			'exchange.code.issueFailed' => 'コードを発行できませんでした',
			'exchange.code.enterTitle' => '6桁コードを入力',
			'exchange.code.enterDescription' => '相手から伝えられたコードを入力してください',
			'exchange.code.enterInvalidFormat' => '6桁の数字を入力してください',
			'exchange.code.submit' => '交換する',
			'exchange.code.notFound' => 'コードが見つからないか、有効期限が切れています',
			'exchange.code.expiredCode' => 'コードの有効期限が切れています',
			'exchange.code.selfCode' => '自分のコードは利用できません',
			'exchange.code.rateLimited' => '試行回数が多すぎます。しばらくしてからお試しください',
			'exchange.code.genericError' => 'コードを確認できませんでした。もう一度お試しください',
			'exchange.scan.title' => 'QRコードを読み取る',
			'exchange.scan.hint' => '相手のQRコードを枠内に写してください',
			'exchange.scan.permissionDeniedTitle' => 'カメラを使用できません',
			'exchange.scan.permissionDeniedBody' => 'カメラの使用を許可すると、QRコードを読み取れます。許可できない場合は6桁コードをご利用ください。',
			'exchange.scan.enterCodeInstead' => '6桁コードを入力する',
			'exchange.scan.success' => 'プロフィールを交換しました',
			'exchange.scan.selfScan' => '自分のQRコードです',
			'exchange.scan.malformed' => '不正なQRコードです',
			'exchange.scan.duplicate' => '既に交換済みです',
			'exchange.scan.genericError' => '交換できませんでした。もう一度お試しください',
			'exchange.list.title' => '交換した人一覧',
			'exchange.list.countLabel' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, one: '${n} 人と交換しました', other: '${n} 人と交換しました', ), 
			'exchange.list.empty' => 'まだ誰とも交換していません',
			'exchange.list.emptyBody' => 'QRコードを読み取ると、ここに一覧が表示されます',
			'exchange.list.deletedProfile' => '削除されたプロフィールです',
			'exchange.list.deleteAction' => '一覧から削除',
			'exchange.list.deleteConfirmTitle' => '一覧から削除しますか?',
			'exchange.list.deleteConfirmBody' => '相手の一覧からは削除されません。',
			'exchange.list.deleteConfirmAction' => '削除する',
			'exchange.list.cancel' => 'キャンセル',
			'exchange.list.noteLabel' => 'メモ',
			'exchange.list.noteHint' => '会話の内容など、自分だけのメモを残せます',
			'exchange.list.noteSave' => '保存',
			'exchange.list.noteSaved' => 'メモを保存しました',
			'exchange.list.noteSaveFailed' => 'メモを保存できませんでした',
			'exchange.list.copyLink' => 'リンクをコピー',
			'exchange.list.linkCopied' => 'リンクをコピーしました',
			'exchange.list.openLinkFailed' => 'リンクを開けませんでした',
			'exchange.list.exchangedAt' => ({required Object date}) => '${date} に交換',
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
			_ => null,
		};
	}
}
