# Diguest — アーキテクチャ設計

## 技術スタック

| 層 | 技術 | 理由 |
|----|------|------|
| フレームワーク | Next.js 15 (App Router) | Server/Client Component分離でFile I/Oを安全に扱える |
| 言語 | TypeScript | 型安全。API境界の誤用を防ぐ |
| スタイリング | Tailwind CSS | DESIGN_TOKENS.mdのカスタム値をconfigに直接マッピング |
| AIバックエンド | Ollama HTTP API | ローカル完結。外部通信なし |
| 永続化 | ローカルファイルシステム（`~/diguest/`）| DBなし制約を満たす唯一の選択肢 |
| フォント | `next/font` (Inter + Noto Serif JP) | レイアウトシフトなしで読み込み |

---

## ディレクトリ構成

```
diguest/
├── app/
│   ├── layout.tsx                    # ルートレイアウト（テーマ・フォント適用）
│   ├── page.tsx                      # ホーム画面（Server Component）
│   ├── session/
│   │   ├── new/
│   │   │   └── page.tsx              # テーマ入力画面（Client Component）
│   │   └── page.tsx                  # 対話画面（Client Component, ?theme=...）
│   ├── notes/
│   │   ├── page.tsx                  # ノート一覧（Server Component）
│   │   └── [fileName]/
│   │       └── page.tsx              # Markdownプレビュー（Server Component）
│   ├── settings/
│   │   └── page.tsx                  # 設定画面（Client Component）
│   └── api/
│       ├── chat/
│       │   └── route.ts              # POST /api/chat（ストリーミング）
│       ├── generate-markdown/
│       │   └── route.ts              # POST /api/generate-markdown
│       ├── save-markdown/
│       │   └── route.ts              # POST /api/save-markdown
│       └── notes/
│           ├── route.ts              # GET /api/notes
│           └── [fileName]/
│               └── route.ts          # GET /api/notes/[fileName]
├── lib/
│   ├── config.ts                     # 設定値（env）の読み込みと型定義
│   ├── ollama.ts                     # Ollama HTTPクライアント
│   ├── markdown.ts                   # Markdown生成・ファイル操作・frontmatter解析
│   └── prompts.ts                    # システムプロンプト定数
├── components/
│   ├── DialogueTurn.tsx              # 1ターン分の表示（user/diguest）
│   ├── StreamingCursor.tsx           # 点滅カーソル（ストリーミング中）
│   ├── NoteRow.tsx                   # ノート一覧の1行
│   └── MarkdownRenderer.tsx          # Markdownレンダリング表示
├── hooks/
│   ├── useSession.ts                 # セッション状態（messages, theme, isStreaming）
│   └── useStreamingChat.ts           # ストリーミングfetchフック
├── types/
│   └── index.ts                      # 共通型定義
├── .env.local                        # 設定（gitignore対象）
├── tailwind.config.ts
└── next.config.ts
```

---

## 型定義（`types/index.ts`）

```typescript
export type Role = 'user' | 'assistant'

export type Message = {
  role: Role
  content: string
}

export type SessionState = {
  theme: string
  messages: Message[]
  isStreaming: boolean
  model: string
}

export type NoteMetadata = {
  fileName: string
  theme: string
  date: string       // ISO 8601
  model: string
  turns: number
}

export type NoteContent = {
  metadata: NoteMetadata
  rawMarkdown: string
}

export type OllamaConfig = {
  baseUrl: string
  model: string
}

export type AppConfig = {
  ollama: OllamaConfig
  notesDir: string
}
```

---

## ルーティング設計

```
/                    → ホーム（Server Component）
/session/new         → テーマ入力（Client Component）
/session?theme=...   → 対話画面（Client Component）
/notes               → ノート一覧（Server Component）
/notes/[fileName]    → Markdownプレビュー（Server Component）
/settings            → 設定（Client Component）
```

### セッションのURL設計の判断

