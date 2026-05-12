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
        errorMessage = nil
        screen = .themeEntry
    }

    func startSession() {
        let trimmedTheme = theme.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTheme.isEmpty else { return }

        startedAt = Date()
        theme = trimmedTheme
        messages = []
        input = ""
        errorMessage = nil
        screen = .session
    }

    func sendInput() {
        let content = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, !isStreaming else { return }

        input = ""
        messages.append(Message(role: .user, content: content))
        messages.append(Message(role: .assistant, content: ""))
        isStreaming = true
        errorMessage = nil

        let history = [Message(role: .system, content: Prompts.system)] + messages.filter { !$0.content.isEmpty }
        let client = OllamaClient(config: config)

        Task {
            do {
                let stream = try await client.streamChat(messages: history)
                for try await chunk in stream {
                    appendAssistantChunk(chunk)
                }
                isStreaming = false
            } catch {
                if messages.last?.role == .assistant, messages.last?.content.isEmpty == true {
                    messages.removeLast()
                }
                isStreaming = false
                errorMessage = error.localizedDescription
            }
        }
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
        guard !messages.isEmpty else {
            screen = .home
            return
        }

        isGeneratingMarkdown = true
        errorMessage = nil
        let client = OllamaClient(config: config)
        let log = messages
            .map { "\($0.role == .user ? "You" : "Diguest"): \($0.content)" }
            .joined(separator: "\n\n")
        let summaryMessages = [
            Message(role: .system, content: Prompts.system),
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
                messages: messages,
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

    private func appendAssistantChunk(_ chunk: String) {
        guard let lastIndex = messages.indices.last, messages[lastIndex].role == .assistant else {
            return
        }

        messages[lastIndex].content += chunk
    }

    private func appendSpeechText(base: String, transcript: String) -> String {
        let spoken = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !spoken.isEmpty else { return base }
        guard !base.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return spoken }
        return "\(base.trimmingCharacters(in: .whitespacesAndNewlines))\n\(spoken)"
    }

    private func parseSummary(_ text: String) -> SummaryPayload? {
        guard
            let start = text.firstIndex(of: "{"),
            let end = text.lastIndex(of: "}")
        else {
            return nil
        }

        let json = String(text[start...end])
        guard let data = json.data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode(SummaryPayload.self, from: data)
    }
}
