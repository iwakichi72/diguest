import Foundation

enum ChoiceTurnLogBuilder {
    static func assistantText(for turn: ChoiceTurn) -> String {
        var lines = [
            "問い: \(singleLine(turn.question))"
        ]

        if !turn.options.isEmpty {
            lines.append("")
            lines.append("選択肢:")
            lines += turn.options.map { "\($0.index). \(singleLine($0.text))" }
        }

        return lines.joined(separator: "\n")
    }

    static func answerText(for answer: ChoiceAnswer) -> String {
        switch answer {
        case .selected(let index, let text):
            return "選択: \(index). \(singleLine(text))"
        case .edited(_, _, let editedText):
            return labeledAnswer(label: "編集した選択", text: editedText)
        case .freeWritten(let text):
            return labeledAnswer(label: "自由記述", text: text)
        }
    }

    static func dialogueLog(seedText: String, turns: [ChoiceTurn]) -> String {
        var blocks: [String] = []
        let seed = seedText.trimmingCharacters(in: .whitespacesAndNewlines)

        if !seed.isEmpty {
            blocks.append("**You:**\n\n\(seed)")
        }

        for turn in turns {
            blocks.append("**Diguest:**\n\n\(assistantText(for: turn))")
            if let answer = turn.answer {
                blocks.append("**You:**\n\n\(answerText(for: answer))")
            }
        }

        return blocks.joined(separator: "\n\n---\n\n")
    }

    static func answeredTurnCount(seedText: String, turns: [ChoiceTurn]) -> Int {
        let seedCount = seedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0 : 1
        return seedCount + turns.filter { $0.answer != nil }.count
    }

    private static func singleLine(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }

    private static func labeledAnswer(label: String, text: String) -> String {
        let trimmed = trimmedPreservingLines(text)
        if trimmed.contains("\n") {
            return "\(label):\n\n\(trimmed)"
        }

        return "\(label): \(trimmed)"
    }

    private static func trimmedPreservingLines(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
