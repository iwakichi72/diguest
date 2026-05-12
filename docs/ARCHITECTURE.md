# Diguest — Macアプリ アーキテクチャ

## 技術スタック

| 層 | 技術 | 理由 |
|----|------|------|
| アプリ | SwiftUI | macOSネイティブの静かなUI、権限、ウィンドウ体験に寄せる |
| 音声入力 | Speech framework + AVFoundation | ブラウザAPIに依存せず、オンデバイス認識を必須化する |
| AIバックエンド | Ollama HTTP API | ローカル完結。外部AI APIなし |
| 永続化 | ローカルファイルシステム | DBなし。Markdownを人間が読める形で残す |
| 設定 | `~/diguest/config.json` | シングルユーザー前提でシンプルに扱える |

## ディレクトリ構成

```text
diguest/
├── Package.swift
├── Resources/
│   └── Info.plist
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
├── scripts/
│   └── build-macos-app.sh
└── docs/
```

## 主要責務

### `AppModel`

画面状態、セッション状態、Ollama呼び出し、Markdown生成、保存、設定反映をまとめるアプリケーション層。SwiftUIの各Viewはここに薄く接続する。

### `OllamaClient`

`/api/tags` で接続確認し、`/api/chat` でストリーミング対話と一括生成を行う。外部AI APIは使わない。

### `SpeechInputController`

`SFSpeechRecognizer.supportsOnDeviceRecognition` を確認し、対応時のみ音声入力を有効化する。認識リクエストは `requiresOnDeviceRecognition = true` を必ず指定する。非対応時にネットワーク認識へフォールバックしない。

### `NoteStore`

Markdown生成、ファイル名生成、保存、一覧、単体読み込みを担当する。保存先は設定値、デフォルトは `~/diguest/`。

### `ConfigStore`

`~/diguest/config.json` を読み書きする。設定項目はOllama URL、モデル、保存先ディレクトリに限定する。

## データフロー

```text
テーマ入力
  ↓
セッション開始
  ↓
ユーザー発言
  ↓
Ollama /api/chat にストリーミング送信
  ↓
Diguestの問い・整理・仮説を表示
  ↓
セッション終了
  ↓
Ollamaで要約JSON生成
  ↓
失敗しても対話ログだけでMarkdown生成
  ↓
保存前プレビュー
  ↓
~/diguest/ にMarkdown保存
```

## 非採用

- Next.js / React / Web APIを本番実行基盤にしない
- ブラウザ音声認識APIを使わない
- DBを持たない
- クラウド同期や外部AI APIを使わない
