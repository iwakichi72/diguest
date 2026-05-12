import XCTest
@testable import Diguest

final class ChoiceTurnLogBuilderTests: XCTestCase {
    func testBuildsReadableChoiceDialogueLog() {
        let turn = ChoiceTurn(
            question: "それはどんな違和感に近いですか？",
            options: [
                ChoiceOption(index: 1, text: "まだ言葉にならない引っかかり"),
                ChoiceOption(index: 2, text: "期待と現実がずれている感じ"),
                ChoiceOption(index: 3, text: "誰かの基準に寄せている感じ"),
                ChoiceOption(index: 4, text: "近いものがないので書く", isFreeWrite: true)
            ],
            rawAssistantText: "{}",
            answer: .edited(
                originalIndex: 2,
                originalText: "期待と現実がずれている感じ",
                editedText: "期待されている自分から離れたい感じ"
            )
        )

        let log = ChoiceTurnLogBuilder.dialogueLog(seedText: "仕事の違和感", turns: [turn])

        XCTAssertTrue(log.contains("**You:**\n\n仕事の違和感"))
        XCTAssertTrue(log.contains("問い: それはどんな違和感に近いですか？"))
        XCTAssertTrue(log.contains("1. まだ言葉にならない引っかかり"))
        XCTAssertTrue(log.contains("4. 近いものがないので書く"))
        XCTAssertTrue(log.contains("編集した選択: 期待されている自分から離れたい感じ"))
    }

    func testNoteStoreEscapesFrontmatterScalarsAndKeepsChoiceLog() {
        let store = NoteStore()
        let turn = ChoiceTurn(
            question: "どれが近いですか？",
            options: [
                ChoiceOption(index: 1, text: "期待と現実がずれている感じ"),
                ChoiceOption(index: 2, text: "まだ言葉にならない引っかかり"),
                ChoiceOption(index: 3, text: "本当は避けていることがある"),
                ChoiceOption(index: 4, text: "近いものがないので書く", isFreeWrite: true)
            ],
            rawAssistantText: "{}",
            answer: .freeWritten("胸の奥が詰まる感じ")
        )

        let markdown = store.buildMarkdown(
            theme: #"quote " theme"#,
            seedText: "最初の入力",
            choiceTurns: [turn],
            model: #"model " x"#,
            startedAt: Date(timeIntervalSince1970: 0),
            summary: "",
            surfaced: []
        )

        XCTAssertTrue(markdown.contains(#"theme: "quote \" theme""#))
        XCTAssertTrue(markdown.contains(#"model: "model \" x""#))
        XCTAssertTrue(markdown.contains("自由記述: 胸の奥が詰まる感じ"))
    }

    func testFreeWrittenAnswerPreservesLineBreaks() {
        let answer = ChoiceAnswer.freeWritten("胸の奥が詰まる感じ\nまだうまく言えない")

        let text = ChoiceTurnLogBuilder.answerText(for: answer)

        XCTAssertTrue(text.contains("自由記述:\n\n胸の奥が詰まる感じ\nまだうまく言えない"))
    }
}
