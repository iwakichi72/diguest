# Choice-First Digging Implementation Plan

## Goal

Implement the choice-first digging flow from `docs/superpowers/specs/2026-05-13-choice-first-digging-design.md`.

The app should default to quick selection instead of long-form writing:

- Diguest returns one question and four answer options.
- The first three options are user-thought hypotheses.
- The fourth option is always `近いものがないので書く`.
- Selecting an option continues the session.
- After the first seed input, writing remains available only for the fourth option or for editing a near-match selection.
- Markdown keeps the question, options, and user answer readable.

## Constraints

- Keep the implementation SwiftUI/macOS only.
- Keep all AI calls local through Ollama.
- Do not add web, React, Next.js, browser APIs, cloud storage, or external AI APIs.
- Do not introduce chat bubbles, avatars, dashboards, streaks, badges, or colorful suggestion chips.
- Keep Markdown durable and understandable as plain text.
- Keep speech input on-device only.

## Current Code Touchpoints

- `Sources/Diguest/Models.swift`
  Add typed structures for choice turns and answer modes.

- `Sources/Diguest/Prompts.swift`
  Update the system prompt to request structured choice responses, and keep summary generation aligned with selected answers.

- `Sources/Diguest/AppModel.swift`
  Manage the selected option flow, parse structured assistant output, support manual writing mode, and keep messages/turns in sync.

- `Sources/Diguest/SessionView.swift`
  Render a quiet numbered choice list, expose manual writing only when needed, and preserve the current reading-oriented session layout.

- `Sources/Diguest/NoteStore.swift`
  Update Markdown generation so choice turns are recorded clearly.

- `docs/ACCEPTANCE_CRITERIA.md`
  Add acceptance criteria for four-option responses, option selection, fallback writing, edited near matches, and malformed model output.

## Implementation Slice 1: Turn Data Model

Add small model types before changing UI behavior.

Proposed types:

```swift
struct ChoiceTurn: Identifiable, Equatable {
    let id: UUID
    var question: String
    var options: [ChoiceOption]
    var rawAssistantText: String
    var answer: ChoiceAnswer?
}

struct ChoiceOption: Identifiable, Equatable {
    let id: UUID
    var index: Int
    var text: String
    var isFreeWrite: Bool
}

enum ChoiceAnswer: Equatable {
    case selected(index: Int, text: String)
    case edited(originalIndex: Int, originalText: String, editedText: String)
    case freeWritten(String)
}

struct ChoiceResponsePayload: Codable {
    let question: String
    let options: [String]
}
```

Implementation notes:

- Normalize every assistant response to four options.
- Keep only three model-generated options.
- Always force option 4 to `近いものがないので書く`.
- Preserve `rawAssistantText` for fallback/debugging.
- Keep existing `Message` for chat history sent to Ollama, but use `ChoiceTurn` for rendering and Markdown.

## Implementation Slice 2: Prompt and Parsing

Change the system prompt so normal Diguest responses return parseable JSON.

Target response shape:

```json
{
  "question": "いま引っかかっているのは、どれに近いですか？",
  "options": [
    "まだ言葉にならない引っかかり",
    "期待と現実がずれている感じ",
    "誰かの基準に寄せている感じ"
  ]
}
```

Prompt requirements:

- Return pure JSON for normal session turns.
- Produce exactly one question.
- Produce three content options.
- Do not include the free-writing option in model output; the app owns option 4.
- Do not produce advice, diagnosis, action plans, scores, or evaluation.
- Use short options by default, sentence-like hypotheses only when nuance matters.

Parsing behavior:

- Extract the first JSON object from the response.
- Decode `ChoiceResponsePayload`.
- Trim empty strings.
- If parsing succeeds, create a normalized `ChoiceTurn`.
- If parsing fails, show the assistant text as a plain question and enter manual writing mode.

## Implementation Slice 3: App State and Session Flow

Add published state to `AppModel`:

- `choiceTurns: [ChoiceTurn]`
- `activeTurnID: UUID?`
- `answerDraft: String`
- `manualAnswerMode: ManualAnswerMode?`

Suggested enum:

```swift
enum ManualAnswerMode: Equatable {
    case freeWrite
    case edit(optionIndex: Int, originalText: String)
}
```

Flow changes:

1. Session starts with no turn and an empty editor.
2. User's first free input remains necessary to seed the session.
3. Diguest generates a structured `ChoiceTurn`.
4. When the user selects one of options 1-3:
   - Record `.selected`.
   - Append a user `Message` that clearly says `選択: N. ...`.
   - Generate the next `ChoiceTurn`.
5. When the user chooses option 4:
   - Enter `.freeWrite` mode.
   - Show the text editor and speech input.
   - On submit, record `.freeWritten`.
   - Append a user `Message` that clearly says `自由記述: ...`.
   - Generate the next `ChoiceTurn`.
