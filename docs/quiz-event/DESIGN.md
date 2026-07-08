# クイズ大会機能 設計書

スポンサー提供の問題でチーム対抗クイズ大会を行う機能の設計ドキュメント。
参加者はカンファレンスアプリ(`apps/app`)から参加し、運営は管理ダッシュボード(`apps/dashboard`)から進行を制御する。

## 1. 企画要件

- 参加者は先着 80 人。4 人 1 チームを運営側でランダム自動編成し、最大 20 チーム
- 前半戦・後半戦の 2 回開催。各回: 30 分の参加登録 → 30 分のクイズ
- 各回スポンサー 4 社 × 各 2 問 = 8 問を出題
- 問題はスポンサー企業が作成し、運営が代理登録する
- 各回終了時に総合上位 3 チームへ FlutterKaigi から景品
- スポンサー別 2 問を全問正解したチームは当該スポンサーのブースへ誘導し、景品を受け取る

### 企画側と確定済みの決定事項

| 論点 | 決定 |
|---|---|
| 参加資格 | 会場にいる人なら誰でも(全員チケット購入者のため) |
| 定員 | 先着 80 人で締切 |
| 回答方式 | チームで 1 回答(メンバーの誰でも変更可、締切時点の値が最終回答) |
| 同点順位 | システムでは同点をそのまま表示し、じゃんけん等の運用で 3 チームに絞る |
| 端数チーム | 3〜5 人チームを許容 |
| 遅刻者 | 登録済みなら編成後でも自分のテーブルに着けば参加可 |
| 問題形式 | ○×(2 択)と 4 択を混在可 |
| 制限時間 | 読み上げ後 3 分(問題ごとに調整可能) |
| 問題入稿 | フォーム等で収集し、運営がダッシュボードから代理登録 |
| チーム集合 | 番号付きテーブルへ誘導 |
| 前後半の重複参加 | システムでは制限せず、当日の運用(アナウンス)で制御 |

### 未解決の懸念

- 回答 3 分 × 8 問 + 読み上げ・正解発表で **30 分枠を超過する見込み**(32〜36 分)。
  回答時間の短縮・発表のテンポ・枠の拡大のいずれかを企画側と要調整。
  `durationSeconds` を問題ごとに持つため、当日のシステム側での短縮調整は可能。

## 2. 設計の基本方針

**Cloud Functions を導入せず、dashboard(管理者クライアント)を「進行サーバ」役にする。**

- 出題・締切・採点・チーム編成はすべて運営が dashboard のボタンで駆動する
- 参加者アプリは Firestore のリアルタイム購読(既存の `StreamProvider` + `watchAll()` パターン)で追従するのみ
- 既存インフラ(Firebase BaaS: Firestore + Auth + App Check)への追加はゼロ
- 司会の読み上げと同期して出題できるため、当日の進行主導権が運営に残る

ただし既存コレクションの「read 全公開」方針をクイズにそのまま適用すると
**締切前に他チームの回答が見えてクイズが成立しない**ため、クイズ関連コレクションのみ read 制限を入れる(§5)。

### 認証

参加者は **Firebase 匿名認証**(`signInAnonymously`)。クイズ参加ボタンを押した時に初回サインインし、
`uid` で参加者を識別する。入力はニックネームのみ。30 分で 80 人を捌くため、サインアップの摩擦をゼロにする。

## 3. データ構造(Firestore)

