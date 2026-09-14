# 会場マップのFlutter Scene調査

## 採用構成

Flutter **3.47.3 / Dart 3.13.3**とFlutter Scene **0.23.0**を使用します。アプリの既存の3D切り替え先を散歩UIにし、会場マップの領域内でモデルを操作します。実装と通常アプリでの起動手順は [会場さんぽ](venue-walk.md) を参照してください。

ネイティブはFlutter GPU / Impeller、WebはFlutter Scene内蔵WebGL2を使います。モデルと両テーマの床画像は `hook/build.dart` で事前変換します。[Flutter Scene 0.23の設定](https://github.com/bdero/flutter_scene/blob/flutter_scene-0.23.0/README.md)

## SDKを戻す案の検証

Flutter 3.41.7でScene 0.17.0、0.16.0、0.14.2を確認しました。依存解決やWebコンパイルの成功だけでは描画の互換性を判断できません。

- 0.17.0は旧SDKにないGPU APIを参照し、ネイティブ側のコンパイルに失敗しました。
- 0.16.0と0.14.2は旧APIに合わせるとネイティブのテストとWebビルドは通りますが、Webのシーンが白くなりました。
- 赤い立方体だけでも再現しました。シェーダーに渡す露出値が0のままで、生成バンドルのuniformの `vecSize` / `columns` が0であることを確認しました。
- Flutter 3.41.7と3.44系のshader bundle schemaはこの型情報を持ちません。Flutter SceneのWeb対応は0.14からで、それ以前への単純な変更ではWebの要件を満たせません。

型情報を追加する変更は [Flutter #185879](https://github.com/flutter/flutter/pull/185879) にあります。今回、独自のエンジン改変やパッケージのコピーは採用しません。

## websiteのCI互換性

旧Jaspr 0.22.4の静的サイト生成で、Linux上の `TaskChain._then` → `_LinkedHashSetMixin.add` が `NoSuchMethodError: &(0)` を発生させ、ビルドが終了しない問題を確認しました。

Jasprの [修正PR #867](https://github.com/schultek/jaspr/pull/867) に同一のスタックとLinux x64のDart VM不具合が報告されています。Jaspr **0.23.4**はコールバック保存にListを使ってこの経路を避け、初期描画失敗時に無期限に待つ問題も修正します。`jaspr` / `jaspr_builder` / `jaspr_cli` を0.23.4系、互換ルーターを0.8.3系へ更新します。[変更履歴](https://pub.dev/packages/jaspr/changelog)

少量のfixtureでは旧版でも成功するため、その結果をCI成功の代わりにはしません。PRのwebsite workflowでSTGデータを使った生成・プレビューまで確認します。SDK更新の影響確認はappだけでなく、data・website・dashboardの解析とテスト、Webビルドを対象にします。

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

## 実装

- GLBのアニメーションと会場内の位置更新を分け、親Nodeで移動と旋回を管理します。
- スティックは描画中のカメラを基準に計算します。モデルの正面やカメラの補間前の角度に依存させません。
- 2Dと同じ会場データを使い、壁・ブース・装飾を避ける経路を求めます。
- 場所検索は会場マップの既存UIを共有します。切り替え時は位置を保持し、明示的な検索結果選択で移動します。
- SceneViewはマップ領域の中に配置し、非表示中は連続描画を停止します。
- テーマ変更は同じシーンの床テクスチャとマテリアルを更新し、モデルや歩行状態を再作成しません。

iOS / Android実機でのフレームレート、発熱、長時間のメモリー使用は未計測です。Webでの検証とネイティブ実機の検証は区別します。