セッションはサーバーに状態を持たない（DBなし制約）。対話中の状態はすべてReact Stateのみで管理する。テーマの受け渡しはクエリパラメータ（`?theme=最近の違和感`）を使う。URLエンコードされるが、ローカル単体ツールとして問題なし。

---

## API設計

### POST `/api/chat`

Ollamaへのストリーミングプロキシ。セッション中の1ターンごとに呼ばれる。

**Request:**
```typescript
{
  messages: Message[]   // 対話履歴全体（システムプロンプトはサーバー側で付与）
  theme: string
}
```

**Response:** `ReadableStream`（text/event-stream）

**処理フロー:**
```
1. システムプロンプト + messages を結合
2. Ollama POST /api/chat にストリーミングリクエスト
3. Ollamaのストリームをそのままクライアントに流す
4. Ollamaが未起動の場合 → 503 + エラーJSON
```

**重要:** システムプロンプトはクライアントから渡さない。サーバー側で `lib/prompts.ts` から注入。これにより「アドバイスしない」制約がクライアント操作で迂回できない。

---

### POST `/api/generate-markdown`

セッション終了時にMarkdownを生成する。ストリーミングなし（一発生成）。

**Request:**
```typescript
{
  theme: string
  messages: Message[]
  model: string
  startedAt: string    // ISO 8601 セッション開始時刻
}
```

**Response:**
```typescript
{
  markdown: string     // 完成したMarkdown文字列
  fileName: string     // YYYYMMDD_HHMMSS_<sanitized-theme>.md
}
```

**処理フロー:**
```
1. Ollamaに要約生成プロンプトを送信（非ストリーミング）
2. 生のテキストからJSONを抽出（正規表現: /\{[\s\S]*\}/）
3. JSON.parse を試みる
   成功 → summary / surfaced を取得
   失敗（C-3修正）→ summary: "" / surfaced: [] でフォールバック継続
4. frontmatter + セクション + 対話ログを組み立て
5. fileName（ファイル名）を生成・返却
6. Ollama呼び出し自体が失敗 → 同様にフォールバックしてログだけ保存
```

**[C-3修正] JSONフォールバック戦略:** ローカルモデルはコードブロックや前置き文を含むことがある。`text.match(/\{[\s\S]*\}/)` でJSON部分を抽出してからパースする。パース失敗時も処理を中断せず空値で継続し、対話ログは必ず保存する。

---

### POST `/api/save-markdown`

生成済みMarkdown文字列をファイルに書き込む。

**Request:**
```typescript
{
  markdown: string
  fileName: string
}
```

**Response:**
```typescript
{
  saved: true
  filePath: string
}
```

**処理フロー:**
```
1. path.basename(fileName) でディレクトリ成分を除去
2. 拡張子が .md であることを確認（違反 → 400）
3. path.resolve 後に notesDir プレフィックスを確認（違反 → 400）
4. config.notesDir が存在しない場合 → mkdir -p
5. filePath = path.join(notesDir, safeName)
6. fs.writeFile（UTF-8）
7. 書き込み失敗 → 500 + エラーJSON
```

**[C-1修正] パストラバーサル防止:** `fileName` はクライアントから来るため `GET /api/notes/[fileName]` と同様の検証を書き込み時にも必ず行う。

---

### GET `/api/notes`

保存済みノート一覧を返す。

**Response:**
```typescript
{
  notes: NoteMetadata[]   // date降順
}
```

**処理フロー:**
```
1. notesDir内の *.md ファイルを列挙
2. 各ファイルのfrontmatter（date, theme, model, turns）をパース
3. date降順でソート
4. NoteMetadata[]として返却
5. notesDir が存在しない → 空配列を返す（エラーにしない）
```

---

### GET `/api/notes/[fileName]`

単一ノートの内容を返す。

**Response:**
```typescript
{
  metadata: NoteMetadata
  rawMarkdown: string
}
```

