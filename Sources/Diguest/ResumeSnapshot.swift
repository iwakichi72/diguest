import Foundation

struct ResumeSnapshot: Codable, Equatable {
    let v: Int
    let depth: Int
    let seed: String
    let turns: [TurnSnapshot]

    struct TurnSnapshot: Codable, Equatable {
        let q: String
        let fb: Bool
        let o: [OptionSnapshot]
        let a: AnswerSnapshot?
    }

    struct OptionSnapshot: Codable, Equatable {
        let i: Int
        let t: String
        let fw: Bool
    }

    struct AnswerSnapshot: Codable, Equatable {
        let k: String
        let i: Int?
        let t: String?
        let oi: Int?
        let ot: String?
        let et: String?
    }
}

enum ResumeSnapshotEncoder {
    static let currentVersion = 1
    static let openMarker = "<!-- diguest-resume:"
    static let closeMarker = "-->"

    static func make(seedText: String, choiceTurns: [ChoiceTurn], depthLevel: Int) -> ResumeSnapshot {
        ResumeSnapshot(
            v: currentVersion,
            depth: depthLevel,
            seed: seedText,
            turns: choiceTurns.map { turn in
                ResumeSnapshot.TurnSnapshot(
                    q: turn.question,
                    fb: turn.isFallback,
                    o: turn.options.map { option in
                        ResumeSnapshot.OptionSnapshot(i: option.index, t: option.text, fw: option.isFreeWrite)
                    },
                    a: turn.answer.map { encodeAnswer($0) }
                )
            }
        )
    }

    static func encodeBlock(_ snapshot: ResumeSnapshot) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = []
        guard let data = try? encoder.encode(snapshot),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        return "\(openMarker) \(json) \(closeMarker)"
    }

    static func decodeBlock(from markdown: String) -> ResumeSnapshot? {
        guard let openRange = markdown.range(of: openMarker) else { return nil }
        let afterOpen = markdown[openRange.upperBound...]
        guard let closeRange = afterOpen.range(of: closeMarker) else { return nil }

        let payload = afterOpen[..<closeRange.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = payload.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(ResumeSnapshot.self, from: data)
    }

    static func stripBlock(from markdown: String) -> String {
        guard let openRange = markdown.range(of: openMarker) else { return markdown }
        var prefix = String(markdown[..<openRange.lowerBound])
        while let last = prefix.last, last.isWhitespace {
            prefix.removeLast()
        }
        return prefix
    }

    private static func encodeAnswer(_ answer: ChoiceAnswer) -> ResumeSnapshot.AnswerSnapshot {
        switch answer {
        case .selected(let index, let text):
            return ResumeSnapshot.AnswerSnapshot(k: "selected", i: index, t: text, oi: nil, ot: nil, et: nil)
        case .edited(let originalIndex, let originalText, let editedText):
            return ResumeSnapshot.AnswerSnapshot(k: "edited", i: nil, t: nil, oi: originalIndex, ot: originalText, et: editedText)
        case .freeWritten(let text):
            return ResumeSnapshot.AnswerSnapshot(k: "freeWritten", i: nil, t: text, oi: nil, ot: nil, et: nil)
        }
    }
}

enum ResumeSnapshotDecoder {
    static func choiceTurns(from snapshot: ResumeSnapshot) -> [ChoiceTurn] {
        snapshot.turns.map { turn in
            ChoiceTurn(
                question: turn.q,
                options: turn.o.map { ChoiceOption(index: $0.i, text: $0.t, isFreeWrite: $0.fw) },
                rawAssistantText: "",
                answer: turn.a.flatMap { decodeAnswer($0) },
                isFallback: turn.fb
            )
        }
    }

    private static func decodeAnswer(_ snapshot: ResumeSnapshot.AnswerSnapshot) -> ChoiceAnswer? {
        switch snapshot.k {
        case "selected":
            guard let index = snapshot.i, let text = snapshot.t else { return nil }
            return .selected(index: index, text: text)
        case "edited":
            guard let originalIndex = snapshot.oi,
                  let originalText = snapshot.ot,
                  let editedText = snapshot.et else { return nil }
            return .edited(originalIndex: originalIndex, originalText: originalText, editedText: editedText)
        case "freeWritten":
            guard let text = snapshot.t else { return nil }
            return .freeWritten(text)
        default:
            return nil
        }
    }
}
