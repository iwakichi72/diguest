import Foundation

enum ChoiceResponseParseResult: Equatable {
    case choice(ChoiceTurn)
    case fallback(question: String, rawAssistantText: String)
}

enum ChoiceResponseParser {
    static let fallbackOptions = [
        "まだ言葉にならない引っかかり",
        "近いけど少し違う",
        "もう少し問いを変えて掘りたい"
    ]

    static func parse(_ text: String) -> ChoiceResponseParseResult {
        let rawText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let json = extractFirstJSONObject(from: rawText),
            let data = json.data(using: .utf8),
            let payload = try? JSONDecoder().decode(ChoiceResponsePayload.self, from: data)
        else {
            return .fallback(question: fallbackQuestion(from: rawText), rawAssistantText: rawText)
        }

        let question = payload.question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else {
            return .fallback(question: fallbackQuestion(from: rawText), rawAssistantText: rawText)
        }

        let options = normalizedOptions(from: payload.options)

        guard options.filter({ !$0.isFreeWrite }).count >= 3 else {
            return .fallback(question: question, rawAssistantText: rawText)
        }

        return .choice(ChoiceTurn(question: question, options: options, rawAssistantText: rawText))
    }

    static func extractFirstJSONObject(from text: String) -> String? {
        var startIndex: String.Index?
        var depth = 0
        var inString = false
        var isEscaped = false
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]

            if inString {
                if isEscaped {
                    isEscaped = false
                } else if character == "\\" {
                    isEscaped = true
                } else if character == "\"" {
                    inString = false
                }
            } else {
                if character == "\"" {
                    inString = true
                } else if character == "{" {
                    if depth == 0 {
                        startIndex = index
                    }
                    depth += 1
                } else if character == "}" {
                    guard depth > 0 else {
                        index = text.index(after: index)
                        continue
                    }
                    depth -= 1
                    if depth == 0, let startIndex {
                        return String(text[startIndex...index])
                    }
                }
            }

            index = text.index(after: index)
        }

        return nil
    }

    private static func fallbackQuestion(from rawText: String) -> String {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !trimmed.isEmpty,
            !trimmed.contains("{"),
            !trimmed.contains("}"),
            trimmed.count <= 240
        else {
            return "いま浮かんでいることを、そのまま書いてください。"
        }

        return trimmed
    }

    static func normalizedOptions(from texts: [String]) -> [ChoiceOption] {
        var seen = Set<String>()
        let contentOptions = texts.compactMap { option -> String? in
            let normalized = ChoiceResponseValidator.normalizedOptionText(option)
            let key = normalized.lowercased()
            guard ChoiceResponseValidator.isEligibleOption(normalized), !seen.contains(key) else {
                return nil
            }
            seen.insert(key)
            return normalized
        }

        return Array(contentOptions.prefix(3)).enumerated().map { offset, text in
            ChoiceOption(index: offset + 1, text: text)
        } + [
            ChoiceOption(index: 4, text: ChoiceResponseValidator.freeWriteText, isFreeWrite: true)
        ]
    }
}
