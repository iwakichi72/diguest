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

    static let defaults = AppConfig(
        ollamaBaseUrl: "http://localhost:11434",
        ollamaModel: "gemma3:4b",
        notesDir: "~/diguest"
    )
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

enum AppScreen: Equatable {
    case home
    case themeEntry
    case session
    case preview
    case note(NoteContent)
    case settings
}

