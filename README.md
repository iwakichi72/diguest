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
  "ollamaModel": "gemma4:e4b",
  "notesDir": "~/diguest",
  "enableDigAnimation": true,
  "digAnimationIntensity": "normal"
}
```

`enableDigAnimation` と `digAnimationIntensity` は省略しても動作します（既存の `config.json` との互換性を保つため、未指定時はそれぞれ `true` / `"normal"` が使われます）。

## 掘削の演出

セッション中、AIが問い返すたびに「地表 → 柔らかい土 → 根 → 堆積層 → 岩盤 → 結晶層 → 深層」と背景の地層と画面端の深度メーター (`Depth 04 / Roots Layer` 等) が進みます。通常の問い返しは +1、`なぜ` / `どうして` / `本当に` などの核心寄りの語が含まれる問い返しは +2 と、踏み込みの強さで進む幅が変わります。

`digAnimationIntensity` は `minimal` / `normal` / `rich` から選べます。設定画面のスイッチで完全に無効化することもできます。macOSの「視差効果を減らす」(Reduce Motion) を有効にしている場合は、揺れ・粒子・微細な動きが自動的に抑えられます。

## 注意事項

- すべての処理はローカルで完結します。
- 外部AI APIやクラウド保存は使いません。
- Ollamaが起動していない場合は、先に `ollama serve` を実行してください。
