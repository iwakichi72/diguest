# Diguest — アーキテクチャ設計

## 技術スタック

| 層 | 技術 | 理由 |
|----|------|------|
| フレームワーク | Next.js 16 (App Router) | Server/Client Component分離でFile I/Oを安全に扱える |
| 言語 | TypeScript | 型安全。API境界の誤用を防ぐ |
| スタイリング | Tailwind CSS 4 | `app/globals.css` でDESIGN_TOKENS.mdの値をテーマ化 |
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
│   │   ├── client.tsx                # 対話画面のClient Component本体
│   │   ├── new/
│   │   │   └── page.tsx              # テーマ入力画面（Client Component）
│   │   └── page.tsx                  # 対話画面（?theme=...）
│   ├── notes/
│   │   └── [fileName]/
│   │       └── page.tsx              # Markdownプレビュー（Server Component）
│   └── api/
│       ├── health/
│       │   └── route.ts              # GET /api/health（Ollama接続確認）
│       ├── chat/
│       │   └── route.ts              # POST /api/chat（ストリーミング）
│       ├── generate-markdown/
│       │   └── route.ts              # POST /api/generate-markdown
│       ├── save-markdown/
│       │   └── route.ts              # POST /api/save-markdown
│       └── config/
│           └── route.ts              # GET /api/config（現在はnotesDir取得）
├── lib/
│   ├── config.ts                     # 設定値（env）の読み込みと型定義
│   ├── ollama.ts                     # Ollama HTTPクライアント
│   ├── markdown.ts                   # Markdown生成・ファイル操作・frontmatter解析
│   └── prompts.ts                    # システムプロンプト定数
├── components/
│   ├── DialogueTurn.tsx              # 1ターン分の表示（user/diguest）
│   ├── StreamingCursor.tsx           # 点滅カーソル（ストリーミング中）
│   ├── MarkdownPreview.tsx           # 保存前Markdownプレビュー
│   └── CopyButton.tsx                # Markdownコピー
├── hooks/
│   ├── useSession.ts                 # セッション状態（messages, theme, isStreaming）
│   └── useStreamingChat.ts           # ストリーミングfetchフック
├── types/
│   └── index.ts                      # 共通型定義
├── .env.local                        # 設定（gitignore対象）
├── postcss.config.mjs
└── next.config.ts
```

上記は現在のWebUI版実装を基準にした構成。`/notes` の月別一覧、`/settings` 画面、`app/api/notes` はMVP後の候補として扱う。

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
/notes/[fileName]    → Markdownプレビュー（Server Component）
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

**Response:** `ReadableStream`（`application/x-ndjson; charset=utf-8`）

**処理フロー:**
```
1. システムプロンプト + messages を結合
2. Ollama POST /api/chat にストリーミングリクエスト
3. Ollamaのストリームをそのままクライアントに流す
4. Ollamaが未起動の場合 → 503 + エラーJSON
```

**重要:** システムプロンプトはクライアントから渡さない。サーバー側で `lib/prompts.ts` から注入。これにより「助言を主目的にしない」基本姿勢をクライアント操作で迂回しにくくする。

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

### GET `/api/health`

Ollama接続確認を行う。対話画面の初期表示時に呼び出し、未起動の場合はセッション画面にエラーを出す。

**Response:**
```typescript
{
  ok: true
}
```

**処理フロー:**
```
1. configからOllama base URLを取得
2. GET /api/tags に3秒タイムアウトで接続
3. 成功 → 200
4. 失敗 → 503 + エラーJSON
```

---

### GET `/api/config`

現在はローカル設定のうち `notesDir` を返す。設定の編集・保存はMVP補強の候補として扱う。

**Response:**
```typescript
{
  notesDir: string
}
```

---

## ノート読み込み設計

保存済みノートの一覧・読み込みは、現状ではAPI RouteではなくServer Componentから `lib/markdown.ts` を直接呼び出す。

```
app/page.tsx
  -> listNotes()

app/notes/[fileName]/page.tsx
  -> readNote(fileName)
```

File I/Oをサーバー側に閉じることで、ブラウザからローカルファイルシステムへ直接アクセスしない。

**処理フロー:**
```
1. fileNameをpath.basenameで正規化
2. path.resolve後にnotesDir配下であることを確認
3. ファイルを読み込み
4. frontmatterをパース
5. NoteContent として返す
6. 不正パス・ファイルなし・frontmatter不正 → notFound()
```

**セキュリティ:** `path.resolve` で正規化後に `notesDir` プレフィックスを確認する。

---

## セッション状態管理

サーバーにセッション状態は持たない。対話中の状態はクライアントのReact Stateで管理する。

```
useSession hook
  state: SessionState
    - theme: string
    - messages: Message[]
    - isStreaming: boolean
    - model: string

