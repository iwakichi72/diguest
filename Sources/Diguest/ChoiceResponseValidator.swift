import Foundation

enum ChoiceResponseValidator {
    static let freeWriteText = "近いものがないので書く"

    static func normalizedOptionText(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"^\s*[\d１２３４]+[\.．、\)]\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }

    static func isEligibleOption(_ text: String) -> Bool {
        let normalized = normalizedOptionText(text)
        guard !normalized.isEmpty, normalized != freeWriteText else {
            return false
        }

        let disallowedFragments = [
            "相談する",
            "相談して",
            "毎朝",
            "10分",
            "整理する",
            "優先順位",
            "改善する",
            "解決する",
            "行動する",
            "試して",
            "しましょう",
            "おすすめ",
            "した方がいい",
            "すべき",
            "べき",
            "必要がある",
            "診断",
            "タイプです"
        ]

        if disallowedFragments.contains(where: { normalized.contains($0) }) {
            return false
        }

        if normalized.contains("あなたは"), normalized.contains("です") {
            return false
        }

        if normalized.range(of: #"^(まず|次に|今日から|明日から)"#, options: .regularExpression) != nil {
            return false
        }

        return true
    }
}