**処理フロー:**
```
1. path.join(notesDir, fileName) のファイルを読み込み
2. frontmatterをパース
3. NoteContent として返却
4. ファイルが存在しない → 404
```

**セキュリティ:** `fileName` に `../` が含まれる場合は400を返す。`path.resolve` で正規化後に `notesDir` プレフィックスを確認する。

---

## セッション状態管理

サーバーに状態なし。すべてクライアントのReact Stateで管理する。

```
useSession hook
  state: SessionState
    - theme: string           （クエリパラメータから初期化）
    - messages: Message[]     （[]で開始）
    - isStreaming: boolean     （false）
    - model: string           （config.ollama.modelから取得）

actions:
  - appendUserMessage(content)
  - appendStreamingChunk(chunk)     （ストリーミング中の末尾更新）
  - finalizeAssistantMessage()      （ストリーミング完了）
  - startStreaming()
  - stopStreaming()
```

### セッション終了フロー

```
「終わる」クリック
  ↓
POST /api/generate-markdown（全messages送信）
  ↓
{ markdown, fileName } を受け取る
  ↓
POST /api/save-markdown（markdown + fileName送信）
  ↓
成功 → router.push(`/notes/${fileName}`)
失敗 → エラー表示（ファイルパスを手動表示）
```

---

## Ollamaストリーミング実装

### サーバー側（`/api/chat/route.ts`）

```typescript
// Next.js App Router でのストリーミングレスポンス
export async function POST(request: Request): Promise<Response> {
  const { messages, theme } = await request.json()

  const ollamaStream = await fetchOllamaStream(messages, theme)

  return new Response(ollamaStream, {
    headers: { 'Content-Type': 'text/event-stream' }
  })
}
```

### クライアント側（`useStreamingChat.ts`）

```typescript
// ReadableStreamを読んでstateを更新する
const reader = response.body!.getReader()
const decoder = new TextDecoder()

while (true) {
  const { done, value } = await reader.read()
  if (done) break

  const chunk = decoder.decode(value)
  // Ollamaのストリームはndjson（1行1JSON）
  for (const line of chunk.split('\n').filter(Boolean)) {
    const parsed = JSON.parse(line)
    if (parsed.message?.content) {
      appendChunk(parsed.message.content)
    }
  }
}
```

---

## ファイル名のサニタイズ（`lib/markdown.ts`）

```
YYYYMMDD_HHMMSS_<sanitized>.md

sanitize(theme: string): string
  1. 先頭・末尾の空白を除去
  2. /, \, :, *, ?, ", <, >, |, \n, \r を _ に置換
  3. 連続する _ を 1つに圧縮
  4. 40文字でカット
```

---

## 設定（[C-2修正]）

`.env.local` は Next.js の**起動時にのみ読み込まれる**ため、実行時の書き換えが反映されない。設定変更をアプリ内から行えるよう、ランタイム設定は別ファイルで管理する。

### 優先順位

```
~/diguest/config.json  （最優先・実行時書き換え可能）
  ↓ なければ
.env.local             （開発初期の起動設定）
  ↓ なければ
デフォルト値
```

### `.env.local`（初期デフォルト・gitignore対象）

```bash
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama3
NOTES_DIR=               # 空の場合 ~/diguest/ を使用
```

### `~/diguest/config.json`（実行時設定・自動生成）

```json
{
  "ollamaBaseUrl": "http://localhost:11434",
  "ollamaModel": "llama3",
  "notesDir": "/Users/<username>/diguest"
}
```

`lib/config.ts` が両者を読み込み、`AppConfig` 型として返す。設定画面はこの JSON を読み書きする。

---

## プロンプト設計

### 対話用システムプロンプト（`lib/prompts.ts` / `SYSTEM_PROMPT`）

**[S-2修正]** 「Markdown化する」の記述を削除。Markdown生成は generate-markdown API の2次プロンプトで行うため、対話セッション中のシステムプロンプトに混在させない。

