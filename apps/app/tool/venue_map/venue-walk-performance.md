# 会場さんぽの性能・現在地判定の修正

2026-09-15、Flutter 3.47.3 / Dart 3.13.3 / Flutter Scene 0.23.0で確認しました。

## 原因と変更

- 壁・床の厚み・机・看板の枠が個別のGeometry / Material / Nodeを持ち、固定物にも毎フレーム影を描画していました。共通の立方体を材質ごとのInstancedMeshで描き、固定物だけに`shadowStatic`を設定しました。広い範囲のグループでも各インスタンスの可視判定を維持します。
- 看板の文字面と枠が重複して影を落としていたため、文字面の影を省きました。入口でフェードする看板と支柱は引き続き動的な影として扱います。テーマ変更は共有マテリアルの色だけを更新します。
- 移動経路の点を一つのInstancedMeshにまとめ、次の経路ではインスタンスを入れ替えます。経路の点と足元・目的地のリングは影を落としません。
- 移動とA*の衝突判定が毎回全117本の壁と全障害物を走査していました。48ピクセルの区画で近くの障害物に絞り、距離の比較では平方根と一時的なPoint生成を省きました。衝突半径、6ピクセルの経路グリッド、壁抜け防止の小刻みな移動は維持します。
- 検索先への接近地点を探した後に、同じ経路をもう一度計算していました。接近地点までの経路をそのまま使います。装飾を追加するときは衝突用の索引を更新し、経路グリッドのキャッシュを破棄します。
- 現在地はホールだけを調べ、それ以外は`y > 587`でエントランスにしていました。設備を含む`places`のポリゴンを先に調べ、男性用・女性用・多目的トイレや案内所を正しく表示します。ホールの訪問判定は別に維持します。

## Webの描画計測

macOSの同じブラウザー、1280×720の画面、ダークテーマ、開始位置、同じカメラで比較しました。アプリ本体をreleaseで起動し、読み込み・カメラ補間が落ち着いた後の120フレーム単位のログを使います。

| 指標                 |       修正前 |         修正後 |
| -------------------- | -----------: | -------------: |
| ScenePassの平均      | 約5.8〜6.1ms |   約1.5〜1.7ms |
| ShadowPassの平均     | 約7.0〜7.4ms | 約0.35〜0.39ms |
| 上記2パスの合計      |       約13ms |   約1.9〜2.1ms |
| 通常描画のdraw calls |          136 |             76 |
| 通常描画のinstances  |          222 |            222 |

Flutter Sceneのログが示す描画処理のCPU時間です。GPUの完了時間、アプリ全体のフレーム時間、iPhone / Android実機のFPSではありません。モデルの形状やテクスチャの解像度は変更していません。

再計測は`apps/app`から次のように起動し、`/#/venue-map`で3Dを選びます。`FLUTTER_SCENE_PROFILE`は計測時だけ指定します。[Flutter Sceneの計測オプション](https://pub.dev/packages/flutter_scene/versions/0.23.0)

```sh
fvm flutter run --release -d web-server --web-hostname=127.0.0.1 --web-port=8774 \
  --dart-define=FLAVOR=dev --dart-define=FLUTTER_SCENE_PROFILE=true
```

## 経路計算の計測

同じMacでDart AOT実行ファイルを使い、30回の中央値を比較しました。各回で新しいVenueNavigationを作り、開始位置から以下の順に検索します。計測はfloor_plan.jsonの形状が対象で、Flutter描画や装飾の生成は含みません。修正前は実際の呼び出しと同じ`approach`＋`route`、修正後は`routeToPlace`です。

| 行き先       |   修正前 |  修正後 |
| ------------ | -------: | ------: |
| JTCC HALL    | 276.16ms | 18.75ms |
| UPSIDER HALL | 183.19ms | 10.90ms |
| Cupertino    | 265.66ms | 17.99ms |
| Material     | 179.52ms | 10.70ms |
| 男性用トイレ |  56.92ms |  3.62ms |
| 女性用トイレ |  77.73ms |  5.18ms |
| 多目的トイレ |  28.36ms |  1.86ms |

再計測は`apps/app`から実行します。

```sh
fvm dart compile exe tool/venue_map/benchmark_navigation.dart -o /tmp/venue-navigation-benchmark
/tmp/venue-navigation-benchmark assets/venue_map/floor_plan.json
```

## 回帰確認

- トイレ3種類で修正前に`Expected: トイレのID / Actual: entrance`を再現し、修正後に成功。
- 4,872地点（乱数を固定した3,000地点＋各壁の境界付近）で全走査の衝突判定と一致。
- 全ホール・22ブースへの到達、装飾追加後の経路、壁際の移動・壁抜け防止を確認。
- 最新の`main`を取り込んだ状態で、アプリテスト319件（GPU必須の2件は別実行）、データ層テスト67件、JavaScriptのマップラベルテスト8件、アプリ・データ層の`dart analyze`、Dartフォーマット、Web releaseビルドが成功。
- `venue_scene_viewport_test.dart`と`venue_map_test.dart`を`--enable-impeller --enable-flutter-gpu`付きで実行し、3Dの一時停止・再開を含む18件が成功。
- Web実画面でトイレ3種類への到着表示、2D/3D往復、撮影ポーズ・PNGプレビュー・散歩への復帰、ライト/ダークのテーマ切替を確認。

iOS simulatorビルドは既存のSwift Package Manager依存の競合で停止しました。`firebase_auth 6.5.6`はFirebase iOS SDK 12.15.0、`firebase_core 4.13.0`は12.17.0をそれぞれexactで要求しています。会場マップの変更に含めず、iOS / Android実機での性能検証は未実施です。
