# Diguest — プロジェクトまとめ

## 概要

Diguestは、まだ言葉になっていない思考・違和感・問いを掘り起こすためのローカルMacアプリです。

AIは答えを急がず、ユーザーの言葉に対して問い、整理、仮説を返します。セッションが終わると、対話全体はMarkdownとして `~/diguest/` に保存されます。

## 現在の方針

Webアプリ版は廃止し、SwiftUIネイティブMacアプリを本線にしています。

- Next.js / React / browser API は使わない
- OllamaへMacアプリから直接接続する
- Markdownはローカルファイルとして保存する
- 音声入力はmacOS Speech frameworkのオンデバイス認識のみ使う
- オンデバイス認識が使えない場合、ネットワーク認識へフォールバックしない

## プロダクト原則

- Diguestはチャットアプリではなく、静かな内省の場所
- AIはアシスタントではなく、問い手であり、書き手
- ダッシュボード、統計、ストリーク、バッジは置かない
- 吹き出し、アバター、提案チップのようなチャットUIへ寄せない
- 1セッションは1つのMarkdownファイルとして残す
- 過去ノートをAIが自動参照しない
- 外部AI APIやクラウド保存を使わない

## 現在のフォルダ構成

```text
diguest/
├── Package.swift
├── Sources/
│   └── Diguest/
│       ├── DiguestApp.swift
│       ├── AppModel.swift
│       ├── ContentView.swift
│       ├── HomeView.swift
│       ├── ThemeEntryView.swift
│       ├── SessionView.swift
│       ├── PreviewView.swift
│       ├── NoteView.swift
│       ├── SettingsView.swift
│       ├── OllamaClient.swift
│       ├── SpeechInputController.swift
│       ├── NoteStore.swift
│       ├── ConfigStore.swift
│       ├── Prompts.swift
│       └── Models.swift
├── Resources/
│   └── Info.plist
├── scripts/
│   └── build-macos-app.sh
├── docs/
└── README.md
```

## 主要コンポーネント

| ファイル | 役割 |
|---|---|
| `DiguestApp.swift` | SwiftUIアプリのエントリポイント |
| `AppModel.swift` | 画面状態、セッション状態、Ollama呼び出し、Markdown生成保存を統括 |
| `OllamaClient.swift` | Ollama HTTP APIとの接続、ストリーミング受信、要約生成 |
| `SpeechInputController.swift` | Apple Speechのオンデバイス音声入力 |
| `NoteStore.swift` | Markdown生成、保存、一覧、読み込み |
| `ConfigStore.swift` | `~/diguest/config.json` の読み書き |
| `Prompts.swift` | Diguestのシステムプロンプト、要約プロンプト |
| `SessionView.swift` | 対話画面 |
| `PreviewView.swift` | 保存前Markdownプレビュー |

## 体験フロー

```text
起動
  ↓
ホーム画面
  ↓
テーマ入力
  ↓
セッション開始
  ↓
ユーザーが書く、または話す
  ↓
Ollamaが問い・整理・仮説をストリーミングで返す
  ↓
「ここで終える」
  ↓
Markdown生成
  ↓
保存前プレビュー
  ↓
ローカル保存
  ↓
ノート再読
```

## 保存仕様

デフォルト保存先:

```text
~/diguest/
```

ファイル名:

```text
YYYYMMDD_HHMMSS_テーマ.md
```

Markdownには以下を含めます。

- frontmatter
- 対話の要約
- 掘り出されたもの
- 対話ログ

要約生成に失敗しても、対話ログだけは保存できる設計です。

## 設定

設定ファイル:

```text
~/diguest/config.json
```

例:

```json
{
  "ollamaBaseUrl": "http://localhost:11434",
  "ollamaModel": "gemma3:4b",
  "notesDir": "~/diguest"
}
```

## ビルドと起動

開発ビルド:

```bash
swift build
```

アプリバンドル生成:

```bash
scripts/build-macos-app.sh
```

起動:

```bash
open build/Diguest.app
```

## 現在できていること

- SwiftUIネイティブMacアプリ化
- Ollama接続確認
- Ollama `/api/chat` へのストリーミング対話
- テーマ入力
- セッション画面
- テキスト入力
- Apple Speech on-device音声入力
- Markdown生成
- 保存前プレビュー
- Markdown保存
- 保存済みノートの一覧と単体表示
- 設定画面
- Web版コード削除
- ルートSwift Package構成への整理

## 未確認・次にやること

- GUI実機確認
  - 初回マイク権限
  - 初回音声認識権限
  - 音声入力の開始/停止
  - Ollama未起動時の表示
  - 保存後のノート表示
- セッション中の下書き保護
- frontmatterのYAML安全性向上
- アプリアイコン
- 署名・notarization方針
- whisper.cpp同梱の検討

## 関連ドキュメント

- `docs/PRODUCT.md` — プロダクト定義
- `docs/UI_BRIEF.md` — UI思想
- `docs/ARCHITECTURE.md` — 技術構成
- `docs/MVP_SPEC.md` — MVP仕様
- `docs/ACCEPTANCE_CRITERIA.md` — 受け入れ条件
- `docs/TASKS.md` — 実装タスク
- `docs/ROADMAP.md` — ロードマップ