```
あなたはDiguestです。ユーザーの思考を掘り下げる対話相手です。

あなたができること：
- ユーザーの発言に対して深掘りする問いを返すこと
- ユーザーの発言を構造化して反射すること
- 「こういうことを言いたいのかもしれない」という仮説を提示すること

あなたが絶対にしないこと：
- アドバイス・提案・改善案を出すこと
- ユーザーの考えを評価すること（良い・悪いと言わない）
- 「〜しましょう」「〜すべきです」という行動促進
- 情報提供・事実説明・知識の共有

応答は簡潔に。問いは1つずつ。
```

### Markdown生成プロンプト（`lib/prompts.ts` / `MARKDOWN_SUMMARY_PROMPT`）

セッション終了時の2次プロンプト。

```
以下は思考の掘り下げセッションの対話ログです。
テーマ：<theme>

<対話ログ>

上記の対話から、以下の2つを生成してください：

1. 対話の要約（200字以内）
   - ユーザーが何を掘り下げようとしていたかを客観的に記述する
   - アドバイス・評価を含めない

2. 掘り出されたもの（箇条書き）
   - 対話を通じてユーザー自身が言語化できたこと
   - まだ言葉になりかけていること
   - 仮説や問いの形で残ったこと

マークダウンのコードブロックは使わず、純粋なJSONのみを返してください：
{"summary":"...","surfaced":["...","..."]}
```

---

## Server / Client Component 分離方針

**[S-3修正]** Server Component は自分の API Route を HTTP fetch で呼ばない。`lib/` の関数を直接 `import` して呼ぶ。API Route はブラウザ（Client Component）からの呼び出し専用。

| ファイル | 種類 | データ取得方法 |
|---------|------|------|
| `app/page.tsx` | Server | `lib/markdown.ts` の `listNotes()` を直接 import |
| `app/notes/page.tsx` | Server | 同上 |
| `app/notes/[fileName]/page.tsx` | Server | `lib/markdown.ts` の `readNote()` を直接 import |
| `app/session/new/page.tsx` | Client | フォーム操作 |
| `app/session/page.tsx` | Client | ストリーミング・リアルタイム更新 |
| `app/settings/page.tsx` | Client | フォーム操作 |
| `components/DialogueTurn.tsx` | Server可 | 静的レンダリング |
| `components/MarkdownRenderer.tsx` | Server可 | 静的レンダリング |
| `components/StreamingCursor.tsx` | Client | アニメーション |

---

## Tailwind設定方針

`DESIGN_TOKENS.md` のカラー・フォントをTailwindのカスタムテーマに直接マッピングする。

```typescript
// tailwind.config.ts（抜粋）
theme: {
  extend: {
    colors: {
      'bg-base':      '#111009',
      'bg-surface':   '#1A1814',
      'bg-subtle':    '#242018',
      'text-primary': '#EDE8E1',
      'text-secondary': '#7A7468',
      'text-muted':   '#443E38',
      'accent':       '#C4956A',
      'border':       '#2C2820',
      'border-focus': '#5A5040',
    },
    fontFamily: {
      ui:      ['var(--font-inter)', 'Hiragino Sans', 'sans-serif'],
      reading: ['var(--font-noto-serif-jp)', 'Hiragino Mincho ProN', 'serif'],
    },
    maxWidth: {
      content: '680px',
    },
  }
}
```

---

## 制約の担保方法

| 制約 | 担保する場所 |
|------|------------|
| 外部APIなし | `lib/ollama.ts` のベースURL設定のみ。localhost以外は設定で指定しない限り不可 |
| DBなし | `lib/markdown.ts` のみがファイルI/O。DBライブラリは依存に入れない |
| AIはアドバイスしない | `lib/prompts.ts` でシステムプロンプトをサーバー側に固定 |
| 1セッション1md | `save-markdown` APIが呼ばれるのはセッション終了時1回のみ。クライアントのフロー設計で保証 |