6. When the user edits a near match:
   - Enter `.edit`.
   - Pre-fill the editor with the selected option text.
   - On submit, record `.edited`.
   - Append a user `Message` that clearly says `編集した選択: ...`.
   - Generate the next `ChoiceTurn`.

The first session input can keep the current free-writing UI. After the first assistant turn, selection becomes the main path.

## Implementation Slice 4: Session UI

Update `SessionView` without turning it into a chat UI.

Required UI pieces:

- `ChoiceTurnBlock`
  Shows Diguest's question with the existing assistant typography and rule treatment.

- `ChoiceOptionList`
  Shows four quiet numbered rows below the question.

- `ChoiceOptionRow`
  Uses subdued borders/rules and text, not colorful chips.

- `ManualAnswerEditor`
  Reuses the current text editor and speech button, but appears only for:
  - the initial user seed input
  - option 4 free writing
  - editing a near-match option

Keyboard behavior:

- `Command+Return` submits manual writing when the editor is visible.
- Number shortcuts may be deferred. They are useful, but not required for MVP.

Interaction detail for editing:

- Selecting an option can immediately continue.
- Add a small quiet secondary action such as `少し直して掘る` for the selected option.
- Implement editing after the main selection/free-writing loop is stable, but keep it inside this feature's definition of done.

## Implementation Slice 5: Markdown

Update Markdown generation so the log remains readable.

Preferred output for each choice turn:

```markdown
**Diguest:**

問い: それはどんな違和感に近いですか？

選択肢:
1. まだ言葉にならない引っかかり
2. 期待と現実がずれている感じ
3. 誰かの基準に寄せている感じ
4. 近いものがないので書く

**You:**

選択: 1. まだ言葉にならない引っかかり
```

Do not remove the current frontmatter, summary, surfaced list, or generated footer.

Summary input should use the readable choice log, not only raw selected labels, so Ollama can summarize the session accurately.

## Implementation Slice 6: Acceptance Criteria and Docs

Update `docs/ACCEPTANCE_CRITERIA.md`:

- Replace or revise AC-04 so normal responses are choice-first.
- Add criteria for selecting one of the first three choices.
- Add criteria for choosing option 4 and writing manually.
- Add criteria for edited near-match answers.
- Add criteria for malformed structured output fallback.
- Keep speech, save, summary failure, settings, and local-first criteria unchanged.

## Testing Plan

Run after implementation:

1. `make build`
   Verify the Swift package/app compiles.

2. `make test`
   Run if available. If no tests exist, record that explicitly.

3. Manual app check with Ollama running:
   - Start a session.
   - Enter the first seed answer.
   - Confirm Diguest shows one question and four options.
   - Select option 1, confirm the next turn generates.
   - Choose option 4, write manually, confirm the next turn generates.
   - Save the session and inspect Markdown.

4. Manual malformed-output check:
   - Temporarily force parsing to fail or use a malformed sample in a local helper path.
   - Confirm the app falls back to manual writing instead of blocking.

## Risk Management

- Parsing streamed JSON can be fragile.
  Mitigation: accumulate the assistant response as text, parse only after streaming completes.

- The model may include the fourth free-writing option itself.
  Mitigation: ignore model options after the first three and force app-owned option 4.

- Maintaining both `messages` and `choiceTurns` can drift.
  Mitigation: centralize answer submission in one `AppModel` method that updates both.

- Editing near-match answers can expand UI scope.
  Mitigation: implement the selection and free-writing loop first, then add near-match editing as the final interaction slice before calling the feature complete.

- Existing uncommitted edits exist in `Motion.swift`, `PreviewView.swift`, and `SessionView.swift`.
  Mitigation: inspect those changes before implementation and avoid overwriting user work.

## Suggested Commit Breakdown

1. `feat: 選択式ターンの状態モデルを追加`
   - Add `ChoiceTurn`, `ChoiceOption`, answer types, parsing helpers.

2. `feat: Ollama応答を4択ターンとして扱う`
   - Update prompts, parse response, normalize options, drive next-turn generation.

3. `feat: 対話画面に4択回答を追加`
   - Add quiet choice list and manual writing states.

4. `feat: 選択式セッションをMarkdownに保存`
   - Update `NoteStore` and summary log generation.

5. `docs: 選択式対話の受け入れ条件を追加`
   - Update acceptance criteria.

## Definition of Done

- The default post-seed session flow is choice-first.
- Every Diguest turn shows one question and four options.
- Option 4 always opens manual writing.
- Selected, edited, and free-written answers advance the session.
- Saved Markdown clearly preserves options and answers.
- Build succeeds.
- No external APIs, web code, or cloud storage are introduced.
