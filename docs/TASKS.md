# Diguest — 実装タスクリスト

優先度はPlanner推奨のP0→P3順。各タスクは独立して完結するように粒度を設定している。

---

## Phase 0: プロジェクトセットアップ

- [ ] **P0-1** `create-next-app` でプロジェクト初期化（TypeScript + Tailwind + App Router）
- [ ] **P0-2** `types/index.ts` — 共通型定義（Message, SessionState, NoteMetadata, AppConfig 等）
- [ ] **P0-3** `tailwind.config.ts` — DESIGN_TOKENS.md のカラー・フォントをカスタムテーマに追加
- [ ] **P0-4** `app/layout.tsx` — next/font でInter + Noto Serif JP を設定、ダークモードデフォルト
- [ ] **P0-5** `.env.local` — OLLAMA_BASE_URL, OLLAMA_MODEL, NOTES_DIR のデフォルト値を設定
- [ ] **P0-6** `lib/config.ts` — env読み込みとデフォルトフォールバック

---

## Phase 1: コアAPI（動作の核心）

### lib層

- [ ] **P1-1** `lib/prompts.ts` — 対話用システムプロンプト定数（日本語）
- [ ] **P1-2** `lib/prompts.ts` — Markdown生成用2次プロンプト定数
- [ ] **P1-3** `lib/ollama.ts` — Ollama `/api/chat` ストリーミング呼び出し関数
- [ ] **P1-4** `lib/ollama.ts` — Ollama `/api/chat` 非ストリーミング呼び出し関数（要約生成用）
- [ ] **P1-5** `lib/ollama.ts` — Ollama接続確認関数（ping: GET /api/tags）
- [ ] **P1-6** `lib/markdown.ts` — ファイル名サニタイズ関数（特殊文字置換・40文字カット）
- [ ] **P1-7** `lib/markdown.ts` — Markdownドキュメント組み立て関数（frontmatter + セクション + ログ）
- [ ] **P1-8** `lib/markdown.ts` — frontmatterパース関数（`---`ブロックの解析）
- [ ] **P1-9** `lib/markdown.ts` — ノートディレクトリ操作（mkdir, writeFile, readFile, readdir）

### API Routes

- [ ] **P1-10** `app/api/chat/route.ts` — POSTハンドラー。メッセージ受取 → システムプロンプト注入 → Ollamaストリームを返す
- [ ] **P1-11** `app/api/chat/route.ts` — Ollama未起動時に503を返す
- [ ] **P1-12** `app/api/generate-markdown/route.ts` — POSTハンドラー。要約生成 → Markdown組み立て → `{markdown, fileName}`返却
- [ ] **P1-13** `app/api/generate-markdown/route.ts` — 要約生成失敗時のフォールバック（空セクションで継続）
- [ ] **P1-14** `app/api/save-markdown/route.ts` — POSTハンドラー。受け取ったMarkdownをファイル書き込み
- [ ] **P1-15** `app/api/save-markdown/route.ts` — notesDir が存在しない場合は自動作成
- [ ] **P1-16** `app/api/notes/route.ts` — GETハンドラー。notesDir列挙 → frontmatterパース → date降順返却
- [ ] **P1-17** `app/api/notes/route.ts` — notesDir非存在時は空配列返却（エラーにしない）
- [ ] **P1-18** `app/api/notes/[fileName]/route.ts` — GETハンドラー。ファイル読込 → frontmatterパース → 返却
- [ ] **P1-19** `app/api/notes/[fileName]/route.ts` — パストラバーサル防止（`../`検出 → 400）
- [ ] **P1-20** `app/api/notes/[fileName]/route.ts` — ファイル非存在 → 404

---

## Phase 2: セッションUI

### hooks

- [ ] **P2-1** `hooks/useStreamingChat.ts` — fetch → ReadableStream読み取り → チャンクをstate更新するフック
- [ ] **P2-2** `hooks/useStreamingChat.ts` — ストリーミング完了・エラー時のコールバック
- [ ] **P2-3** `hooks/useSession.ts` — SessionState管理（useReducer）
- [ ] **P2-4** `hooks/useSession.ts` — appendUserMessage / appendStreamingChunk / finalizeAssistantMessage アクション

### components

- [ ] **P2-5** `components/DialogueTurn.tsx` — ユーザーターン表示（通常テキスト・左揃え）
- [ ] **P2-6** `components/DialogueTurn.tsx` — Diguestターン表示（斜体・破線ルール）
- [ ] **P2-7** `components/StreamingCursor.tsx` — 点滅カーソルアニメーション（スピナーなし）

### pages

