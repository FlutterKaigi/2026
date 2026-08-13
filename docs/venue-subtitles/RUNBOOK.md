# Venue subtitles runbook

このRunbookは正面スクリーン字幕の**技術試作・リハーサル**向けです。本番採用は未承認であり、DroidKaigi後のフォローアップ、実会場試験、理事・運営・会場・制作・収録担当のGo／No-Go合意が必要です。必須ゲートが1つでも未達なら正面スクリーン方式を使わず、準備済みのアプリ字幕へフォールバックします。

## 事前準備

- 合成PCとプロジェクターの実対応解像度を確認（1920×1080は試作候補であり、本番値は機材試験後に固定）
- 登壇者HDMIをキャプチャーするOBS sceneを作成
- `CAPTION ON`: 映像 + Browser Source
- `CAPTION OFF`: 映像のみ
- 合成PCを経由しない物理HDMIバイパスを外部スイッチャーへ用意
- PA／マイク音声をSTT・翻訳プロセスへ別系統で入力
- STT・翻訳producer、用語集、API credential、音声入力を別手順で起動し、実発話からrelayまでE2E確認
- NTP等で合成PCの時刻を同期
- clean／captioned／both／post-productionのどれで収録するか決定
- YouTube字幕（自動／校正済み／なし）と焼き込み字幕の重複方針を、収録方式とは別に決定
- 制作物チームが字幕カード、文字、行間、行数、色、安全領域を承認
- アプリチームが、合成PCと独立したアプリ字幕および来場者案内を本番可能な状態にする

OBS Browser Source:

```text
URL: http://127.0.0.1:8088/?room=<room>&session=<session>&maxLines=1
Width: 1920  # 試作候補。実機で確定した値へ変更
Height: 1080 # 試作候補。実機で確定した値へ変更
Custom CSS: なし
Shutdown source when not visible: OFF
Refresh browser when scene becomes active: OFF
```

## 起動

```bash
cd /path/to/2026
fvm dart pub get
fvm dart run melos venue-screen:build
export VENUE_CAPTION_WRITE_TOKEN="$(openssl rand -hex 32)"
fvm dart run melos caption-relay:serve
```

tokenは承認済みのsecret共有手段で字幕producer担当へ渡し、端末へ表示しません。画面共有、チャット、議事録、shell履歴へ貼らないでください。別ターミナルのfixture試験では同じ値を対話入力します。

別ターミナルで確認します。

```bash
curl --fail http://127.0.0.1:8088/healthz
read -rs 'VENUE_CAPTION_WRITE_TOKEN?relay起動時のtoken: '; export VENUE_CAPTION_WRITE_TOKEN; printf '\n'
fvm dart run melos caption-relay:replay
```

既定値以外の会場・セッションへfixtureを流す場合は、relayのworktree内で次を実行します。

```bash
cd tools/caption_relay
fvm dart run bin/replay_captions.dart \
  --file test/fixtures/rehearsal.json \
  --room '<room>' \
  --session '<session>'
```

認証付きclearは、次のコマンドで送ります。

```bash
curl --fail-with-body -X POST http://127.0.0.1:8088/api/v1/clear \
  -H 'content-type: application/json' \
  -H "authorization: Bearer ${VENUE_CAPTION_WRITE_TOKEN}" \
  --data '{"roomId":"<room>","sessionId":"<session>"}'
```

プレビューを開き、次を確認します。

```text
http://127.0.0.1:8088/?view=preview&room=<room>&session=<session>&maxLines=1
```

- statusが`connected`
- droppedが`0`
- 1行／2行、明暗スライドで読みやすい
- 客席最後列で、合意した可読性基準を満たす
- 日本語／英語／混在文の最長fixtureに末尾省略、文字切れ、意図しない改行がない
- ページ番号、コード、注釈、QRコード等のスライド重要領域と重ならない

STT・翻訳生成側は、字幕を1画面に収まる短い意味単位へ分割して送ります。オーバーレイは省略部分を自動繰り越ししません。オペレーターは長文fixtureで省略記号・不自然な途切れを目視し、本番中もプレビューと生成側のチャンク長を監視します。省略が継続する場合は生成側の送信を止め、`CAPTION OFF`へ切り替えます。

## Go／No-Go前確認

次の欄を[Acceptance checklist](ACCEPTANCE.md)で確定します。

