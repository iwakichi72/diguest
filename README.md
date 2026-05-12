# Diguest

> 問いで、自分の思考を掘る。

Diguestは、まだ言葉になっていない思考・違和感・問いを掘り起こすためのローカルMacアプリです。AIは答えを急がず、問い、整理し、仮説を提示します。セッションが終わると、対話の全体がMarkdownとして手元に残ります。

## 前提条件

- macOS 13以上
- Xcode / Swift toolchain
- Ollama

Ollamaで使いたいモデルを事前にpullしておきます。

```bash
ollama pull gemma3:4b
# または
ollama pull qwen3:8b
```

## ビルド

```bash
scripts/build-macos-app.sh
open build/Diguest.app
```

開発中に直接ビルドする場合:

```bash
swift build
swift run Diguest
```

## 使い方

1. ホーム画面で「新しく掘る」を選ぶ
2. 今日掘り下げたいテーマや問いを入力する
3. テキスト、または対応環境では音声入力で話す
4. `Command+Return` または「置く」で発言する
5. 「ここで終える」からMarkdownを生成して保存する

音声入力はmacOSの `Speech` frameworkを使います。`SFSpeechRecognizer.supportsOnDeviceRecognition` が `true` の環境でだけ有効になり、認識リクエストには `requiresOnDeviceRecognition = true` を指定します。対応していない環境では、ネットワーク認識へフォールバックせずテキスト入力のみになります。

## 保存先

セッションは `~/diguest/` にMarkdownファイルとして保存されます。

```text
~/diguest/
└── 20260512_201822_最近の違和感.md
```

ファイル名は `YYYYMMDD_HHMMSS_テーマ.md` の形式です。

## 設定

アプリ内の設定画面、または `~/diguest/config.json` で設定できます。

```json
{
  "ollamaBaseUrl": "http://localhost:11434",
  "ollamaModel": "gemma3:4b",
  "notesDir": "~/diguest"
}
```

## 注意事項

- すべての処理はローカルで完結します。
- 外部AI APIやクラウド保存は使いません。
- Ollamaが起動していない場合は、先に `ollama serve` を実行してください。
