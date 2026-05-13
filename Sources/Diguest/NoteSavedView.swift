import SwiftUI

struct NoteSavedView: View {
    let note: NoteContent

    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(title: "今日掘り当てたもの")

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    if model.config.enableDigAnimation && model.digDepth.level > 0 {
                        CrystallizationView(depth: model.digDepth)
                            .padding(.top, 4)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(note.metadata.theme)
                            .font(.system(size: 22, design: .serif))
                            .foregroundStyle(Theme.text)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 10) {
                            Text(shortDate(note.metadata.date))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(Theme.muted)
                            if model.digDepth.level > 0 {
                                Text("・")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.muted)
                                Text("\(model.digDepth.currentLayer.displayName) ・ 深さ \(String(format: "%02d", model.digDepth.level))")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(Theme.muted)
                            }
                        }
                    }

                    Button("ホームへ戻る") {
                        model.goHome()
                    }
                    .buttonStyle(QuietButtonStyle(prominent: true))
                    .keyboardShortcut(.return, modifiers: [])
                    .padding(.top, 10)
                }
                .frame(maxWidth: 560, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 64)
                .padding(.bottom, 40)
            }
        }
        .task {
            guard !reduceMotion else { return }
            try? await Task.sleep(nanoseconds: 3_200_000_000)
            guard !Task.isCancelled else { return }
            model.goHome()
        }
    }

    private func shortDate(_ raw: String) -> String {
        String(raw.prefix(10))
    }
}
