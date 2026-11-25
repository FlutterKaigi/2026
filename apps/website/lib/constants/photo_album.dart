import 'event_info.dart';

// 公式写真アルバムの告知（トップの写真ゾーン `PhotoAlbumHero`）に載せるデータ層。
// UI のラベルは `strings.dart` 側に置く。

/// 公式写真アルバムの公開 URL。
///
/// アルバムの公開前は空のままにしておく。このリポジトリも PR プレビューも一般公開なので、
/// 公開前の共有 URL をソースに書かない。空のあいだ `PhotoAlbumHero` は「近日公開」の
/// 無効ボタンを出す。
///
/// 公開日の作業:
/// - 下の `defaultValue` に公開用アルバムの URL を入れる、または
/// - デプロイ / プレビューのビルドに `--dart-define=PHOTO_ALBUM_URL=...` を渡す。
const photoAlbumUrl = String.fromEnvironment('PHOTO_ALBUM_URL', defaultValue: '');

/// 散らして並べる写真 1 枚。
///
/// 写真の下に文字（キャプション）は出さず、見た目は写真だけ。何の写真かは読み上げ用の
/// [alt] と、[albumPhotos] の各エントリのコメントで表す。
class AlbumPhoto {
  const AlbumPhoto({
    required this.alt,
    this.asset,
    this.objectPosition = 'center',
  });

  /// 画像の代替テキスト（読み上げ用）。写っているものを短く説明する。
  final LocalizedText alt;

  /// 画像の URL。写真は R2 の公開バケットから配信する（[albumPhotos] を参照）ので絶対 URL を
  /// 入れる。サイトの baseHref からの相対パスも受け付ける。
  /// null のあいだはブランドカラーのグラデーションのプレースホルダーを出す。
  ///
  /// 元写真は 3:2。幅 960px 前後の webp（1 枚 30〜60KB 前後）にそろえる。表示枠は
  /// 3:2〜縦長まで変わるので、CSS の `object-fit: cover` で切り抜く。
  /// 読み込めないとき（R2 から消したときなど）は、その写真だけを取り除いて
  /// グラデーションのタイルに戻す。
  final String? asset;

  /// `object-position`。枠に合わせて切り抜くとき、顔や被写体が外れないように
  /// 調整する（例: `'50% 30%'`）。
  final String objectPosition;
}

/// 背景に敷く、ぼかした写真の「ドアップ」の指定。
class AlbumBackground {
  const AlbumBackground({this.asset, this.focus = '50% 40%', this.zoom = 1.6, this.blur = 18});

  /// 背景用の画像（[AlbumPhoto.asset] と同じく URL）。null のときは 1 枚目の写真
  /// ([albumPhotos] の先頭) を流用する（ダウンロードも配信も 1 回で済む）。どちらも無ければ
  /// ブランドグラデーション。
  /// 配信されるファイル自体はぼかされない（鮮明）ので、顔が判別できないよう 640px 前後まで
  /// 小さくする。
  final String? asset;

  /// 拡大の中心（`object-position` と `transform-origin` に使う）。
  final String focus;

  /// 拡大率。1.0 で全体、大きいほどドアップ。ぼかしの縁が透けないよう、[blur] に対して
  /// 十分な余白が出る倍率（1.1 以上）にする。
  final double zoom;

  /// ぼかしの強さ（CSS の px）。小さいほど写っている人の輪郭が見える。
  final double blur;
}

/// 散らし配置のスロット数（デスクトップ）。`PhotoAlbumHero` のスロット表と、CSS の
/// `.album-hero__item--1`〜`--N` の N に合わせる。これを超える写真は表示しない。
/// 先頭 5 枚はスマホにも出る（スマホは 5 枚、タブレットは 7 枚まで）。
const photoAlbumMaxPhotos = 10;

/// 写真の置き場（R2 の公開バケット `2026-public-production` の `album/`）。
///
/// 写真はリポジトリに入れず、`public-buckets/album-photos/` のツールで変換してアップロードする。
/// Git の履歴は消せないが R2 のファイルは消せるので、撮影チームから掲載の取り下げを頼まれても
/// 対応できる。ファイル名はここで使っている名前（01〜10 と bg）で固定。
const _albumBase = 'https://2026-bucket.flutterkaigi.jp/album';

/// 背景に敷く、ぼかした全員集合の写真（2 日目）。
///
/// 壁を除いて人の写る下半分だけを切り出し、幅 640px に縮小してある。ぼかしは弱め（7px）で、
/// 人の輪郭がうっすら見える程度。
const albumBackground = AlbumBackground(asset: '$_albumBase/bg.webp', focus: '50% 50%', zoom: 1.15, blur: 7);

