# 会場マップ

アプリの2D・3D表示は、確認済みの会場マップ v17 と同じ形状・配置を使います。
38か所（4ホール、22社のブース、12設備）を共通データに登録しています。

## 表示と操作

- 2D：文字のないフロア画像の上に、Flutterの選択可能なラベルを配置します。パン、ピンチ、拡大・縮小、90度回転、全体表示に対応します。ラベルは回転しても正立します。
- 3D：同じ床面、117本の壁線分、スポンサーの机、4本のエスカレーターをThree.jsで表示します。ホールやトイレの壁は確定済みの線分を立ち上げ、入口を再推定しません。ドラッグ回転、パン、ズーム、90度回転、全体表示に対応します。
- ホール・スポンサー・設備をタップ、または一覧から選択すると、その場所を強調して表示します。選択を解除してもカメラを戻しません。
- 2D・3Dを切り替えると、選択していた場所に移動します。表示方法は保存します。
- スマートフォンは下部の検索シート、大画面は左側の検索一覧を使用します。
- スポンサーは机の位置に番号を表示し、番号と正式名で一覧・選択カードから探せます。ブースは共通色に統一し、ランクによる色分けや表記は掲載しません。検索は名前、整数番号、`#15`、`㉒`にも対応します。
- スポンサー名は `sponsor-names.json` にある公式サイトの日英掲載名を使い、元の略称も検索できます。参照URL・確認日を同ファイルに記録しています。GENDAはイベント一覧に掲載がないため、会社公式サイトの名称を使っています。
- 縮小時はホールと設備を優先し、ブース番号は拡大すると表示します。3Dでは地図の傾きによる圧縮も考慮します。選択したブースの番号は常に表示します。検索一覧には縮尺に関係なく全22社を掲載します。
- Ask the SpeakerはJTCC・UPSIDER・Materialで区別し、対応するホールとの間を選択カードから移動できます。地図・一覧・読み上げでも対象ホールを確認できます。
- 参加者向けの行き先を優先し、ホワイエは地図のラベル・一覧・選択対象に含めません。ホールはイベント名を表示し、施設側の別名は検索用にのみ残します。
- トイレ・出入口などの設備は名称だけを表示し、説明文がない項目には一覧・選択カードとも補足行を設けません。
- 日本語・英語、ライト・ダーク、文字拡大に対応します。ホール・設備の色を保ち、番号の前景色はコントラストを確保します。
- 3DはWebのiframe、iOS・AndroidのWebViewに対応します。非表示・検索シート表示中は描画を停止し、Webではフォーカス対象からも外します。読み込み失敗時は再試行または2Dに切り替えられます。

エレベーターは掲載していません。一般利用外の範囲は共通のグレーで示します。
多目的トイレ、男女トイレの入口、ホールの両開き扉10組、左右2本ずつのエスカレーター、3か所のAsk、2か所のゴミ箱を反映しています。

## 共通データと生成

`build-visitor-map-v17.mjs` が確認済みの作図形状を持ち、`build-app-map.mjs` がそこからアプリ用素材を出力します。
構造に使っているSVGの直線コマンド以外が追加された場合、エクスポーターはエラーで停止します。

生成する素材：

- `assets/venue_map/floor_plan.json`：1774 × 810の共通座標、床領域、壁、入口、机、設備、検索情報。
- `assets/venue_map/floor_map_base.png` / `floor_map_base_dark.png`：ラベルを除いたフロア画像。日本語の焼き込みを避け、各表示がラベルを描画します。
- `assets/venue_map/floor_map_base.svg`：同じフロア画像のベクター原稿。アプリのバンドルには含めません。
- `assets/html/venue_floor_plan_webview.html`：Three.js r160、OrbitControls、共通JSON、両テーマの床面、アプリのNoto Sans JPとMaterial Iconsのサブセットを埋め込んだ3D素材。マップ表示時の外部通信は不要です。

リポジトリルートで次の順序で実行します。Node.jsとSharp、Python 3、設定済みのFlutter SDKが必要です。

```sh
node apps/app/tool/venue_map/build-app-map.mjs
python3 apps/app/tool/venue_map/build.py
```

3Dベンダーコードのライセンスは `assets/venue_map/THREE_LICENSE.txt`、Noto Sans JPは `res/assets/fonts/NotoSansJP/OFL.txt` にあります。Material IconsのライセンスはHTML内にも埋め込みます。

## 確認

`apps/app` ディレクトリからFirebase初期化なしで実際の会場マップページを起動できます。

```sh
fvm flutter run --no-pub -d web-server -t tool/venue_map/preview.dart --web-port 8772
```

`?theme=dark&locale=en` でダークテーマ・英語を確認できます。

```sh
fvm flutter test --no-pub test/venue_map_test.dart
node --test tool/venue_map/label-layout.test.cjs
fvm dart analyze
fvm flutter build web --no-pub --release -t tool/venue_map/preview.dart --output=build/venue-map-preview
```

テストでは配置・番号・ブースの共通色、入口の選択、設備、検索、2D/3Dのデータ一致、カメラ、狭い画面と文字拡大、ラベルの重なり、番号のコントラスト、3Dエラー時の2D復帰を確認します。

2026-09-09のiOSシミュレータービルド確認では、既存のSwift Package依存解決が失敗しました。`cloud_functions` が `firebase-ios-sdk 12.17.0`、`cloud_firestore` が `12.15.0` を要求して衝突しています。Web版の両モードは実画面で確認済みですが、iOS上の実行は未確認です。