actions:
  - addUser(content)
  - startAssistant()
  - appendChunk(chunk)
  - finalize()
  - removeLastAssistant()
```

### セッション終了フロー

```
「ここで終える」クリック
  ↓
POST /api/generate-markdown（theme, messages, startedAt）
  ↓
{ markdown, fileName } を受け取る
  ↓
保存前Markdownプレビューを表示
  ↓
「保存する」
  ↓
POST /api/save-markdown（markdown + fileName）
  ↓
成功 → router.push(`/notes/${savedFileName}`)
失敗 → エラー表示
```

---

## Ollamaストリーミング実装

### サーバー側（`/api/chat/route.ts`）

```typescript
export async function POST(request: Request) {
  const body = await request.json()
  const withSystem = [
    { role: 'system', content: SYSTEM_PROMPT },
    ...body.messages.filter(m => m.role !== 'system'),
  ]

  const stream = await streamChat(withSystem)
  return new Response(stream, {
    headers: { 'Content-Type': 'application/x-ndjson; charset=utf-8' },
  })
}
### クライアント側（`useStreamingChat.ts`）

```typescript
const reader = response.body!.getReader()
const decoder = new TextDecoder()
let buffer = ''

while (true) {
  const { done, value } = await reader.read()
  if (done) break

  buffer += decoder.decode(value, { stream: true })
  const lines = buffer.split('\n')
  buffer = lines.pop() ?? ''

  for (const line of lines) {
    if (!line.trim()) continue
    const parsed = JSON.parse(line)
    if (parsed.message?.content) onChunk(parsed.message.content)
    if (parsed.done) break
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

あなたの基本姿勢：
- ユーザーの発言に対して深掘りする問いを返すこと
- ユーザーの発言を構造化して反射すること
- 「こういうことを言いたいのかもしれない」という仮説を提示すること

あなたが主目的にしないこと：
- アドバイス・提案・改善案を次々に出すこと
- ユーザーの考えを良い・悪いで裁くこと
- 行動を急がせること
- 情報提供だけで応答を終えること

必要な場合は、短い示唆や確認を添えてよい。ただし、ユーザー自身の言葉を引き出すことを優先する。

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
   - アドバイスや評価を中心にしない

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
| `app/notes/[fileName]/page.tsx` | Server | `lib/markdown.ts` の `readNote()` を直接 import |
| `app/session/new/page.tsx` | Client | フォーム操作 |
| `app/session/page.tsx` | Server | `Suspense` で `SessionClient` を包む |
| `app/session/client.tsx` | Client | ストリーミング・リアルタイム更新 |
| `components/DialogueTurn.tsx` | Server可 | 静的レンダリング |
| `components/MarkdownPreview.tsx` | Client | 保存前プレビューの操作 |
| `components/CopyButton.tsx` | Client | Clipboard API |
| `components/StreamingCursor.tsx` | Client | アニメーション |

`/notes` と `/settings` はMVP補強で追加する候補。

---

## Tailwind設定方針

Tailwind CSS 4のCSS-first設定を使い、`app/globals.css` の `@theme` に `DESIGN_TOKENS.md` のカラー・フォントをマッピングする。

```css
@import "tailwindcss";

@theme {
  --color-bg-base: #111009;
  --color-bg-surface: #1a1814;
  --color-bg-subtle: #242018;
  --color-text-primary: #ede8e1;
  --color-text-secondary: #7a7468;
  --color-text-muted: #443e38;
  --color-accent: #c4956a;
  --color-border: #2c2820;
  --color-border-focus: #5a5040;

  --font-ui: var(--font-inter), "Hiragino Sans", system-ui, sans-serif;
  --font-reading: var(--font-noto-serif), "Hiragino Mincho ProN", serif;
}

@utility max-w-content {
  max-width: 680px;
}
```

---

## 制約の担保方法

| 制約 | 担保する場所 |
|------|------------|
| 外部APIなし | `lib/ollama.ts` のベースURL設定のみ。localhost以外は設定で指定しない限り不可 |
| DBなし | `lib/markdown.ts` のみがファイルI/O。DBライブラリは依存に入れない |
| AIは助言を主目的にしない | `lib/prompts.ts` でシステムプロンプトをサーバー側に固定 |
| 1セッション1md | `save-markdown` APIが呼ばれるのはセッション終了時1回のみ。クライアントのフロー設計で保証 |
