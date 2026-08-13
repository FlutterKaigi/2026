# Venue screen captions

FlutterKaigiの正面スクリーン向けリアルタイム翻訳字幕オーバーレイです。Flutter Webは字幕だけを透明背景で描画し、登壇者映像の取り込みと合成はOBSに任せます。

> [!IMPORTANT]
> この実装は技術試作であり、本番採用は未承認です。DroidKaigi後のフォローアップで進捗を確認し、理事・運営・会場・制作・収録担当によるGo／No-Go判断と実会場ゲートの通過後にのみ採用します。来場者アプリ内字幕は必須の独立フォールバックとしてアプリチームが並行開発しますが、このブランチの実装範囲には含みません。

## 設計上の境界

- 正面スクリーン経路は会場PC内で完結し、クラウドやFirestoreを必須にしない
- STT・翻訳プロセスからはローカルHTTP APIで字幕を受け取る
- オーバーレイにはローカルWebSocketで字幕を配信する
- Flutter WebはUVC／HDMI映像を直接扱わない
- OBSの「字幕なし」シーンに加え、合成PCが停止しても使える物理HDMIバイパスを用意する
- 切断、無効データ、期限切れ時に、観客画面へエラーを表示しない

Flutter Web、OBS、Dart relay、Caption Event v1は今回の試作候補です。会場機材、制作デザイン、運用レビューの結果によって変更できます。現時点の1920×1080、1行、64 pxも本番値ではありません。

## 起動

リポジトリルートから実行します。

```bash
fvm dart pub get
fvm dart run melos venue-screen:build
export VENUE_CAPTION_WRITE_TOKEN='<32文字以上の試験用secret>'
fvm dart run melos caption-relay:serve
```

実運用ではplaceholderを直接使わず、`export VENUE_CAPTION_WRITE_TOKEN="$(openssl rand -hex 32)"`で試験ごとに生成します。

`caption-relay:serve`はrelease build済みの`apps/venue_screen/build/web`を配信します。画面コードを変更した場合は、relayを起動し直す前に`venue-screen:build`を再実行してください。

このブランチが提供するのは「字幕イベント受信から会場表示まで」のvertical sliceです。マイク音声を取得するSTT・翻訳producer本体は未選定・未実装で、本番を翻訳できる完成システムではありません。producer、音声経路、用語集、API障害時の運用を別タスクで成立させることがGo／No-Goの前提です。

起動後のURL:

- OBS用: `http://127.0.0.1:8088/?room=main&session=rehearsal`
- 調整用プレビュー: `http://127.0.0.1:8088/?view=preview&room=main&session=rehearsal`
- ヘルスチェック: `http://127.0.0.1:8088/healthz`

匿名化した字幕fixtureを別ターミナルから流せます。

```bash
export VENUE_CAPTION_WRITE_TOKEN='<relay起動時と同じsecret>'
fvm dart run melos caption-relay:replay
```

## 字幕生成側からの入力

STT・翻訳側は、同じPCのAPIへPOSTします。リレーが時刻と単調増加する`sequence`を付け、WebSocketのCaption Event v1へ変換します。

`translatedText`は「スクリーンにそのまま表示できる短い意味単位」で送信してください。オーバーレイは省略された文を後続画面へ自動繰り越ししません。生成側が句読点・発話境界を使って分割し、各チャンクを順番に送る責任を持ちます。最終的な文字数ではなく、採用するフォント、言語、行数、実解像度で収まることをリハーサルfixtureで確認します。

```bash
source_started_at="$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
curl -X POST http://127.0.0.1:8088/api/v1/captions \
  -H 'content-type: application/json' \
  -H "authorization: Bearer ${VENUE_CAPTION_WRITE_TOKEN}" \
  --data @- <<JSON
{
    "roomId": "main",
    "sessionId": "rehearsal",
    "utteranceId": "rehearsal-42",
    "utteranceSequence": 42,
    "revision": 0,
    "sourceText": "FlutterKaigiへようこそ。",
    "translatedText": "Welcome to FlutterKaigi.",
    "isFinal": true,
    "sourceStartedAt": "${source_started_at}",
    "clearAfterMs": 8000
}
JSON
```

