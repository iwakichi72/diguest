import XCTest
@testable import Diguest

final class ChoiceResponseParserTests: XCTestCase {
    func testParsesBraceAwareJSONAndForcesFreeWriteOption() {
        let text = """
        前置き
        {"question":"その違和感はどれに近いですか？","options":["まだ言葉にならない{引っかかり}","期待と現実がずれている感じ","誰かの基準に寄せている感じ"]}
        後置き
        """

        guard case .choice(let turn) = ChoiceResponseParser.parse(text) else {
            return XCTFail("Expected a parsed choice turn")
        }

        XCTAssertEqual(turn.question, "その違和感はどれに近いですか？")
        XCTAssertEqual(turn.options.map(\.text), [
            "まだ言葉にならない{引っかかり}",
            "期待と現実がずれている感じ",
            "誰かの基準に寄せている感じ",
            "近いものがないので書く"
        ])
        XCTAssertTrue(turn.options[3].isFreeWrite)
    }

    func testDeduplicatesAndUsesFirstThreeEligibleOptions() {
        let text = """
        {"question":"どれが近いですか？","options":["まだ言葉にならない引っかかり","まだ言葉にならない引っかかり","期待と現実がずれている感じ","誰かの基準に寄せている感じ","本当は避けていることがある"]}
        """

        guard case .choice(let turn) = ChoiceResponseParser.parse(text) else {
            return XCTFail("Expected a parsed choice turn")
        }

        XCTAssertEqual(turn.options.map(\.text), [
            "まだ言葉にならない引っかかり",
            "期待と現実がずれている感じ",
            "誰かの基準に寄せている感じ",
            "近いものがないので書く"
        ])
    }

    func testFallsBackWhenEligibleOptionsAreFewerThanThree() {
        let text = """
        {"question":"どれが近いですか？","options":["まだ言葉にならない引っかかり","上司に相談する","毎朝10分書く","あなたは完璧主義です"]}
        """

        guard case .fallback(let question, _) = ChoiceResponseParser.parse(text) else {
            return XCTFail("Expected fallback")
        }

        XCTAssertEqual(question, "どれが近いですか？")
    }

    func testFallbackOptionsStillProvideFourChoices() {
        let options = ChoiceResponseParser.normalizedOptions(from: ChoiceResponseParser.fallbackOptions)

        XCTAssertEqual(options.map(\.text), [
            "まだ言葉にならない引っかかり",
            "近いけど少し違う",
            "もう少し問いを変えて掘りたい",
            "近いものがないので書く"
        ])
        XCTAssertTrue(options[3].isFreeWrite)
    }

    func testValidatorRejectsAdviceDiagnosisAndShouldStatements() {
        XCTAssertFalse(ChoiceResponseValidator.isEligibleOption("上司に相談する"))
        XCTAssertFalse(ChoiceResponseValidator.isEligibleOption("毎朝10分書く"))
        XCTAssertFalse(ChoiceResponseValidator.isEligibleOption("あなたは完璧主義です"))
        XCTAssertFalse(ChoiceResponseValidator.isEligibleOption("優先順位を整理する"))
        XCTAssertTrue(ChoiceResponseValidator.isEligibleOption("期待と現実がずれている感じ"))
    }
}
