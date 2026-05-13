import Foundation

enum Role: String, Codable {
    case system
    case user
    case assistant
}

struct Message: Codable, Identifiable, Equatable {
    let id: UUID
    var role: Role
    var content: String

    init(id: UUID = UUID(), role: Role, content: String) {
        self.id = id
        self.role = role
        self.content = content
    }
}

struct OllamaMessage: Codable {
    let role: String
    let content: String
}

struct AppConfig: Codable, Equatable {
    var ollamaBaseUrl: String
    var ollamaModel: String
    var notesDir: String
    var enableDigAnimation: Bool
    var digAnimationIntensity: DigAnimationIntensity

    static let defaults = AppConfig(
        ollamaBaseUrl: "http://localhost:11434",
        ollamaModel: "gemma3:4b",
        notesDir: "~/diguest",
        enableDigAnimation: true,
        digAnimationIntensity: .normal
    )

    init(
        ollamaBaseUrl: String,
        ollamaModel: String,
        notesDir: String,
        enableDigAnimation: Bool = true,
        digAnimationIntensity: DigAnimationIntensity = .normal
    ) {
        self.ollamaBaseUrl = ollamaBaseUrl
        self.ollamaModel = ollamaModel
        self.notesDir = notesDir
        self.enableDigAnimation = enableDigAnimation
        self.digAnimationIntensity = digAnimationIntensity
    }

    private enum CodingKeys: String, CodingKey {
        case ollamaBaseUrl
        case ollamaModel
        case notesDir
        case enableDigAnimation
        case digAnimationIntensity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.ollamaBaseUrl = try container.decodeIfPresent(String.self, forKey: .ollamaBaseUrl)
            ?? AppConfig.defaults.ollamaBaseUrl
        self.ollamaModel = try container.decodeIfPresent(String.self, forKey: .ollamaModel)
            ?? AppConfig.defaults.ollamaModel
        self.notesDir = try container.decodeIfPresent(String.self, forKey: .notesDir)
            ?? AppConfig.defaults.notesDir
        self.enableDigAnimation = try container.decodeIfPresent(Bool.self, forKey: .enableDigAnimation)
            ?? AppConfig.defaults.enableDigAnimation
        self.digAnimationIntensity = try container.decodeIfPresent(DigAnimationIntensity.self, forKey: .digAnimationIntensity)
            ?? AppConfig.defaults.digAnimationIntensity
    }
}

struct NoteMetadata: Identifiable, Equatable {
    var id: String { fileName }
    let fileName: String
    let theme: String
    let date: String
    let model: String
    let turns: Int
}

struct NoteContent: Equatable {
    let metadata: NoteMetadata
    let rawMarkdown: String
}

struct SummaryPayload: Codable {
    let summary: String
    let surfaced: [String]
}

struct ChoiceTurn: Identifiable, Equatable {
    let id: UUID
    var question: String
    var options: [ChoiceOption]
    var rawAssistantText: String
    var answer: ChoiceAnswer?
    var isFallback: Bool

    init(
        id: UUID = UUID(),
        question: String,
        options: [ChoiceOption],
        rawAssistantText: String,
        answer: ChoiceAnswer? = nil,
        isFallback: Bool = false
    ) {
        self.id = id
        self.question = question
        self.options = options
        self.rawAssistantText = rawAssistantText
        self.answer = answer
        self.isFallback = isFallback
    }
}

struct ChoiceOption: Identifiable, Equatable {
    let id: UUID
    var index: Int
    var text: String
    var isFreeWrite: Bool

    init(id: UUID = UUID(), index: Int, text: String, isFreeWrite: Bool = false) {
        self.id = id
        self.index = index
        self.text = text
        self.isFreeWrite = isFreeWrite
    }
}

enum ChoiceAnswer: Equatable {
    case selected(index: Int, text: String)
    case edited(originalIndex: Int, originalText: String, editedText: String)
    case freeWritten(String)
}

enum ManualAnswerMode: Equatable {
    case freeWrite
    case edit(optionIndex: Int, originalText: String)
}

struct ChoiceResponsePayload: Codable, Equatable {
    let question: String
    let options: [String]
}

enum AppScreen: Equatable {
    case home
    case themeEntry
    case session
    case preview
    case note(NoteContent)
    case settings
}