`sourceStartedAt`には、音声取得側のproducerが検出した発話区間の開始時刻をUTCのISO-8601形式で入れます。リハーサルではPCとproducerの時計を同期してください。未来5秒超／過去5分超は拒否されます。relayは受理した最終字幕について`relay受信時刻 - sourceStartedAt`を集計し、本文を保存せず`/healthz`の`finalCaptionLatencyMs`へ`count`、`p50`、`p95`、`max`（すべてms）を出します。この集計は全room／session横断の直近1,000 finalで、relay再起動時にresetされ、WebSocket・OBS・描画時間は含みません。

`utteranceSequence`はセッション内で新しい発話ごとに増やし、同じ発話のpartial／final更新には同じ`utteranceId`、同じ`sourceStartedAt`、増加する`revision`を使います。relayは古い発話、同じ／古いrevision、final確定後のpartialを拒否するため、非同期翻訳の完了順が前後しても画面が過去へ巻き戻りません。

即時消去:

```bash
curl -X POST http://127.0.0.1:8088/api/v1/clear \
  -H 'content-type: application/json' \
  -H "authorization: Bearer ${VENUE_CAPTION_WRITE_TOKEN}" \
  --data '{"roomId":"main","sessionId":"rehearsal"}'
```

relayはループバック以外へのbindを拒否します。ポートフォワード、会場Wi-Fi、インターネットへ公開しません。字幕投入とclearはループバックでも`VENUE_CAPTION_WRITE_TOKEN`によるBearer認証が必須です。WebSocketは読取専用で、ブラウザーからはrelayと同一originの場合だけ接続できます。write tokenをURL、OBS設定、ログへ入れず、試験ごとに更新して終了時に破棄してください。STT・翻訳を別PCで動かす要件が確定した場合は、この平文HTTPを公開せず、認証・暗号化を含む別transportを会場ネットワーク担当と設計します。

## 表示調整

OBS Browser SourceのURLクエリで調整します。

| パラメーター |            既定値 | 範囲・用途                                    |
| ------------ | ----------------: | --------------------------------------------- |
| `room`       |            `main` | 会場ID                                        |
| `session`    |       `rehearsal` | セッションID。セッション間の字幕混入を防ぐ    |
| `maxLines`   |               `1` | `1`または`2`。まず1行で検証する               |
| `fontSize`   |              `64` | 36–96 px                                      |
| `lineHeight` |            `1.25` | 1.0–1.6                                       |
| `horizontal` |              `72` | 左右余白 24–200 px                            |
| `bottom`     |              `54` | 下余白 16–240 px                              |
| `opacity`    |            `0.88` | 背景不透明度 0.65–1.0                         |
| `staleAfter` |              `12` | heartbeat停止を判断する秒数 6–60              |
| `view`       |         `overlay` | `preview`で診断情報と模擬スライドを表示       |
| `ws`         | 同一originの`/ws` | `flutter run`時のみ使うloopback WebSocket URL |

1行表示では長い翻訳が省略されます。STT・翻訳側で意味のまとまりを短く分割するか、実会場検証後に`maxLines=2`を採用してください。オペレーターはプレビューで長文fixtureを流し、末尾の省略、意図しない改行、スライド重要領域との重なりを目視検知します。本番中も翻訳生成側のチャンク長とプレビューを監視し、省略が続く場合は字幕送信停止または`CAPTION OFF`へ切り替えます。プレビュー画面の診断情報はOBS用画面には一切表示されません。

`ws`は`flutter run`の開発サーバーからloopback relayへ接続する場合だけ指定します。その場合だけrelayを`--allow-loopback-development-origin`付きで起動します。本番relayは同一origin以外のブラウザー接続を拒否します。ユーザー情報や`token`を含むURLは設定エラーとなり、OBS用画面は何も表示しません。認証情報はURLへ置きません。

表示カード、色、余白、安全領域は制作物チームによるレビュー前の仮デザインです。登壇者ごとにスライドの下端を塞がないこと、最後列から読めること、明暗・日本語・英語・混在文で文字が欠けないことを確認してから固定します。

詳細は[運用Runbook](../../docs/venue-subtitles/RUNBOOK.md)を参照してください。
