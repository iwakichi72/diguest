# Diguest — Design Tokens

## 概要

デザイントークンはDiguestの視覚的一貫性を保つための最小単位。
CSS変数・Python/Rich定数・将来のGUIライブラリすべてで共通して参照できる形で定義する。

---

## カラー

### 哲学

色は少なく使う。炭と紙と、一筋の光。

- ダークモード: 地の底にある炭のような深い黒（青みを排除した温かみのある暗さ）
- アクセント: 1色のみ。ランタンの光のような、くすんだ琥珀

### ダークモード（プライマリ）

```css
/* backgrounds */
--color-bg-base:      #111009;  /* 最深部。画面の地 */
--color-bg-surface:   #1A1814;  /* カード・入力欄の背景 */
--color-bg-subtle:    #242018;  /* ホバー時の行背景など */
--color-bg-inverse:   #EDE8E1;  /* 反転が必要な場合（ほぼ使わない） */

/* borders */
--color-border:       #2C2820;  /* 通常の境界線 */
--color-border-focus: #5A5040;  /* フォーカスリング */

/* text */
--color-text-primary:   #EDE8E1;  /* 主文章 */
--color-text-secondary: #7A7468;  /* 補足・メタ情報 */
--color-text-muted:     #443E38;  /* ヒント・無効状態 */
--color-text-inverse:   #111009;  /* bg-inverse上のテキスト */

/* accent — 1色のみ */
--color-accent:         #C4956A;  /* 琥珀。リンク・フォーカス下線・Diguestの問いのサイドライン */
--color-accent-subtle:  #2A2018;  /* アクセント背景（hover等） */

/* functional */
--color-success:        #5C8B6E;  /* 保存完了などの成功 */
--color-error:          #8B5C5C;  /* エラー */
```

### ライトモード（セカンダリ）

```css
/* backgrounds */
--color-bg-base:      #F5F1EB;  /* 古い紙のようなオフホワイト */
--color-bg-surface:   #FEFCF8;  /* 入力欄・カード */
--color-bg-subtle:    #EDE8E0;  /* ホバー行 */

/* borders */
--color-border:       #D4CFC6;
--color-border-focus: #A89880;

/* text */
--color-text-primary:   #1C1A16;
--color-text-secondary: #6E6860;
--color-text-muted:     #B0A898;

/* accent */
--color-accent:         #A07848;  /* ライトモードでは少し濃く */
--color-accent-subtle:  #F0E8DC;

/* functional */
--color-success:        #406050;
--color-error:          #7A4040;
```

### Rich（CLI）カラーマッピング

```python
# rich スタイル定義
STYLE_PRIMARY   = "color(252)"   # #D0CBC4 相当
STYLE_SECONDARY = "color(242)"   # #6C6560 相当
STYLE_MUTED     = "color(238)"   # #444038 相当
STYLE_ACCENT    = "color(179)"   # #C4956A 相当（TerminalによってはYellow系）
STYLE_SUCCESS   = "color(107)"   # #87AF5F 相当
STYLE_ERROR     = "color(167)"   # #AF5F5F 相当
STYLE_DIGUEST   = "italic color(252)"  # Diguestの問いのテキスト
```

---

## タイポグラフィ

### フォントスタック

```css
/* UIフォント（ナビ・ボタン・メタ情報） */
--font-ui: "Inter", "Hiragino Sans", "Hiragino Kaku Gothic ProN",
           "Yu Gothic UI", system-ui, sans-serif;

/* 本文フォント（対話・ノートプレビュー） */
--font-reading: "Noto Serif JP", "Hiragino Mincho ProN",
                "Yu Mincho", "YuMincho", Georgia, serif;

/* コードフォント（ファイルパス・モデル名） */
--font-mono: "JetBrains Mono", "Fira Code", "SF Mono",
             "Menlo", "Consolas", monospace;
```

### フォントサイズスケール

```css
--text-xs:   11px;   /* メタ・ラベル・発言カウンター */
--text-sm:   13px;   /* 補足テキスト・ヒント */
--text-base: 16px;   /* UI標準サイズ */
--text-md:   18px;   /* 対話本文 */
--text-lg:   22px;   /* 画面見出し */
--text-xl:   28px;   /* セッションのテーマ表示 */
```

### 行間

```css
--leading-tight:   1.4;   /* UI要素（ボタン・ラベル） */
--leading-base:    1.7;   /* UIテキスト */
--leading-reading: 1.9;   /* 対話本文・ノートプレビュー */
--leading-loose:   2.2;   /* 引用・Diguestの問い（間を持たせる） */
```

### ウェイト

```css
--weight-regular: 400;
--weight-medium:  500;
--weight-bold:    600;  /* 700は使わない。重すぎる */
```

---

## スペーシング

8pxを基本単位とする。

```css
--space-1:  4px;
--space-2:  8px;
--space-3:  12px;
--space-4:  16px;
--space-5:  20px;
--space-6:  24px;
--space-8:  32px;
--space-10: 40px;
--space-12: 48px;
--space-16: 64px;
--space-20: 80px;
--space-24: 96px;
```

### レイアウト

```css
--layout-content-width:  680px;   /* コンテンツ最大幅 */
--layout-narrow-width:   520px;   /* 入力フォーム等の狭いカラム */
--layout-page-padding-x: var(--space-6);  /* 左右ページ余白 */
--layout-page-padding-y: var(--space-10); /* 上下ページ余白 */
```

---

## ボーダー・シャドウ

