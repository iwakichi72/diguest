# Diguest

> 問いで、自分の思考を掘る。

AIと対話しながら、まだ言葉になっていない思考・違和感・問いを掘り起こすローカルツールです。AIは答えを急がず、問い、整理し、仮説を提示します。必要なときだけ控えめな示唆を添えます。セッションが終わると、対話の全体がMarkdownとして手元に残ります。

---

## 前提条件

- **Node.js** 18以上
- **Ollama** — [ollama.com](https://ollama.com) からインストール

Ollamaで使いたいモデルを事前にpullしておきます：

```bash
ollama pull gemma3:4b
# または
ollama pull qwen3:8b
```

---

## セットアップ

```bash
# 1. リポジトリをクローン
git clone <repo-url>
cd diguest

# 2. 依存パッケージをインストール
npm install

# 3. 環境変数ファイルを作成
cp .env.local.example .env.local
```

`.env.local` を開き、使いたいモデル名を設定します：

```bash
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=gemma3:4b
```

```bash
# 4. 開発サーバーを起動
npm run dev
```

ブラウザで [http://localhost:3000](http://localhost:3000) を開きます。

---

## 使い方

**1. セッションを始める**

ホーム画面で「掘り始める」をクリックし、今日掘り下げたいテーマや問いを入力します。一言でも、問いの形でも構いません。

**2. 対話する**

AIが問いを返します。思ったことをそのまま書いてください。Enter で送信、Shift+Enter で改行します。

**3. 終える**

「ここで終える」をクリックすると、AIが対話の要約と掘り出されたものを生成します。内容を確認して「保存する」を押すと、Markdownとして保存されます。

---

## 保存先

セッションは `~/diguest/` に Markdown ファイルとして保存されます：

```
~/diguest/
└── 20250510_143022_最近の違和感.md
```

ファイル名は `YYYYMMDD_HHMMSS_テーマ.md` の形式です。

---

## 設定

環境変数または `~/diguest/config.json` で設定できます。

| 設定 | 環境変数 | デフォルト |
|------|----------|-----------|
| OllamaのURL | `OLLAMA_BASE_URL` | `http://localhost:11434` |
| 使用モデル | `OLLAMA_MODEL` | `gemma4:e4b` |
| 保存先ディレクトリ | `NOTES_DIR` | `~/diguest/` |

`~/diguest/config.json` は環境変数より優先されます（サーバー再起動不要）：

```json
{
  "ollamaBaseUrl": "http://localhost:11434",
  "ollamaModel": "qwen3:8b",
  "notesDir": "/Users/yourname/notes/diguest"
}
```

---

## 注意事項

- すべての処理はローカルで完結します。外部APIへの通信はありません。
- 対話の内容はサーバーに保存されません。ファイルは手元のマシンにのみ残ります。
- Ollamaが起動していない状態でセッションを開始すると、エラーが表示されます。先に `ollama serve` を実行してください。
