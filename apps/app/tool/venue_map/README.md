# 会場マップ

アプリの `VenueMapPage` が操作 UI、検索、選択状態を持ちます。Material 3 の部品とアプリの
`ColorScheme` / `TextTheme` を使い、日本語・英語とライト・ダークテーマに対応します。

- 2D は Flutter で描画し、初回起動時の表示方法です。
- 表示方法だけを SharedPreferences に保存します。ページを作り直したときは会場全体を表示します。
- 場所の選択はハイライトと一度のカメラ移動です。その後のパン・ズーム・回転は選択から独立しています。
- 検索の開閉、選択解除、テーマ変更、画面サイズ変更では選択位置へ戻しません。
- 画面内の場所のラベルはすべて表示します。重なる場合は近くへずらし、引き出し線で実際の位置を示します。
  トイレは配置を先に確保します。回転・縮小・選択を理由にラベルを省略しません。
- 設備は2D・3Dで同じMaterialアイコンを使用します。英語ではアイコンに設備名を添えます。
- スマホは下部の検索ボタンと選択カード、大きな画面は検索サイドバーを使います。
- 3D は iOS / Android の WebView と Web の iframe で表示します。非表示中は描画を停止します。
  読み込めない場合は再試行または 2D への切り替えができます。

## 図面と素材

`assets/venue_map/floor_plan.json` は添付された詳細図面（871 × 449）の座標を基準にした共通データです。
ホールの形・名称・設備の位置を更新する際は、このファイルを変更します。
設備の `materialIcon` と `mapLabel` も2D・3D共通です。
`floor_map.png` は確認済みの文字なし画像を使っています。
`artBox` は画像の外壁を図面の座標へ合わせる位置とサイズです。

3D の `scene.js` は同じ JSON と画像を使います。操作は `configure`（テーマ・言語・選択・表示状態）、
`focus`（一度の移動）、`fit`、`zoom` に分かれています。
3D は普通の OrbitControls のパン・ズームで近づきます。選択を追跡する独自の回転処理はありません。

## 3D アセットの再生成

リポジトリルートから実行します。

```sh
python3 apps/app/tool/venue_map/build.py
```

生成先は `assets/html/venue_floor_plan_webview.html` です。Three.js r160 / OrbitControls、画像、図面データ、
アプリで使う Noto Sans JP のラベル用サブセットを埋め込み、ネットワーク接続を必要としません。
Materialアイコンも設定済みのFlutter SDKから必要な字形を取り出して埋め込みます。
Material Iconsのライセンスは生成HTML内に含まれ、アプリではFlutterのライセンス一覧から参照できます。
Three.js は既存のアプリのバンドルから切り出したものです。ライセンスは
`assets/venue_map/THREE_LICENSE.txt`、フォントは既存の `res/assets/fonts/NotoSansJP/OFL.txt` にあります。
フォントのサブセット生成には設定済みの Flutter SDK 内の `font-subset` を使用します。

## 実装画面のプレビュー

Firebase なしで実際のページを起動できます。`apps/app` で実行します。

```sh
fvm flutter run -d web-server -t tool/venue_map/preview.dart --web-port 8766
```

`?theme=dark&locale=en` でダークテーマ・英語を確認できます。この起動ファイルは開発確認用です。

```sh
fvm flutter test test/venue_map_test.dart
node --test tool/venue_map/label-layout.test.cjs
fvm dart analyze
```
