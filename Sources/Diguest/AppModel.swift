import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var screen: AppScreen = .home
    @Published var config: AppConfig = .defaults
    @Published var notes: [NoteMetadata] = []
    @Published var theme = ""
    @Published var input = ""
    @Published var messages: [Message] = []
    @Published var seedText = ""
    @Published var choiceTurns: [ChoiceTurn] = []
    @Published var manualAnswerMode: ManualAnswerMode?
    @Published var pendingChoice: ChoiceOption?
    @Published var isStreaming = false
    @Published var isGeneratingMarkdown = false
    @Published var markdownPreview = ""
    @Published var errorMessage: String?
    @Published var isOllamaReachable = false

    let speech = SpeechInputController()

    private let configStore = ConfigStore()
    private let noteStore = NoteStore()
    private var startedAt = Date()
    private var speechBase = ""
    private var speechObservation: AnyCancellable?

    init() {
        speechObservation = speech.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    func bootstrap() async {
        config = configStore.load()
        speech.probe()
        reloadNotes()
        await refreshConnection()
    }

    func showThemeEntry() {
        theme = ""
        input = ""
        seedText = ""
        choiceTurns = []
        manualAnswerMode = nil
        pendingChoice = nil
        errorMessage = nil
        screen = .themeEntry
    }

    func startSession() {
        let trimmedTheme = theme.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTheme.isEmpty else { return }

        startedAt = Date()
        theme = trimmedTheme
        messages = []
        seedText = ""
        choiceTurns = []
        manualAnswerMode = nil
        pendingChoice = nil
        input = ""
        errorMessage = nil
        screen = .session
    }

    func sendInput() {
        let content = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, !isStreaming else { return }

        if manualAnswerMode != nil {
            submitManualAnswer(content)
            return
        }

        guard choiceTurns.isEmpty else { return }

        seedText = content
        input = ""
        messages.append(Message(role: .user, content: content))
        errorMessage = nil

        generateChoiceTurn()
    }

    func selectOption(_ option: ChoiceOption) {
        guard !isStreaming, !isGeneratingMarkdown, activeTurnIndex != nil else { return }

        if option.isFreeWrite {
            pendingChoice = nil
            manualAnswerMode = .freeWrite
            input = ""
        } else {
            pendingChoice = option
            manualAnswerMode = nil
            input = ""
        }
    }

    func confirmPendingChoice() {
        guard let option = pendingChoice, !isStreaming else { return }

        let answer = ChoiceAnswer.selected(index: option.index, text: option.text)
        pendingChoice = nil
        recordAnswer(answer)
    }

    func editPendingChoice() {
        guard let option = pendingChoice, !isStreaming else { return }

        input = option.text
        manualAnswerMode = .edit(optionIndex: option.index, originalText: option.text)
        pendingChoice = nil
    }

    func cancelManualAnswer() {
        input = ""
        manualAnswerMode = nil
        pendingChoice = nil
    }

    func toggleSpeech() {
        speechBase = input
        speech.toggle { [weak self] transcript, isFinal in
            guard let self else { return }
            let next = self.appendSpeechText(base: self.speechBase, transcript: transcript)
            self.input = next
            if isFinal {
                self.speechBase = next
            }
        }
    }

    func endSession() {
        guard !messages.isEmpty || !choiceTurns.isEmpty else {
            screen = .home
            return
        }

        isGeneratingMarkdown = true
        errorMessage = nil
        let client = OllamaClient(config: config)
        let log = ChoiceTurnLogBuilder.dialogueLog(seedText: seedText, turns: choiceTurns)
        let summaryMessages = [
            Message(role: .system, content: Prompts.summarySystem),
            Message(role: .user, content: Prompts.summary(theme: theme, log: log))
        ]

        Task {
            var summary = ""
            var surfaced: [String] = []

            do {
                let text = try await client.generateText(messages: summaryMessages)
                if let parsed = parseSummary(text) {
                    summary = parsed.summary
                    surfaced = parsed.surfaced
                }
            } catch {
                summary = ""
                surfaced = []
            }

            markdownPreview = noteStore.buildMarkdown(
                theme: theme,
                seedText: seedText,
                choiceTurns: choiceTurns,
                model: config.ollamaModel,
                startedAt: startedAt,
                summary: summary,
                surfaced: surfaced
            )
            isGeneratingMarkdown = false
            screen = .preview
        }
    }

    func savePreview() {
        do {
            let fileName = noteStore.buildFileName(theme: theme, startedAt: startedAt)
            let savedName = try noteStore.save(markdown: markdownPreview, fileName: fileName, config: config)
            reloadNotes()
            if let note = noteStore.read(fileName: savedName, config: config) {
                screen = .note(note)
            } else {
                screen = .home
            }
        } catch {
            errorMessage = "保存できませんでした"
        }
    }

    func openNote(_ metadata: NoteMetadata) {
        if let note = noteStore.read(fileName: metadata.fileName, config: config) {
            screen = .note(note)
        }
    }

    func reloadNotes() {
        notes = Array(noteStore.listNotes(config: config).prefix(20))
    }

    func refreshConnection() async {
        isOllamaReachable = await OllamaClient(config: config).checkConnection()
    }

    func saveSettings() {
        do {
            try configStore.save(config)
            reloadNotes()
            errorMessage = nil
            screen = .home
            Task { await refreshConnection() }
        } catch {
            errorMessage = "設定を保存できませんでした"
        }
    }

    func goHome() {
        errorMessage = nil
        screen = .home
    }

    private func appendSpeechText(base: String, transcript: String) -> String {
        let spoken = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !spoken.isEmpty else { return base }
        guard !base.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return spoken }
        return "\(base.trimmingCharacters(in: .whitespacesAndNewlines))\n\(spoken)"
    }

    private func parseSummary(_ text: String) -> SummaryPayload? {
        guard let json = ChoiceResponseParser.extractFirstJSONObject(from: text) else { return nil }
        guard let data = json.data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode(SummaryPayload.self, from: data)
    }

    private var activeTurnIndex: Int? {
        choiceTurns.indices.last { choiceTurns[$0].answer == nil }
    }

    private func submitManualAnswer(_ content: String) {
        guard let manualAnswerMode else { return }

        let answer: ChoiceAnswer
        switch manualAnswerMode {
        case .freeWrite:
            answer = .freeWritten(content)
        case .edit(let optionIndex, let originalText):
            answer = .edited(originalIndex: optionIndex, originalText: originalText, editedText: content)
        }

        input = ""
        self.manualAnswerMode = nil
        pendingChoice = nil
        recordAnswer(answer)
    }

    private func recordAnswer(_ answer: ChoiceAnswer) {
        guard let index = activeTurnIndex else { return }

        choiceTurns[index].answer = answer
        messages.append(Message(role: .user, content: ChoiceTurnLogBuilder.answerText(for: answer)))
        errorMessage = nil

        generateChoiceTurn()
    }

    private func generateChoiceTurn() {
        guard !messages.isEmpty, !isStreaming else { return }

        isStreaming = true
        errorMessage = nil
        let history = [Message(role: .system, content: Prompts.system)] + messages
        let client = OllamaClient(config: config)

        Task {
            do {
                let stream = try await client.streamChat(messages: history)
                var rawAssistantText = ""
                for try await chunk in stream {
                    rawAssistantText += chunk
                }

                switch ChoiceResponseParser.parse(rawAssistantText) {
                case .choice(let turn):
                    choiceTurns.append(turn)
                    messages.append(Message(role: .assistant, content: ChoiceTurnLogBuilder.assistantText(for: turn)))
                    manualAnswerMode = nil
                case .fallback(let question, let rawAssistantText):
                    let turn = ChoiceTurn(
                        question: question,
                        options: ChoiceResponseParser.normalizedOptions(from: ChoiceResponseParser.fallbackOptions),
                        rawAssistantText: rawAssistantText,
                        isFallback: true
                    )
                    choiceTurns.append(turn)
                    messages.append(Message(role: .assistant, content: ChoiceTurnLogBuilder.assistantText(for: turn)))
                    manualAnswerMode = nil
                }

                isStreaming = false
            } catch {
                isStreaming = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
