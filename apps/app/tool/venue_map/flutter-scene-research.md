# 会場マップでだしゅまるを歩かせるための Flutter Scene 調査

調査日: 2026-09-14。公開済みの `flutter_scene 0.23.0` と、指定されたモデルの実データを確認した。

## 結論

**Flutter Scene で実現できる。Web も対応しているため、in-app browser で操作するデモを作れる。** Flutter GPU 自体は Web 用ではないが、Flutter Scene は Web では同梱の WebGL2 バックエンドを使う。CanvasKit / Skwasm の両方が対象で、Web に Flutter GPU の有効化フラグは不要。[Flutter Scene 0.23.0 README](https://github.com/bdero/flutter_scene/blob/flutter_scene-0.23.0/README.md)

調査開始時の固定 SDK は Flutter 3.41.7 / Dart 3.11.5。最新公開版 `flutter_scene 0.23.0` の Flutter 下限は **3.47.0** なので、0.23.0 の導入には SDK 更新が必要。旧版 0.17.0 は 3.41.7 で Web ビルドが通ることまで追加検証したが、後述の API・アセット処理の差がある。今回の実装方針は、ユーザーの SDK 更新意向を受けて **Flutter 3.47.0 + Scene 0.23.0 を本体へ導入し、依存解決・解析・テストで影響を確認する**ものとする。本体の会場マップに「さんぽ」を追加し、Firebase 初期化なしの操作確認用入口を `apps/app/tool/venue_map/walk_preview.dart` に用意した。[0.23.0 pubspec](https://github.com/bdero/flutter_scene/blob/flutter_scene-0.23.0/packages/flutter_scene/pubspec.yaml)

## バージョンと実行環境

調査時の pub.dev 最新公開版は **0.23.0（2026-08-25 公開）**。GitHub の `master` は公開後の開発も含むため、以下の API・制約は可能な限り公開タグで照合した。[pub.dev](https://pub.dev/packages/flutter_scene)、[公開タグ](https://github.com/bdero/flutter_scene/tree/flutter_scene-0.23.0)

| Flutter Scene  | Web                                      | Flutter / Dart の条件                                            | 判断                                                                                  |
| -------------- | ---------------------------------------- | ---------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| 0.13 以前      | 現行の WebGL2 バックエンド導入前         | 版による                                                         | 今回の対象外                                                                          |
| 0.14.0〜0.17.0 | WebGL2 対応。0.17 の README では preview | 0.17 の宣言は Flutter `>=3.29.0-1.0.pre.242` / Dart `^3.10.0`    | 0.17 は 3.41.7 で依存解決・最小 Web ビルド成功。3D 描画互換性は未確認。今回採用しない |
| 0.18〜0.20     | WebGL2 対応                              | Flutter 下限 3.44。0.18 の説明では当時の新しい master API も必要 | SDK の宣言だけでは実動作を判断できない                                                |
| 0.21〜0.23     | WebGL2 対応                              | Flutter `>=3.47.0`。0.23 の Dart 宣言は `^3.10.0`                | 今回の検証対象は 0.23.0                                                               |

Web 対応は 0.14.0 で追加された。0.17 は新しい native/data assets 機能への依存から master 推奨だった。0.18 と 0.21 で SDK 要件が明確化されている。[0.14 の変更履歴](https://github.com/bdero/flutter_scene/blob/flutter_scene-0.14.0/packages/flutter_scene/CHANGELOG.md)、[0.17 README](https://github.com/bdero/flutter_scene/blob/flutter_scene-0.17.0/README.md)、[0.17 pubspec](https://github.com/bdero/flutter_scene/blob/flutter_scene-0.17.0/packages/flutter_scene/pubspec.yaml)、[0.18 の変更履歴](https://github.com/bdero/flutter_scene/blob/flutter_scene-0.18.0/packages/flutter_scene/CHANGELOG.md)、[0.21 の変更履歴](https://github.com/bdero/flutter_scene/blob/flutter_scene-0.21.0/packages/flutter_scene/CHANGELOG.md)

| 実行先                | 描画経路と設定                                                                                  |
| --------------------- | ----------------------------------------------------------------------------------------------- |
| Web / in-app browser  | Flutter Scene 内蔵 WebGL2。追加フラグなし                                                       |
| iOS / Android / macOS | Flutter GPU → Impeller。開発時は `--enable-flutter-gpu`、配布時は各プラットフォーム設定で有効化 |
| Windows / Linux       | Flutter GPU → Impeller。配布用の runner 設定を利用するには Flutter 3.47.1 が必要                |

ネイティブ設定は iOS / macOS の `FLTEnableFlutterGPU`、Android の `io.flutter.embedding.android.EnableFlutterGPU`。Web デモは 3.47.0 で SDK 要件を満たすが、それをもって各ネイティブ端末での性能や配布可否まで検証したことにはならない。[0.23.0 のプラットフォーム設定](https://github.com/bdero/flutter_scene/blob/flutter_scene-0.23.0/README.md#enable-flutter-gpu)

### Flutter 3.41.7 を維持する場合の実測

本体を変更せず `/tmp/flutter_scene_017_compat` に最小アプリを作り、SDK の絶対パスを指定して確認した。`flutter pub get` は成功し、Scene 0.17.0 / flutter_gpu_shaders 0.5.2 / Dart 3.11.5 が解決された。`dart run flutter_scene:init` 自体も成功するが、生成される hook は `dataAssetsRequired` を指定するため、最初の Web ビルドは DataAssets 非対応エラーになる。

hook の `SceneAssetMode` と `MaterialAssetMode` を `legacyOnly` に変更すると、cube + `SceneView` の **`flutter build web --release` と `--debug` は両方成功**した。ただし Chrome で Flutter の画面は開いたものの 3D cube の表示は確認できなかったため、描画の実動作まで成功したとは判断しない。指定 GLB の読み込み検証も、この旧版では未実施。

0.17 へ戻す場合は、少なくとも以下の差に対応する必要がある。

- `Node.position` / `rotation` / `scale` の代わりに `localTransform` を代入する。
- `Camera.screenPointToRay` / `worldToScreen` がない。`getViewTransform(Size)` の逆変換等を実装する。
- アンチエイリアスは `none` / `msaa` のみで、`fxaa` はない。
- `loadTexture` はなく `gpuTextureFromAsset` を使う。`TextureTransform` もない。
- PBR の `roughness` は `roughnessFactor`。`Scene.update` / `SceneView.onTick` / `cameraBuilder` は利用できる。
- `legacyOnly` の事前変換モデルは `build/scenes/...fsceneb` を Flutter assets に登録し、`package:flutter_scene/fscene.dart` の `loadFscenebAsset` で明示的に読み込む。`loadScene` の source path 解決は DataAssets に依存する。

[0.17 build hook](https://github.com/bdero/flutter_scene/blob/flutter_scene-0.17.0/packages/flutter_scene/lib/src/importer/build_hooks.dart)、[0.17 camera](https://github.com/bdero/flutter_scene/blob/flutter_scene-0.17.0/packages/flutter_scene/lib/src/camera.dart)、[0.17 asset helpers](https://github.com/bdero/flutter_scene/blob/flutter_scene-0.17.0/packages/flutter_scene/lib/src/asset_helpers.dart)

### Flutter 3.47.0 へ更新する場合の影響調査

公式の 3.44 / 3.47 の変更点と、本リポジトリ・解決済み依存のソースを照合した。以下の調査では、SDK 更新を直ちに止める必要のある具体的なコンパイル破壊箇所は見つからなかった。最終判断は新 SDK での解析・テスト・ビルド結果による。[公式変更一覧](https://docs.flutter.dev/release/breaking-changes)

| 主な変更                                                                                     | このリポジトリへの影響                                                                                                                   |
| -------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `describeEnum` 削除、`IconData` の継承禁止、`CupertinoPageTransitionsBuilder` の import 移動 | 本体・共有 package と解決済み依存の `lib/` 検索では該当 API 使用なし                                                                     |
| `ListTile` と `Material` の間に不透明な色を描く widget があると debug assert                 | 本体・dashboard に `ListTile` がある。確認した設定・アカウントカードは `Card` で囲んでいる。画面テストで全体を確認する                   |
| Android の built-in Kotlin / AGP 9 対応                                                      | 既存 app は AGP 8.11.1 / Kotlin 2.2.20。Flutter 更新だけで AGP 9 へ同時更新する必要はない                                                |
| OpenGL ES の render-target texture が top-down に統一                                        | 主に独自 GLSL / Flutter GPU の補正が対象。本体に既存の独自 fragment shader 使用は見つからない。新 Scene の床画像の向きは実描画で確認する |
| iOS / Android の `Semantics.header` が no-op、見出しは `headingLevel`                        | 本体に `Semantics(header: true)` の明示利用は見つからない                                                                                |

[describeEnum](https://docs.flutter.dev/release/breaking-changes/remove-describeEnum)、[IconData](https://docs.flutter.dev/release/breaking-changes/icondata-class-marked-final)、[page transitions](https://docs.flutter.dev/release/breaking-changes/decouple-page-transition-builders)、[ListTile](https://docs.flutter.dev/release/breaking-changes/list-tile-color-warning)、[built-in Kotlin](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin)、[OpenGL ES](https://docs.flutter.dev/release/breaking-changes/opengles-render-to-texture-top-down)、[semantics](https://docs.flutter.dev/release/breaking-changes/semantics-header-heading-level)

インストール済みの 3.41.7 / 3.47.0 の Flutter tools ソースでは、`compileSdk=36` / `targetSdk=36` / `minSdk=24` / NDK `28.2.13676358` は同じ。新規プロジェクト用テンプレートの Gradle / AGP / Kotlin は変わっているので、今回の SDK 更新に合わせて既存 Android プロジェクトを再生成する必要はない。[3.41.7 の定数](https://github.com/flutter/flutter/blob/3.41.7/packages/flutter_tools/lib/src/android/gradle_utils.dart)、[3.47.0 の定数](https://github.com/flutter/flutter/blob/3.47.0/packages/flutter_tools/lib/src/android/gradle_utils.dart)

Pub Workspace は app / website / dashboard / data で依存解決を共有するため、app のみの成功では全体の SDK 更新確認にならない。既存の Firebase Web 上限や `path_provider_foundation` override は、今回の Scene 導入と別の変更として不用意に解除せず、既存 package の解析・テストも確認する。

## 指定モデルの調査

取得元を次のコミットに固定して GLB の JSON / BIN チャンクを読み、構成・アニメーションを確認した。

- リポジトリ: `yakitama5/flutter_deck_slides`
- コミット: `de216b458aaef0d0f537a2cfdce76a7d7cf05234`
- ファイル: `slides/20260919_flutterkaigi_mini/assets/models/dashmaru.glb`
- SHA-256: `1efe2af1902f90688466ead1cfaacbf36337582c41bdd0579904ccbaba8b4e8f`

[固定コミットのモデル](https://github.com/yakitama5/flutter_deck_slides/blob/de216b458aaef0d0f537a2cfdce76a7d7cf05234/slides/20260919_flutterkaigi_mini/assets/models/dashmaru.glb)、[モデル manifest](https://github.com/yakitama5/flutter_deck_slides/blob/de216b458aaef0d0f537a2cfdce76a7d7cf05234/slides/20260919_flutterkaigi_mini/assets/models/dashmaru_manifest.json)

| 項目             | 実データ                                                              |
| ---------------- | --------------------------------------------------------------------- |
| 形式・容量       | glTF 2.0 の GLB、9,497,528 bytes（約 9.50 MB）                        |
| 形状             | 89 nodes / 52 meshes / 207,534 triangles                              |
| 骨格             | 1 skin / 28 joints                                                    |
| 材質             | 9 materials、`KHR_materials_specular` 使用                            |
| 画像・テクスチャ | 0。色・輪郭も形状と材質で構成                                         |
| 座標             | GLB は Y-up / 正面 +Z / 高さ 3.04 / 足裏はおおむね Y=0                |
| アニメーション   | 8 clips。それぞれ 89 channels、全 sampler が `LINEAR`                 |
| channel 構成     | translation 29 / rotation 28 / scale 32。morph weights channel はない |

容量・メッシュ数等は manifest と一致。アニメーションの実測時間は下表のとおり。[モデル生成ソース](https://github.com/yakitama5/flutter_deck_slides/blob/de216b458aaef0d0f537a2cfdce76a7d7cf05234/slides/20260919_flutterkaigi_mini/tool/build_dashmaru.py)

| Clip    |    長さ | 会場での利用       |
| ------- | ------: | ------------------ |
| `Idle`  |  4.8 秒 | 停止中             |
| `Walk`  |  1.4 秒 | 通常移動           |
| `Run`   | 0.76 秒 | 走る操作           |
| `Jump`  |  2.4 秒 | 任意のリアクション |
| `Wave`  |  3.2 秒 | 手を振る           |
| `Blink` |  2.2 秒 | まばたき           |
| `Shake` |  2.8 秒 | 身体を振る         |
| `Sit`   |  6.4 秒 | 座って立ち上がる   |

`Walk` / `Run` はその場で繰り返す歩容として使い、会場内の位置更新はアプリが担当する。モデル全体を移動用の親 `Node` で包むと、GLB 内の関節アニメーションと会場の移動・方向転換を分けて扱える。これは GLB のルート構成とアニメーショントラックを踏まえた実装方針。

表情は `FaceNormal` / `FaceSmile` / `FaceSpiral` / `FaceStrain` のサブツリーで構成される。通常以外は GLB 内で scale `0.001` にして隠している。表情切り替えを実装する場合は最初に scale を 1 に戻し、`visible` で排他的に選ぶ。これらの表情グループ自体にはアニメーショントラックがない。[元の表情制御](https://github.com/yakitama5/flutter_deck_slides/blob/de216b458aaef0d0f537a2cfdce76a7d7cf05234/slides/20260919_flutterkaigi_mini/lib/dashmaru_scene.dart#L121)

### 出典・権利

元 README は、このモデルを参考資料から作ったデモ用モデルと説明し、**公式配布の 3D モデルではない**こととキャラクターの権利が元権利者に帰属することを記載している。GLB の copyright も FlutterKaigi のキャラクターを基にした fan model としている。[元 README のモデル説明](https://github.com/yakitama5/flutter_deck_slides/blob/de216b458aaef0d0f537a2cfdce76a7d7cf05234/slides/20260919_flutterkaigi_mini/README.md#モデルと参考資料)

確認したリポジトリにはモデルへ適用される明示的な OSS ライセンスを見つけられなかった。`packages/flutter_deck_patched/LICENSE` は別パッケージの MIT ライセンスであり、この GLB を MIT と扱う根拠にはならない。今回の指定モデルによるローカル検証は進め、公開配布に進める段階でモデル作者・キャラクター権利者の利用条件を確認する。モデルの出典と固定コミットを残す。

## 元スライドは既に Flutter Scene で描画している

元スライドは `flutter_scene: 0.23.0` を固定し、Flutter 3.47.1 / Dart 3.13.1 を使用する構成。Web と macOS の起動方法があり、Web の公開デモも案内されている。指定モデルは Flutter Scene と無関係な形式ではなく、このライブラリで描画するために使われている実例そのものだった。[元 pubspec](https://github.com/yakitama5/flutter_deck_slides/blob/de216b458aaef0d0f537a2cfdce76a7d7cf05234/slides/20260919_flutterkaigi_mini/pubspec.yaml)、[元 README](https://github.com/yakitama5/flutter_deck_slides/blob/de216b458aaef0d0f537a2cfdce76a7d7cf05234/slides/20260919_flutterkaigi_mini/README.md)、[公開デモ](https://yakitama5.github.io/flutter_deck_slides/20260919_flutterkaigi_mini/)

元実装で参考になる点は以下。

- `Scene.initializeStaticResources()` の完了後に `loadScene()` する。
- 全クリップを先に作成し、同じ bind pose を基準にする。
- 切り替え時はクリップの `weight` を 0.3 秒で補間。途中で別の動作に変わっても、現時点の重みからつなぐ。
- フレームの `deltaSeconds` を最大 0.05 秒に制限し、`scene.update(delta)` を 1 回呼ぶ。
- Flutter Scene へのインポートで座標が変換されるため、読み込んだだしゅまるの正面は -Z 側。

[元の scene 制御](https://github.com/yakitama5/flutter_deck_slides/blob/de216b458aaef0d0f537a2cfdce76a7d7cf05234/slides/20260919_flutterkaigi_mini/lib/dashmaru_scene.dart)

## モデル変換と最小 API

古い記事にある `.model` 変換手順は使わない。**`.model` は 0.17.0 で削除済み**。現行は GLB をビルド時に `.fsceneb` へ変換し、元の asset path を渡して `loadScene()` するか、`Node.fromGlbAsset()` で GLB を実行時に直接読み込む。[0.17 の変更履歴](https://github.com/bdero/flutter_scene/blob/flutter_scene-0.17.0/packages/flutter_scene/CHANGELOG.md)、[現行のアセット読み込み](https://fscene.dev/guides/assets-and-loading/)

同梱する会場とキャラクターには事前変換を選ぶ。`dart run flutter_scene:init` が build hook と `flutter_scene_generated/` の asset 宣言を準備する。元スライドの hook は探索範囲を `assets/models/` に限定している。生成物は Flutter engine に依存するため、モデルのソースを保存し、生成物は SDK ごとに再生成する。[元の build hook](https://github.com/yakitama5/flutter_deck_slides/blob/de216b458aaef0d0f537a2cfdce76a7d7cf05234/slides/20260919_flutterkaigi_mini/hook/build.dart)、[0.23 の build hook](https://github.com/bdero/flutter_scene/blob/flutter_scene-0.23.0/packages/flutter_scene/lib/src/importer/build_hooks.dart)

以下は 0.23.0 向けの API の組み合わせ。ウィジェットのライフサイクル、入力、衝突処理、エラー表示は実装側で持つ。

```dart
import 'package:flutter_scene/scene.dart' as scene;
import 'package:vector_math/vector_math.dart' as vm;

final world = scene.Scene();
final actor = scene.Node(name: 'venue-walker');

await scene.Scene.initializeStaticResources();
final model = await scene.loadScene('assets/models/dashmaru.glb');
actor.add(model);
world.add(actor);

final idle = model.createAnimationClip(model.findAnimationByName('Idle')!)
  ..loop = true
  ..weight = 1
  ..play();
final walk = model.createAnimationClip(model.findAnimationByName('Walk')!)
  ..loop = true
  ..weight = 0
  ..play();

// onTick の移動処理で位置・向きと Idle/Walk の重みを更新する。
actor.position = vm.Vector3(x, 0, z);
idle.weight = 1 - walkWeight;
walk.weight = walkWeight;

// build 内では SceneView が描画とフレーム更新を担当する。
scene.SceneView(
  world,
  camera: scene.PerspectiveCamera(
    position: vm.Vector3(0, 12, -16),
    target: vm.Vector3.zero(),
  ),
  onTick: (elapsed, deltaSeconds) {
    // 移動 → 重み更新 → world.update(dt) の順に1回だけ処理する。
  },
);
```

`Node.position` / `rotation` / `scale` は 0.22.0 で追加された API。値を読んで成分だけ書き換えてもノードに反映されないので、新しいベクトル・Quaternion を代入する。[Node の API](https://github.com/bdero/flutter_scene/blob/flutter_scene-0.23.0/packages/flutter_scene/lib/src/node.dart)、[SceneView の API](https://github.com/bdero/flutter_scene/blob/flutter_scene-0.23.0/packages/flutter_scene/lib/src/widgets/scene_view.dart)、[クリップ再生・ブレンド](https://fscene.dev/guides/animation/)

### アニメーションの制約

0.23 の importer は translation / rotation / scale / morph weights を扱うが、GLTF の補間方式を完全に再現するものではない。CUBICSPLINE は接線を捨ててキーフレーム値を使用し、STEP の扱いにも制約がある。今回の GLB は全て LINEAR なので、この制約による非互換は見つからない。[0.23 animation importer](https://github.com/bdero/flutter_scene/blob/flutter_scene-0.23.0/packages/flutter_scene/lib/src/runtime_importer/animation_builder.dart)

描画エンジンがクリップを毎フレーム進めるため、独自 ticker と `SceneView` の両方で重複して時間を進めない。移動と表情まで同じ時刻で評価したい場合は、元スライドと同じく `onTick` で `world.update(dt)` を一度だけ明示する。`AnimationClip.seek()` は再生状態を変えない。[AnimationClip](https://github.com/bdero/flutter_scene/blob/flutter_scene-0.23.0/packages/flutter_scene/lib/src/animation/animation_clip.dart)、[SceneView](https://github.com/bdero/flutter_scene/blob/flutter_scene-0.23.0/packages/flutter_scene/lib/src/widgets/scene_view.dart)

## 会場アプリへの実装方針

現在の会場 3D 表示は Three.js を埋め込んだ HTML を、Web では iframe / `HtmlElementView`、ネイティブでは `WebViewWidget` で開く構成。Flutter Scene に移す場合は、キャラクターだけを重ねると床・壁と深度を共有できないため、会場とキャラクターを同じ Scene に置くのが自然。本体の `VenueMap3DController` / 選択結果の契約と、会場 JSON は再利用できる。

今回の本体の歩行画面では次を実装する。

1. 既存 `floor_plan.json` と床画像を取り込み、元の会場配置に対応する床・壁・歩行範囲を作る。
2. だしゅまるを独立した親ノードに配置し、キーボード・画面内入力・目的地点指定で移動させる。
3. 入力方向の長さを正規化して斜め移動の加速を防ぎ、経過時間に比例して動かす。
4. 壁や進入不可領域を避け、実際の移動速度に応じて Idle / Walk / Run を切り替える。歩容の再生だけで位置が進むとは扱わない。
5. 追従視点と俯瞰視点を用意し、ブラウザ上で経路・向き・止まり方を確認する。

会場の床は 2D なので、最初から汎用物理エンジンを入れる必要はない。歩行可能な領域と障害物に対する円形の当たり判定、目的地移動には床上の経路探索を使う方針とする。これは今回の要件からの設計判断であり、Flutter Scene の制約ではない。

## 採用判断と検証範囲

Flutter Scene は **SDK を更新して操作デモ・本体への統合を進める対象として採用できる**。0.23 も pre-1.0 で minor 更新に破壊的変更があり、Flutter GPU も API 安定性を保証していないため、SDK と Scene の版を固定する。[Flutter Scene の要件](https://github.com/bdero/flutter_scene/blob/flutter_scene-0.23.0/README.md#requirements)、[Flutter GPU の状態](https://github.com/flutter/flutter/blob/main/docs/engine/impeller/Flutter-GPU.md)

本体への統合を判断する際に、特に確認する項目は次の通り。

- 約 9.50 MB・20.8 万三角形のモデルについて、初回ロード時間・メモリ・対象スマートフォンのフレーム時間を測る。必要に応じて軽量版を用意する。
- 会場の検索、スポット選択、テーマ変更、2D への切り替えを保つ。
- WebGL2 の初期化失敗、バックグラウンド復帰、連続移動、狭い画面の操作を確認する。
- iOS / Android でスキニング・影・色・電池消費を確認する。ブラウザでの確認をネイティブ検証の代用にしない。

一次資料・公開パッケージのソース確認、GLB バイナリの解析、旧 3.41.7 + 0.17.0 の最小 Web ビルド、および SDK 更新の既知変更との照合を行った。その後、Flutter 3.47.0 + `flutter_scene 0.23.0` を本体に導入し、会場内の歩行を in-app browser で確認した。ワークスペース全体の解析、app / data / dashboard / website のテスト、website と会場マップの Web ビルド結果・残るネイティブ検証の制限は [実装・検証記録](venue-walk.md) に記載している。
