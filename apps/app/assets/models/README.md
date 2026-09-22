# だしゅまるの3Dモデル

`dashmaru.glb` は、ユーザー指定の [yakitama5/flutter_deck_slides](https://github.com/yakitama5/flutter_deck_slides/tree/de216b458aaef0d0f537a2cfdce76a7d7cf05234/slides/20260919_flutterkaigi_mini/assets/models) から取得した未変更のモデルです。

- 取得日: 2026-09-14
- 固定コミット: `de216b458aaef0d0f537a2cfdce76a7d7cf05234`
- 元ファイル: `slides/20260919_flutterkaigi_mini/assets/models/dashmaru.glb`
- サイズ: 9,497,528 bytes
- SHA-256: `1efe2af1902f90688466ead1cfaacbf36337582c41bdd0579904ccbaba8b4e8f`
- モデル作者: yakitama5
- キャラクター: FlutterKaigi「だしゅまる」

元の [README](https://github.com/yakitama5/flutter_deck_slides/blob/de216b458aaef0d0f537a2cfdce76a7d7cf05234/slides/20260919_flutterkaigi_mini/README.md) では、参考資料から作成したデモ用のモデルであり、公式配布の3Dモデルではないと説明されています。GLB の copyright 表記は `Dashmaru character: FlutterKaigi. Reference-based fan model for FlutterKaigi mini.` です。

モデルに適用される明示的な OSS ライセンスは取得元で確認できていません。リポジトリ内の別パッケージの MIT ライセンスを、このモデルのライセンスとして扱わないでください。今回の用途は指定モデルによるローカル検証です。公開配布の前にモデル作者・キャラクター権利者の利用条件を確認してください。

`Idle` / `Walk` / `Run` / `Wave` を会場さんぽで使用し、撮影サンプルでは `Sit` / `Jump` も使用しています。`hook/build.dart` が Flutter Scene の `.fsceneb` に事前変換します。生成物は保存せず、固定 SDK でビルド時に再生成します。