```css
/* border radius */
--radius-sm: 4px;    /* 入力フィールド */
--radius-md: 6px;    /* ボタン */
--radius-lg: 12px;   /* カード（ほぼ使わない） */

/* borders */
--border-width: 1px;
--border-style: solid;
```

シャドウは原則使わない。境界線は `--color-border` のみで表現する。
深度は重なりではなく、背景色の差（`--color-bg-base` vs `--color-bg-surface`）で表現する。

---

## コンポーネント定義

### 入力フィールド（textarea / input）

```css
.input {
  background:    var(--color-bg-surface);
  border:        var(--border-width) var(--border-style) var(--color-border);
  border-radius: var(--radius-sm);
  color:         var(--color-text-primary);
  font-family:   var(--font-reading);
  font-size:     var(--text-md);
  line-height:   var(--leading-reading);
  padding:       var(--space-4) var(--space-5);
  resize:        none;
  width:         100%;
}

.input:focus {
  border-color: var(--color-border-focus);
  outline:      none;
  /* フォーカスリングはborder-colorの変化のみ。ボックスシャドウなし */
}

.input::placeholder {
  color: var(--color-text-muted);
}
```

### ボタン（プライマリ）

```css
.button-primary {
  background:    transparent;
  border:        1px solid var(--color-border);
  border-radius: var(--radius-md);
  color:         var(--color-text-primary);
  font-family:   var(--font-ui);
  font-size:     var(--text-base);
  font-weight:   var(--weight-medium);
  padding:       var(--space-3) var(--space-6);
  cursor:        pointer;
  transition:    opacity 150ms ease;
}

.button-primary:hover {
  opacity: 0.7;
}

.button-primary:disabled {
  color:   var(--color-text-muted);
  cursor:  default;
  opacity: 1;
}
```

ボタンに色を付けない。強調はサイズ・ポジションで行う。

### Diguestの問い（ダイアログ内）

```css
.diguest-turn {
  border-top:    1px dashed var(--color-border);
  border-bottom: 1px dashed var(--color-border);
  color:         var(--color-text-primary);
  font-family:   var(--font-reading);
  font-size:     var(--text-md);
  font-style:    italic;
  line-height:   var(--leading-loose);
  margin:        var(--space-8) 0;
  padding:       var(--space-6) 0;
}
```

### ユーザーの発言（ダイアログ内）

```css
.user-turn {
  color:       var(--color-text-primary);
  font-family: var(--font-reading);
  font-size:   var(--text-md);
  line-height: var(--leading-reading);
  margin:      var(--space-8) 0;
}
```

### ノートリストの行

```css
.note-row {
  align-items:     baseline;
  border-radius:   var(--radius-sm);
  color:           var(--color-text-primary);
  cursor:          pointer;
  display:         flex;
  gap:             var(--space-5);
  padding:         var(--space-3) var(--space-4);
  text-decoration: none;
  transition:      background 100ms ease;
}

.note-row:hover {
  background: var(--color-bg-subtle);
}

.note-row-date {
  color:      var(--color-text-secondary);
  font-size:  var(--text-sm);
  flex-shrink: 0;
  font-variant-numeric: tabular-nums;
  width: 2ch;
}

.note-row-theme {
  font-size:   var(--text-base);
  overflow:    hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
```

---

## アニメーション

```css
/* 画面フェードイン */
@keyframes fade-in {
  from { opacity: 0; }
  to   { opacity: 1; }
}

.page-enter {
  animation: fade-in 200ms ease;
}

/* ストリーミングカーソル */
@keyframes cursor-blink {
  0%, 100% { opacity: 1; }
  50%       { opacity: 0; }
}

.streaming-cursor::after {
  content:    "▍";
  color:      var(--color-text-muted);
  animation:  cursor-blink 800ms step-end infinite;
  font-style: normal;
}
```

**トランジション統一値:**
```css
--transition-fast:   100ms ease;
--transition-base:   150ms ease;
--transition-slow:   200ms ease;
--transition-page:   200ms ease;
--transition-scroll: 300ms ease;
```

---

## CLI（Rich）レイアウト定義

GUIに対応するCLIのビジュアル設定。

```python
from rich.console import Console
from rich.theme import Theme

THEME = Theme({
    "diguest.prompt":    "italic #C4956A",   # Diguestの問い
    "diguest.user":      "#EDE8E1",           # ユーザーの発言
    "diguest.meta":      "#7A7468",           # メタ情報（ターン数・保存先）
    "diguest.muted":     "#443E38",           # ヒント
    "diguest.success":   "#5C8B6E",           # 保存完了
    "diguest.error":     "#8B5C5C",           # エラー
    "diguest.separator": "#2C2820",           # 区切り線の色
})

# 区切り線（Diguestの問いの前後）
SEPARATOR = "╌" * 48  # スタイル: diguest.separator

# コンテンツ幅
CONTENT_WIDTH = 72  # 文字数

console = Console(theme=THEME, width=CONTENT_WIDTH)
```

---

## アクセシビリティ

- テキストのコントラスト比: `--color-text-primary` on `--color-bg-base` = **11.8:1**（AA・AAA共に合格）
- `--color-text-secondary` on `--color-bg-base` = **4.8:1**（AA合格）
- フォーカス状態: `border-color` の変化のみ。キーボード操作可能なすべての要素にfocusスタイルを持たせる
- フォントサイズの最小値: 11px（`--text-xs`）。これ以下は使わない