```
quizEvents/{eventId}                     # 前半戦・後半戦で 2 ドキュメント
  title: LocaleMap
  status: 'registration' | 'teamBuilding' | 'inProgress' | 'finished'
  currentQuestionId: string?
  sponsorIds: [sponsorId, ...]           # 出題順(4 社)

  participants/{uid}                     # ドキュメント ID = Firebase Auth uid
    displayName: string                  # ルールで文字数を強制(20 文字以内)
    registeredAt: Timestamp
    teamId: string?                      # チーム編成時に運営が書き込み

  teams/{teamId}
    tableNumber: int                     # 物理テーブル番号(1〜20)。集合誘導の主キー
    name: string                         # 演出用("Team Scaffold" 等 Widget 名を自動生成)
    memberUids: [uid, ...]
    members: [{uid, displayName}, ...]   # 表示用に非正規化
    score: int                           # 冪等再集計(正解数 × 10)で毎回上書き
    rank: int?                           # 全問終了後に確定
    perfectSponsorIds: [sponsorId, ...]  # 全問終了後に一括判定

  questions/{questionId}
    sponsorId: string
    order: int
    title: string
    options: [string]                    # 2〜4 件。○× は 2 件("○", "×")
    durationSeconds: int                 # デフォルト 180。当日調整可
    status: 'draft' | 'open' | 'closed' | 'revealed'
    openedAt: Timestamp?                 # open 時に一度だけ書く(以後更新しない)
    closesAt: Timestamp?                 # open 時に now + durationSeconds で確定
    correctOptionIndex: int?             # revealed 遷移と同一バッチで secret からコピー
    explanation: string?

  questions/{questionId}/secret/answer   # クライアント read 不可・管理者のみ
    correctOptionIndex: int
    explanation: string

  answers/{questionId}_{teamId}          # チームで 1 回答。ID で 1 問 1 チーム 1 件を保証
    questionId: string
    teamId: string
    selectedOptionIndex: int?            # 未回答は null
    answeredBy: uid?                     # 最後に変更したメンバー
    submittedAt: Timestamp?
    isCorrect: bool?                     # 採点時に dashboard のみ書き込み
```

回答ドキュメントは参加者が作成するのではなく、**運営の「出題」操作時に全チーム分を
(`selectedOptionIndex: null` で)事前作成する**。参加者の権限が update のみになるため
ルールが単純化し、ID 偽装の経路が構造的になくなり、存在しないドキュメントの購読による
permission-denied も回避できる。

### packages/data への追加

既存パターン(freezed モデル + リポジトリ + JSON Schema + シード)に従い、以下を追加する。

- モデル: `QuizEvent`, `QuizParticipant`, `QuizTeam`, `QuizQuestion`, `QuizAnswer`
- リポジトリ: 各モデルの Firestore 実装。リアルタイム購読用の `watchXxx()`(`Stream`)を提供
- JSON Schema: `packages/data/firebase/schemas/firestore/` 配下に追加
- シードデータ: エミュレータでの開発・リハーサル用

## 4. 得点・順位ルール

- 正解 = 10 点固定。チームスコアは `answers` の正解数から **毎回再集計して上書き**する(加算しない)。
  採点処理が冪等になり、ボタン二度押し・ブラウザクラッシュ後の再実行が安全になる
- 回答速度によるボーナス・タイブレークは行わない
  (「議論して締切間際に確定したチームが不利」となり、議論促進の企画意図と矛盾するため)
- 同点は同順位として表示し、上位 3 チームへの絞り込みはじゃんけん等の運用で行う
- スポンサーパーフェクト(2 問全問正解)の判定と最終順位の確定は、全 8 問の正解発表後に一括で行う
  (途中でパーフェクト状況を表示すると 2 問目の回答戦略に影響が出るため)

## 5. Firestore セキュリティルール

### アクセス制御方針

| パス | read | write(クライアント) |
|---|---|---|
| `quizEvents`, `teams` | 全公開 | 不可(管理者のみ) |
| `questions` | get のみ(draft は管理者のみ)。list は管理者のみ | 不可(管理者のみ) |
| `questions/*/secret` | **不可**(管理者のみ) | 不可 |
| `participants/{uid}` | 全公開 | 本人のみ create。イベント `status == 'registration'` 中のみ。`displayName` は 1〜20 文字 |
| `answers/{qid}_{tid}` | **自チームメンバーのみ**(get のみ。list は管理者のみ) | 自チームメンバーのみ update(create / delete は管理者のみ) |