- [ ] **P2-8** `app/session/new/page.tsx` — テーマ入力フォーム（Enter送信・空白時ボタン無効）
- [ ] **P2-9** `app/session/new/page.tsx` — `/session?theme=<encoded>` へのナビゲーション
- [ ] **P2-10** `app/session/page.tsx` — searchParamsからtheme取得・SessionState初期化
- [ ] **P2-11** `app/session/page.tsx` — 対話ループ（ユーザー入力 → POST /api/chat → ストリーミング表示）
- [ ] **P2-12** `app/session/page.tsx` — テキストエリア自動リサイズ（最小2行・最大6行）
- [ ] **P2-13** `app/session/page.tsx` — Shift+Enter 改行 / Enter 送信
- [ ] **P2-14** `app/session/page.tsx` — ストリーミング中は入力無効化
- [ ] **P2-15** `app/session/page.tsx` — 新ターン追加時に自動スクロール（scrollIntoView）
- [ ] **P2-16** `app/session/page.tsx` — 「終わる」ボタン → generate-markdown → save-markdown → /notes/[fileName] へ遷移
- [ ] **P2-17** `app/session/page.tsx` — Ollama未起動エラー表示（UI Brief のコピー通り）

---

## Phase 3: ノートUI

### components

- [ ] **P3-1** `components/NoteRow.tsx` — 日付（日のみ）＋テーマの1行。ホバーでbg-subtle
- [ ] **P3-2** `components/MarkdownRenderer.tsx` — rawMarkdownをHTMLにレンダリング（`react-markdown` または `marked`）
- [ ] **P3-3** `components/MarkdownRenderer.tsx` — Noto Serif JP でのレンダリング（読むモード）

### pages

- [ ] **P3-4** `app/notes/page.tsx` — GET /api/notes → 月ごとグルーピング → NoteRow一覧
- [ ] **P3-5** `app/notes/page.tsx` — ノート0件時の空状態表示（COPY_GUIDE参照）
- [ ] **P3-6** `app/notes/[fileName]/page.tsx` — GET /api/notes/[fileName] → メタ情報 + MarkdownRenderer
- [ ] **P3-7** `app/notes/[fileName]/page.tsx` — 「Markdownをコピー」ボタン（コピー後ラベル変更）
- [ ] **P3-8** `app/notes/[fileName]/page.tsx` — 「エディタで開く」（POST /api/open-file または href="file://"）

---

## Phase 4: ホーム・設定

- [ ] **P4-1** `app/page.tsx` — ホーム画面（「新しいセッションを始める」CTA + 直近ノート5件）
- [ ] **P4-2** `app/page.tsx` — Server ComponentとしてGET /api/notes を直接呼び出し
- [ ] **P4-3** `app/settings/page.tsx` — OllamaモデルとノートDir設定フォーム
- [ ] **P4-4** `app/settings/page.tsx` — 設定の保存（`.env.local` 書き換えまたはruntime configファイル）

---

## Phase 5: 仕上げ

- [ ] **P5-1** 全画面にフェードインアニメーション（200ms）
- [ ] **P5-2** ページ遷移時の`<Link>`プリフェッチ設定
- [ ] **P5-3** Ollamaモデル別の応答速度に合わせた体感調整（初回応答が遅い場合の沈黙演出）
- [ ] **P5-4** ファイル名の日本語エンコードが正しくURL/パス変換されることを確認
- [ ] **P5-5** `next.config.ts` — ローカルファイルシステムアクセスの設定（experimental.serverActions等）
- [ ] **P5-6** Acceptance Criteriaの各項目を手動確認

---

## 依存パッケージ一覧

```json
{
  "dependencies": {
    "next": "^15",
    "react": "^19",
    "react-dom": "^19",
    "react-markdown": "^9"
  },
  "devDependencies": {
    "typescript": "^5",
    "@types/node": "^20",
    "@types/react": "^19",
    "tailwindcss": "^3",
    "postcss": "^8",
    "autoprefixer": "^10"
  }
}
```

`react-markdown` のみが唯一の追加依存。DBクライアント・外部SDKは入れない。

---

## 実装順序の補足

**P1-10〜P1-20（API Routes）はPhase 2のUIより先に完成させる。**  
APIがないとUIのhooksが動かない。APIを先に作ってcurl/fetchで単体確認してからUIに進む。

**Phase 2のP2-8〜P2-11は連番で実装する。**  
テーマ入力 → 対話 → 終了のフローが完結しないとE2E確認ができないため。

**P3-8（エディタで開く）は後回し可。**  
macOSの`open`コマンドを使うが、ファイルプロトコルでのブラウザ動作に制約がある。先にコア機能を完成させる。
