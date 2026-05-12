# Choice-First Digging Design

## Purpose

Diguest should let users dig into their thinking without making them write long answers every turn. The default interaction becomes choosing from a small set of candidate answers. Free writing remains available, but it is a fallback for moments when no option feels close enough.

This supports the core product goal: helping users surface their own thoughts, not receiving advice from an assistant.

## Product Decision

Use a hybrid choice model:

- Most turns show short, fast choices.
- Deeper turns may show sentence-like hypothesis choices when nuance matters.
- The default is four choices.
- One of the four choices is always a free-writing path.

The usual set is:

1. A short or sentence-like candidate answer
2. A short or sentence-like candidate answer
3. A short or sentence-like candidate answer
4. `近いものがないので書く`

When one option is close but not exact, the UI may let the user edit that selected text before sending it. This editing flow should feel like refining a draft, not filling out a form.

Near-match editing is an action on one of the first three choices. It is not a fifth choice.

## Interaction Model

Each Diguest turn contains:

- One question
- Four answer options by default
- A clear path to write manually when none fit

The user can answer by selecting an option. The selected option is treated as the user's next answer and is sent into the next generation step.

Free writing is available only after the user chooses `近いものがないので書く`. Editing is available only after selecting one of the first three options. This keeps the main path quick while preserving escape hatches for personal nuance.

## Choice Content Rules

Choices are not advice, recommendations, diagnoses, scores, or action plans. They are hypothesis labels for the user's inner state.

Good choices:

- `まだ言葉にならない引っかかり`
- `期待と現実がずれている感じ`
- `本当は避けていることがある`
- `怒りよりも、置いていかれた感じが強い`

Bad choices:

- `上司に相談する`
- `毎朝10分書く`
- `あなたは完璧主義です`
- `優先順位を整理する`

The prompt should instruct the model to generate options that are:

- Short enough to scan quickly
- Mutually distinct
- Based on the user's previous answer
- Focused on inner texture, emotion, tension, memory, value, or unresolved question
- Free of advice, evaluation, and behavior change

## UI Design

The choice UI must not become chat suggestion chips. It should read like a quiet worksheet or a numbered list below Diguest's question.

Visual direction:

- Keep the single-column 680px reading width.
- Present options as subdued rows or a radio-style list.
- Avoid colorful pills, bubbles, avatars, badges, and dashboard patterns.
- Keep the free-writing path as the fourth option, visually equal but slightly quieter.
- Once an option is chosen, append it into the transcript as the user's answer.

The existing text editor remains available for manual writing and editing, but it is no longer the main visual focus on every turn.

## Data Flow

The app should represent Diguest's response as structured turn data:

- Assistant question text
- Four options
- The user's selected option, edited option, or free-written answer

For MVP implementation, this may be stored alongside existing messages as readable text if a dedicated turn model would add too much scope. The important requirement is that selection history remains durable in Markdown.

## Markdown Output

Markdown should remain readable and durable. The existing note format can stay, with choice details included in the dialogue log.

Example:

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

Free writing example:

```markdown
**You:**

自由記述: もっと身体感覚に近い。胸の奥が詰まる感じ。
```

Edited near-match example:

```markdown
**You:**

編集した選択: 期待と現実がずれているというより、期待されている自分から離れたい感じ。
```

The summary generation should treat selected and edited choices as user-authored material, because the user confirmed that those words are close enough to their thought.

## Error Handling

If structured option generation fails, Diguest should still return a plain question and allow free writing. The session must remain usable.

If speech input is available, it can fill the free-writing editor. If on-device speech recognition is unavailable, the app must not fall back to network recognition.

If the model returns fewer or more than four options, the app should normalize to four where possible:

- Keep the best three content options.
- Always reserve the fourth slot for `近いものがないので書く`.

## MVP Scope

In scope:

- Generate one question and four answer options per Diguest turn.
- Let the user select an option to continue.
- Let the user choose the fourth option to write manually.
- Let the user edit a near-match selected option before sending, without adding a fifth option.
- Save questions, options, selections, edits, and free-written answers in Markdown.
- Keep all generation local through Ollama.

Out of scope:

- Past-note retrieval for option generation
- Personality diagnosis
- Scoring, tagging, dashboards, streaks, or analytics
- Visual branch trees
- User-managed option templates
- External AI APIs or cloud storage
- Browser or web implementation

## Acceptance Criteria

- Given a session is active, when Diguest responds, then the app shows one question and four answer options by default.
- Given answer options are visible, when the user chooses one of the first three options, then that option is recorded as the user's answer and the next Diguest turn begins.
- Given no option is close enough, when the user chooses the fourth option, then the app opens manual writing with optional on-device speech input.
- Given the user edits a near-match option, when they submit it, then the edited text is recorded as the user's answer.
- Given a session is saved, when the Markdown is opened, then each turn's question, options, selected answer, edited answer, or free-written answer is readable in the dialogue log.
- Given Ollama returns malformed structured output, when Diguest cannot parse the options, then the app falls back to a plain question and manual writing instead of blocking the session.

## Implementation Notes

The first implementation should change the prompt and session loop before adding deeper model abstractions. If the structured response format proves stable, introduce explicit turn models afterward.

Recommended sequence:

1. Update prompts to request a question plus four options.
2. Add parsing for structured assistant responses.
3. Render choices as a quiet numbered selection list in `SessionView`.
4. Send selected, edited, or free-written answers as user messages.
5. Preserve choice details in Markdown generation.
6. Add acceptance criteria to project docs after implementation details are confirmed.