### answers の update ルールで強制すること

- 対象 question が `status == 'open'` かつ `request.time < closesAt`
  (サーバ時刻基準のため端末の時計ずれの影響を受けない)
- 書き込み可能フィールドは `selectedOptionIndex` / `answeredBy` / `submittedAt` のみ
  (`diff().affectedKeys().hasOnly([...])`)。**`isCorrect` はクライアントから一切書けない**
- `answeredBy == request.auth.uid`、`submittedAt == request.time`、
  `selectedOptionIndex` は `options` の範囲内の整数
  (`questionId` / `teamId` は事前作成 + フィールドホワイトリストにより変更不能)
- 自チーム判定は `request.auth.uid in get(team).data.memberUids`(ルール内 get は 1 評価あたり 2 回で上限 10 回に収まる)

### これにより防げる不正

- 他チームの回答の覗き見(コバンザメ回答) → answers の read 制限
- 締切前の正誤の漏洩 → `isCorrect` の書き込みを revealed 遷移と同一バッチに限定(§6)
- 得点の自己申告・改ざん → `isCorrect` のフィールドホワイトリスト
- 他チーム名義の回答・妨害 → ドキュメント ID 整合 + メンバーシップ検証
- 締切後の回答 → `request.time < closesAt`

匿名認証による複数アカウントは技術的に防げないが、回答が締切まで自チーム以外に見えないため
カンニング経路がなく実害はない(チーム = 物理的に集合した 4 人という運用前提)。

### インデックス

現状 `firestore.indexes.json` は空。必要な複合インデックスを実装時に洗い出して**事前定義・デプロイ**する
(当日の初回クエリで `failed-precondition` になるのが典型事故のため、ステージングでのリハーサルで検証する)。

## 6. 運営ダッシュボード(apps/dashboard)

`feature/quiz/` として既存の feature パターンに従って追加する。

### 問題管理

- スポンサーごとに問題の CRUD(問題文・選択肢 2〜4 件・正解・解説・制限時間)
- スポンサーからの入稿はフォーム等で収集し、運営が代理登録する(スポンサー用ロールは新設しない)

### 進行コンソール(当日のメイン画面)

- 登録者数のリアルタイム表示 → 「チーム編成」ボタン
  - ランダムシャッフルで 4 人ずつに分割。端数は 3〜5 人チームを許容
  - チーム名は Flutter Widget 名等から自動生成、テーブル番号を割当
  - `teamBuilding` 中は再編成(既存チームを削除して作り直し)が可能。クイズ開始後は不可
- 問題ごとに「出題」→「締切」→「正解発表」ボタン
  - 出題: `status = 'open'`, `openedAt = now`, `closesAt = now + durationSeconds` を設定し、
    **全チーム分の回答ドキュメントを同一バッチで事前作成**(§3 参照)。draft の問題のみ実行可
  - 正解発表は締切後のみ実行可(回答受付中の正解漏洩をリポジトリ層でも防止)。
    発表済みの問題への再実行(再採点)も可能
  - 正解発表: **採点(`isCorrect` 書き込み)+ `team.score` 再集計 + secret から正解コピー + `status = 'revealed'`
    を単一 WriteBatch で原子的に実行**。締切〜発表の間に正誤が漏れる経路を塞ぐ
  - 採点は冪等(再集計方式)のため、失敗・二度押し時は同じボタンの再実行で回復できる
- 全 8 問終了後に「結果確定」ボタン: `rank` と `perfectSponsorIds` を一括確定、`status = 'finished'`
- 進行状態はすべて Firestore にあるため、ブラウザクラッシュ時は別 PC で開き直してそのまま継続可能

### ステージ投影ページ

会場スクリーン用の表示を dashboard 内の別ルートとして実装する。

- 問題・選択肢・カウントダウン・回答済みチーム数
- 正解発表・解説
- チーム編成発表・ランキング発表の演出