- DroidKaigi後フォローアップ日時: **TBD**
- FlutterKaigi Go／No-Go期限: **TBD**
- 最終決定者／会議体: **TBD**
- 制作デザイン承認者: **TBD**
- アプリ字幕オーナー・準備完了日: **TBD**
- STT・翻訳producerオーナー・準備完了日: **TBD**

機材、表示品質、運用、組織承認、収録、セキュリティ、独立アプリフォールバックのいずれかの必須ゲートが未達ならNo-Goです。正面表示とアプリ字幕の両方が未達の場合は本施策全体をNo-Goとし、翻訳字幕を提供できると来場者へ案内しません。

## セッション切替

1. STT・翻訳送信を止める
2. `/api/v1/clear`を送る
3. OBS Browser Sourceと字幕生成側の`session`を同じ新IDへ変更
4. fixtureを1件送り、他会場・前セッションの字幕が出ないことを確認
5. 登壇開始前に再度clearする

## 本番中の監視

- オペレーターはプレビュー画面で接続状態を監視する
- 観客向けBrowser Sourceには診断情報を表示しない
- 誤訳や古い字幕が残った場合はclearする
- 省略、意図しない改行、重要領域との重なりが続く場合は`CAPTION OFF`にする
- 本文はrelayログへ記録されない。必要な遅延計測は個人情報を除いた集計値で行う
- `/healthz`の`finalCaptionLatencyMs`（count／p50／p95／max、単位ms）を試験終了時に記録する。この値は発話開始からrelay受理までであり、画面描画までの遅延は撮影映像でも確認する
- 遅延測定は専用のrelayを再起動して対象room／sessionだけを流す。集計は全stream横断・直近1,000件のfinal・メモリ内で、relay再起動時にresetされるため、countと試験範囲も併記する
- `CAPTION OFF`時にアプリ字幕へ誘導する担当者・場内案内・QR導線を本番前に確定する

## 障害対応

| 症状                 | 即時対応                                                      | 復旧確認                                                                     |
| -------------------- | ------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| 字幕だけ停止         | `CAPTION OFF`へ切替                                           | previewがconnected、fixture表示後に戻す                                      |
| 古い字幕が残る       | clearを送信。消えなければ`CAPTION OFF`                        | `clearAt`とsession IDを確認                                                  |
| 誤訳が連続           | STT・翻訳送信を停止し`CAPTION OFF`                            | 用語集／入力音声を確認                                                       |
| OBS／Flutter表示異常 | `CAPTION OFF`へ切替                                           | Browser Sourceを再読込しfixture確認                                          |
| 合成PC／OBS停止      | 物理HDMIバイパスへ切替                                        | 登壇者映像が安定するまで字幕を再開しない。場内担当が準備済みアプリ字幕を案内 |
| 会場ネットワーク停止 | 正面表示はlocalhostで継続。翻訳APIも止まる場合は`CAPTION OFF` | API接続回復後にfixture確認                                                   |

映像が一瞬でも不安定な場合は、字幕復旧より素通し映像を優先します。

## ネットワークとtoken

- relayは`127.0.0.1`等のループバックだけで待受し、それ以外へのbindを拒否する
- 字幕投入とclearはループバックでも`VENUE_CAPTION_WRITE_TOKEN`を必須とする
- write tokenはURL、OBS scene collection、ログ、スクリーンショットへ入れない
- WebSocketは読取専用とし、ブラウザーからはrelayと同一originだけを許可する
- `--allow-loopback-development-origin`は`flutter run`でのローカル開発時だけ使い、本番では指定しない
- tokenは試験ごとに新しくし、安全な手段でSTT・翻訳プロセスへ渡し、終了時に破棄する
- STT・翻訳を別PCで動かす場合はrelayをLAN公開せず、認証・暗号化を備えた別transportを設計・承認する

## 終了

1. clearを送る
2. OBSを`CAPTION OFF`へ切り替える
3. relayを`Ctrl+C`で停止する
4. 一時的なtokenやAPI credentialを破棄する
5. 字幕本文・音声が外部サービスへ保存された場合は、合意済みの保持方針に従う

物理スイッチャーの機種、入力番号、切替ボタン、収録継続確認の具体手順は機材確定後にこのRunbookへ追記します。未記入のままでは本番Goにしません。