/// 散らして並べる写真。**並び順がそのまま優先度**で、1 枚目が主役の大きな写真（背景用の
/// 写真が無ければ背景にも流用）、先頭 5 枚がスマホ（≤640px）に、先頭 7 枚がタブレットにも出る。
/// 並び順を変えるとスマホやタブレットに出る写真が変わる。位置だけを動かしたいときは、
/// `PhotoAlbumHero` のスロット表（画面幅ごとの位置）を入れ替える。
///
/// 写真は R2 の公開バケットから配信する。選び方の決まり（撮影チームの確認、参加者の写り込み、
/// ライセンス）と、変換・アップロード・取り下げの手順は `public-buckets/album-photos/README.md`。
/// `asset` の名前は R2 のファイル名で、同じ名前で上書きすればコードを変えずに差し替えられる
/// （写真の中身が変わるときは `alt` と `objectPosition` も見直す）。
const albumPhotos = <AlbumPhoto>[
  // 01: メッセージボード（寄せ書きでいっぱいの壁）と、両脇のバナー。人は写らない。
  // どの画面幅でも 3:2 の大きな枠。
  AlbumPhoto(
    asset: '$_albumBase/01.webp',
    alt: LocalizedText(
      ja: 'FlutterKaigi 2026 のロゴと来場者の寄せ書きでいっぱいのメッセージボード。両脇にはスポンサーのロゴが並ぶバナーが立っている',
      en: 'The FlutterKaigi 2026 message board filled with signatures and drawings from attendees, with a banner of sponsor logos on each side',
    ),
  ),
  // 02: 開会のあいさつ（オープニングでマイクを手に話す男性）。後ろにスポンサーのロゴの壁。
  AlbumPhoto(
    asset: '$_albumBase/02.webp',
    alt: LocalizedText(
      ja: '開会のあいさつで、マイクを手に話す男性。後ろにはスポンサーのロゴが並ぶ',
      en: 'A man speaking into a microphone at the opening, in front of the wall of sponsor logos',
    ),
    // タブレット・スマホでは縦長（3:4）に切り抜くので、左寄りの人物を枠に残す。
    objectPosition: '10% 50%',
  ),
  // 03: ボードにペンで寄せ書きをしながら、笑顔で話す 2 人。
  AlbumPhoto(
    asset: '$_albumBase/03.webp',
    alt: LocalizedText(
      ja: 'ボードにペンで寄せ書きをしながら、笑顔で話す女性 2 人',
      en: 'Two women chatting and smiling as one of them writes on the message board with a marker',
    ),
  ),
  // 04: スライドの前でマイクを持って話す登壇者の横顔。どの画面幅でも 3:2 のまま、切り抜かずに使う。
  AlbumPhoto(
    asset: '$_albumBase/04.webp',
    alt: LocalizedText(
      ja: 'マイクを手に、スライドの前で話す登壇者',
      en: 'A speaker talking into a microphone in front of a projected slide',
    ),
  ),
  // 05: ステージに並ぶパネルの登壇者 3 人。
  AlbumPhoto(
    asset: '$_albumBase/05.webp',
    alt: LocalizedText(
      ja: 'ステージに並ぶ 3 人の登壇者。真ん中の女性がマイクを手に笑顔で話している',
      en: 'Three speakers on stage, the woman in the middle smiling as she speaks into a microphone',
    ),
    // スマホ・タブレットでは正方形に切り抜くので、3 人の顔を枠に残す。
    objectPosition: '79% 50%',
  ),
  // 06: スティックを掲げて盛り上がる客席のアップ。
  AlbumPhoto(
    asset: '$_albumBase/06.webp',
    alt: LocalizedText(
      ja: 'カラフルなスティックを掲げて、笑顔で盛り上がる客席のみなさん',
      en: 'Smiling audience members waving colorful inflatable sticks',
    ),
  ),
  // 07: ぬいぐるみが並ぶクレーンゲーム。人は写らない。
  AlbumPhoto(
    asset: '$_albumBase/07.webp',
    alt: LocalizedText(
      ja: 'マスコットのぬいぐるみが並ぶクレーンゲーム',
      en: 'A claw machine full of mascot plush toys',
    ),
    // 縦長（3:4）に切り抜くので、アームとぬいぐるみを枠に残す。
    objectPosition: '42% 50%',
  ),
  // 08: かぼちゃの帽子と青いマスコットの帽子をかぶって、ポーズをとる 2 人。
  AlbumPhoto(
    asset: '$_albumBase/08.webp',
    alt: LocalizedText(
      ja: 'かぼちゃの帽子と青いマスコットの帽子をかぶって、ポーズをとる 2 人',
      en: 'Two people posing in a pumpkin hat and a blue mascot hat',
    ),
    // デスクトップでは縦長（3:4）に切り抜くので、2 人を枠に残す。
    objectPosition: '66% 50%',
  ),
  // 09: 会場に置かれた大きなマスコットのエアバルーン。人は写らない。
  AlbumPhoto(
    asset: '$_albumBase/09.webp',
    alt: LocalizedText(
      ja: '会場に置かれた、大きなマスコットのエアバルーンと FlutterKaigi 2026 のバナー',
      en: 'The giant inflatable mascot beside a FlutterKaigi 2026 banner',
    ),
    // デスクトップだけに出る正方形（1:1）の小さな枠なので、マスコットを枠に残す（右のバナーは半分切れる）。
    objectPosition: '33% 50%',
  ),
  // 10: 会場の全員がグラスを掲げる乾杯。
  AlbumPhoto(
    asset: '$_albumBase/10.webp',
    alt: LocalizedText(
      ja: '会場いっぱいの来場者が、乾杯の音頭に合わせてグラスを掲げている',
      en: 'Attendees across the hall raising their glasses as a man leads the toast',
    ),
    // デスクトップでは縦長（3:4）に切り抜くので、右端の人物を枠に残す。
    objectPosition: '100% 50%',
  ),
];
