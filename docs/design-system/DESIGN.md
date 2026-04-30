# FlutterKaigi 2026 DESIGN.md

本ドキュメントは、FlutterKaigi 2026のアプリおよびWebサイトにおける共通デザインシステム（カラー、タイポグラフィ、基本方針）を定義するガイドラインです。

> **デザイントークンの正データ**: Figma から書き出した W3C 互換トークンファイルです。本ドキュメントに記載の値はすべて以下のファイルから引用しています。
>
> | ファイル | 内容 |
> | :--- | :--- |
> | [`tokens/color.tokens.json`](./tokens/color.tokens.json) | カラーパレット全体（Light / Dark / High Contrast / Medium Contrast・State Layers・Reference Palette） |
> | [`tokens/typography.tokens.json`](./tokens/typography.tokens.json) | タイポグラフィスケール |
> | [`tokens/font.tokens.json`](./tokens/font.tokens.json) | フォントファミリー・ウェイト定義 |
> | [`tokens/effect.tokens.json`](./tokens/effect.tokens.json) | シャドウ・エフェクト定義 |

## 1. デザインコンセプト・基本方針

今年のテーマである「Assemble（集結）」やイベントの熱気を表現するため、**Magenta Red (#FF0055)** から **Deep Navy (#001155)** へと変化する鮮やかなグラデーションをメインビジュアルの基調としています。このグラデーションの中間を繋ぐ重要なキーカラーとして **Deep Purple (#6200EA)** を定義し、ブランドの象徴色として活用します。

直線的な幾何学模様（手裏剣/風車モチーフ）をアクセントとしつつ、UIの設計は **Material Design 3 (M3)** に準拠することで、エンジニアフレンドリーかつアクセシビリティの高い構築を目指します。

### フォント（Typography）ルール

* **メインビジュアル（グラフィック・OGP等）**
  * 英数字：**Poppins**（幾何学的で親しみやすいテーマ性を強調）
  * 日本語：**Noto Sans JP**
* **アプリ / Web UI（プロダクト全体）**
  * すべて：**Noto Sans JP**（視認性・可読性・多言語対応の安定性を最優先）

---

## 2. Color Scheme（カラーシステム）

Figmaのデザイントークンに基づき定義されたカラーパレットです。

### 🎨 Key Colors（ブランドカラー）

メインビジュアルのグラデーションおよび、ブランドを象徴する要素に使用します。

| 役割 | カラーコード (HEX) | 用途・説明 |
| :--- | :--- | :--- |
| **Magenta Red** | `#FF0055` | グラデーションの左側（始点）。情熱や熱気を表現。 |
| **Deep Purple** | `#6200EA` | **ブランドの象徴色。** グラデーションの中間色として全体を調和させる。 |
| **Deep Navy** | `#001155` | グラデーションの右側（終点）。テック感や信頼感を表現。 |

### 🎨 Work Colors（装飾グラフィック用）

手裏剣モチーフなどのグラフィック要素にのみ使用します。UI コンポーネントには使用しないでください。

| 役割 | カラーコード (HEX) | 用途 |
| :--- | :--- | :--- |
| **Shuriken / Firebase Red** | `#DD2C00` | 手裏剣グラフィックのアクセント。 |
| **Shuriken / Firebase Orange** | `#FF9100` | 手裏剣グラフィックのアクセント。 |
| **Firepop / Dark** | `#A80B04` | Firepop グラフィック（暗）。 |
| **Firepop / Orange** | `#F35201` | Firepop グラフィック（中）。 |
| **Firepop / Primary** | `#FB8700` | Firepop グラフィック（メイン）。 |
| **Firepop / Yellow** | `#FBB901` | Firepop グラフィック（明）。 |

### 📱 M3 UI Colors — Light Mode

アプリ・WebのシステムUIに使用する基本パレットです。Deep Purpleをベースに生成されています。

| Role | Color | On Color | 用途・説明 |
| :--- | :--- | :--- | :--- |
| **Primary** | `#65558F` | `#FFFFFF` | 主要アクション（FAB、Primary ボタンなど）。 |
| **Primary Container** | `#E9DDFF` | `#4D3D75` | 選択状態の強調・背景要素。 |
| **Secondary** | `#904A45` | `#FFFFFF` | 補助的な強調アクションや情報。 |
| **Secondary Container** | `#FFDAD6` | `#73332F` | Secondary の背景要素。 |
| **Tertiary** | `#3C6090` | `#FFFFFF` | 第3のアクセント（タグやバッジなど）。 |
| **Tertiary Container** | `#D4E3FF` | `#224876` | Tertiary の背景要素。 |
| **Error** | `#BA1A1A` | `#FFFFFF` | エラーメッセージ、破壊的アクション。 |
| **Error Container** | `#FFDAD6` | `#93000A` | エラー状態の背景要素。 |
| **Surface** | `#FDF7FF` | `#1D1B20` | カードなどの表面レイヤー色。 |
| **Surface Variant** | `#E7E0EB` | `#49454E` | 区切り・インプットフィールドの背景。 |
| **Background** | `#FDF7FF` | `#1D1B20` | 画面全体の背景色。 |
| **Outline** | `#7A757F` | — | 境界線・ディバイダー。 |
| **Outline Variant** | `#CAC4CF` | — | より控えめな境界線。 |
| **Shadow / Scrim** | `#000000` | — | 影・モーダルオーバーレイ。 |

> **Inverse / Fixed / Surface Container 系**（inverse-surface, primary-fixed, surface-container-* など）は [`color.tokens.json`](./tokens/color.tokens.json) を参照してください。

### 🌙 M3 UI Colors — Dark Mode

| Role | Color | On Color | 用途・説明 |
| :--- | :--- | :--- | :--- |
| **Primary** | `#CFBDFE` | `#36275D` | 主要アクション。 |
| **Primary Container** | `#4D3D75` | `#E9DDFF` | 選択状態の強調・背景要素。 |
| **Secondary** | `#FFB3AC` | `#571E1A` | 補助的な強調アクションや情報。 |
| **Secondary Container** | `#73332F` | `#FFDAD6` | Secondary の背景要素。 |
| **Tertiary** | `#A6C8FF` | `#01315E` | 第3のアクセント。 |
| **Tertiary Container** | `#224876` | `#D4E3FF` | Tertiary の背景要素。 |
| **Error** | `#FFB4AB` | `#690005` | エラーメッセージ、破壊的アクション。 |
| **Error Container** | `#93000A` | `#FFDAD6` | エラー状態の背景要素。 |
| **Surface** | `#141218` | `#E6E0E9` | カードなどの表面レイヤー色。 |
| **Surface Variant** | `#49454E` | `#CAC4CF` | 区切り・インプットフィールドの背景。 |
| **Background** | `#141218` | `#E6E0E9` | 画面全体の背景色。 |
| **Outline** | `#948F99` | — | 境界線・ディバイダー。 |
| **Outline Variant** | `#49454E` | — | より控えめな境界線。 |
| **Shadow / Scrim** | `#000000` | — | 影・モーダルオーバーレイ。 |

> **High Contrast / Medium Contrast バリアント** も定義済みです（`deeppurple/sys/light-high-contrast` 等）。詳細は [`color.tokens.json`](./tokens/color.tokens.json) を参照してください。

---

## 3. Typography（タイポグラフィ）

アプリおよびWeb UIにおいては、実装の安定性を考慮し **すべて「Noto Sans JP」** で統一します。

### 📱 アプリ / Web UI用（Noto Sans JP）

M3の5つの階層（Role）に基づいたスケールです。

| 階層 (Role) | サイズ (px) | 行高 (lh) | 字間 (ls) | ウェイト | 用途・説明 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Display L** | 57 | 64 | -0.25 | 400 | 画面内で最大の見出し。トップの日付など。 |
| **Display M** | 45 | 52 | 0 | 400 | 〃 |
| **Display S** | 36 | 44 | 0 | 400 | 〃 |
| **Headline L** | 32 | 40 | 0 | 400 | ページタイトルやセクション見出し。 |
| **Headline M** | 28 | 36 | 0 | 400 | 〃 |
| **Headline S** | 24 | 32 | 0 | 400 | 〃 |
| **Title L** | 22 | 28 | 0 | 400 | コンポーネントの見出し。 |
| **Title M** | 16 | 24 | +0.15 | 500 | 〃 |
| **Title S** | 14 | 20 | +0.10 | 500 | 〃 |
| **Label L** | 14 | 20 | +0.10 | 500 | ボタンテキスト、チップ、タグなど。 |
| **Label M** | 12 | 16 | +0.50 | 500 | 〃 |
| **Label S** | 11 | 16 | +0.50 | 500 | 〃 |
| **Body L** | 16 | 24 | +0.50 | 400 | セッション詳細、お知らせ本文などの長文。 |
| **Body M** | 14 | 20 | +0.25 | 400 | 〃 |
| **Body S** | 12 | 16 | +0.40 | 400 | 〃 |

#### 💡 Baseline と Emphasis の使い分け

* **Baseline**: 上記表に記載された標準スタイル。
* **Emphasis**: Baselineとサイズ・行高・字間は同じまま、**太さ（Weight）のみを一段階太くした**スタイル。
* **実装ルール**: 強調したい箇所では、同じ階層（Role）を維持したままウェイトのみを上書き（例：w400 → w500）して実装してください。

### 🎨 メインビジュアル / OGP グラフィック用

グラフィックとしてのインパクトを重視したスケールです。

| 要素 | フォント | サイズ / ウェイト |
| :--- | :--- | :--- |
| **開催年 (2026)** | Poppins | 72px / Medium (500) |
| **イベント名** | Poppins | 60px / Medium (500) |
| **コンセプト英字** | Poppins | 40px / **Black (900)** |
| **日本語コピー** | Noto Sans JP | 32px / Regular (400) |

---

## 4. Effects（エフェクト）

### 手裏剣モチーフの Shadow

装飾グラフィック（手裏剣/風車モチーフ）に適用するドロップシャドウです。

| プロパティ | 値 |
| :--- | :--- |
| Type | Drop Shadow |
| Color | `#00000040`（不透明度 25%） |
| Offset X | 12px |
| Offset Y | 12px |
| Blur Radius | 10px |
| Spread | 0px |

---

## 5. 開発・実装時の注意事項

### Flutterでの実装

* **テーマの利用**: ハードコードを避け、`Theme.of(context).colorScheme.primary` のようにテーマから色を参照してください。
* **強調の実装例**:

  ```dart
  Text(
    '強調テキスト',
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w500, // Emphasisの適用
    ),
  )
  ```

### State Layers（インタラクション）

ボタン等のホバー・タップ状態は、文字色（On Color）の不透明度を重ねて表現します。

* Hover: `0.08` (8%)
* Focus: `0.10` (10%)
* Pressed: `0.16` (16%)

> Light / Dark 両モードの State Layer カラーは [`color.tokens.json`](./tokens/color.tokens.json) の `color/deeppurple/state-layers/` に定義されています。