## 7. 参加者アプリ(apps/app)

`feature/quiz/` として追加。ルートは `/quiz` の 1 本(TypedGoRoute)。
ホームのお知らせとイベント情報ページにバナー導線を置く。

画面は `quiz_events.status` と自分の参加状態で切り替わるステートマシン:

1. **参加登録**: ニックネーム入力 → 参加ボタン(現在の参加人数をリアルタイム表示)。
   80 人到達時はアプリ側で登録ボタンを無効化(厳密な先着制御はせず、多少の超過は編成時に調整)
2. **待機**: 「登録済み。チーム発表をお待ちください」
3. **チーム発表**: 「テーブル 7 へ!」+ チーム名・メンバー一覧。
   物理テーブル番号が集合誘導の主役、Widget 名チーム名は演出
4. **出題中**: 問題文 + 選択肢(○× は 2 大ボタン表示)。
   - 選択肢をタップするとチーム全員の画面にリアルタイム反映(誰でも締切まで変更可 = 議論が発生する)
   - カウントダウンは `closesAt` からクライアント計算(question doc の更新は発生させない)
   - 締切数秒前に UI 側で入力をロックし、サーバ側の write 拒否をユーザーに体感させない
   - 同時タップの書き込み競合は last-write-wins を許容し、楽観的 UI + リトライで吸収
5. **正解発表**: 正解・解説・自チームの正誤とスコア
6. **最終結果**: 順位・上位 3 チーム表示、パーフェクト達成スポンサーのブース誘導

遅刻者(登録済みだが編成時に不在)は、本人のアプリにチーム発表と進行中の問題が表示され続けるため、
途中からテーブルに着けばそのまま参加できる(追加実装不要)。

## 8. 当日フローとの対応

| 当日の流れ | システム操作(dashboard) | 参加者アプリ |
|---|---|---|
| 参加登録(30 分) | イベントを `registration` に | 参加登録 → 待機 |
| 80 人到達 or 締切 | 「チーム編成」実行 | チーム発表 → テーブルへ移動 |
| 出題(× 8 問) | 司会の読み上げ後「出題」→ 3 分後「締切」→「正解発表」 | 回答 → 正解確認 |
| 結果発表 | 「結果確定」 | 最終順位・ブース誘導表示 |
| 後半戦 | 別の `quiz_events` ドキュメントで同じ流れを繰り返す | 再登録から |

前後半は完全に独立したイベントとして扱う(参加者・チームとも作り直し)。
前半参加者の後半参加はシステムでは制限せず、当日のアナウンスで制御する
(uid で前半参加者を判別できるため、必要になれば「前半参加者は登録不可」を後から追加可能)。

## 9. 運用上の注意(Runbook 候補)

- **App Check**: Web(dashboard)の reCAPTCHA 検証が詰まると全書き込みが失敗する。
  事前にステージングで enforcement を検証し、緊急時に enforcement を一時オフにする手順を用意する
- **通信環境**: 参加者 80 人が同時にアプリを使うため、会場 Wi-Fi の収容能力を事前確認する
- **リハーサル**: エミュレータ + シードで通し確認したうえで、ステージング環境で本番同等のリハーサルを行う
  (80 人分の負荷はスクリプトで模擬)
- **ニックネーム**: システムは文字数制限のみ。会場投影に不適切な名前は運営の目視で対処する

## 10. 実装ステップ

1. `packages/data`: モデル・リポジトリ・セキュリティルール・インデックス・JSON Schema・シード
2. `apps/dashboard`: 問題管理 CRUD
3. `apps/app`: 匿名認証 + `/quiz` ルート + 参加登録〜チーム発表
4. `apps/dashboard`: 進行コンソール(チーム編成・出題・採点)
5. `apps/app`: 出題・回答・結果画面
6. `apps/dashboard`: ステージ投影ページ
7. 通しリハーサル(エミュレータ → ステージング)
