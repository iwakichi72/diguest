# Diguest — Acceptance Criteria

## AC-01: アプリ起動

**Given** `build/Diguest.app` が存在する  
**When** アプリを開く  
**Then** ホーム画面が表示される

## AC-02: Ollama接続

**Given** Ollamaが `localhost:11434` で起動している  
**When** 設定画面または起動時に接続確認する  
**Then** 接続中として表示される

**Given** Ollamaが起動していない  
**When** 接続確認する  
**Then** 「Ollamaが見つかりません」と分かる表示になる

## AC-03: セッション開始

**Given** ホーム画面を表示している  
**When** テーマを入力してセッションを開始する  
**Then** 対話画面へ移動する

## AC-04: 対話の継続

**Given** セッション中である  
**When** ユーザーが発言する  
**Then** Diguestは問い・整理・仮説提示のいずれかを中心にストリーミング応答する

## AC-05: 音声入力

**Given** macOSのオンデバイス音声認識が利用できる  
**When** マイクボタンを押す  
**Then** 認識結果が入力欄へ下書きとして入る

**Given** オンデバイス音声認識が利用できない  
**When** セッション画面を表示する  
**Then** ネットワーク認識へフォールバックせず、テキスト入力のみで使える

## AC-06: セッション終了とMarkdown保存

**Given** 対話中である  
**When** 「ここで終える」を選ぶ  
**Then** Markdownプレビューが表示される

**Given** Markdownプレビューを表示している  
**When** 「保存する」を選ぶ  
**Then** `~/diguest/` または設定された保存先にMarkdownファイルが保存される

## AC-07: Markdownの内容

**Given** セッションが保存された  
**When** 生成されたMarkdownファイルを開く  
**Then** frontmatter、対話の要約、掘り出されたもの、対話ログが含まれる

## AC-08: 要約失敗時の保護

**Given** Ollamaの要約生成が失敗する  
**When** セッションを終了する  
**Then** 対話ログだけでもMarkdownとして保存できる

## AC-09: 設定

**Given** 設定画面を開いている  
**When** Ollama URL、モデル、保存先を変更して保存する  
**Then** `~/diguest/config.json` に反映される
