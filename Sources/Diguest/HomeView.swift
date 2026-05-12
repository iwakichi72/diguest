import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(
                title: "Diguest",
                trailing: AnyView(
                    Button("設定") {
                        model.screen = .settings
                    }
                    .buttonStyle(QuietButtonStyle())
                )
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("今日、何を掘りますか？")
                            .font(.system(size: 28, weight: .regular, design: .serif))
                            .foregroundStyle(Theme.text)

                        Button("新しく掘る") {
                            model.showThemeEntry()
                        }
                        .buttonStyle(QuietButtonStyle(prominent: true))
                    }

                    Rectangle()
                        .fill(Theme.border)
                        .frame(height: 1)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("過去のノート")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.secondary)

                        if model.notes.isEmpty {
                            Text("最初の問いを立ててみよう")
                                .font(.system(size: 15, design: .serif))
                                .foregroundStyle(Theme.secondary)
                        } else {
                            ForEach(model.notes) { note in
                                Button {
                                    model.openNote(note)
                                } label: {
                                    HStack(spacing: 18) {
                                        Text(shortDate(note.date))
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundStyle(Theme.muted)
                                            .frame(width: 88, alignment: .leading)
                                        Text(note.theme)
                                            .font(.system(size: 16, design: .serif))
                                            .foregroundStyle(Theme.text)
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(maxWidth: 680, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 72)
                .padding(.bottom, 40)
            }
        }
    }

    private func shortDate(_ raw: String) -> String {
        String(raw.prefix(10))
    }
}

