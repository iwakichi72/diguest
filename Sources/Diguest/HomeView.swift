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

                    if model.ollamaCheckState == .unreachable {
                        OllamaUnreachableCard()
                            .quietReveal(duration: MotionToken.base, blur: 1)
                    }

                    Rectangle()
                        .fill(Theme.border)
                        .frame(height: 1)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("過去のノート")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.secondary)

                        if model.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("まだノートはありません")
                                    .font(.system(size: 15, design: .serif))
                                    .foregroundStyle(Theme.secondary)
                                Text("最初のセッションを終えると、ここにノートが残ります。")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.muted)
                                    .lineSpacing(3)
                            }
                        } else {
                            ForEach(model.notes) { note in
                                Button {
                                    model.openNote(note)
                                } label: {
                                    NoteRow(note: note)
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
        .task {
            await model.refreshConnection()
        }
    }
}

private struct NoteRow: View {
    let note: NoteMetadata

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 18) {
            Text(shortDate(note.date))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.muted)
                .frame(width: 88, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(note.theme)
                    .font(.system(size: 16, design: .serif))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)

                if let layerLine = layerLine {
                    HStack(spacing: 10) {
                        Text(layerLine)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Theme.muted)
                        if let excerpt = note.seedExcerpt, !excerpt.isEmpty {
                            Text("「\(excerpt)」")
                                .font(.system(size: 12, design: .serif))
                                .italic()
                                .foregroundStyle(Theme.muted)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var layerLine: String? {
        guard let level = note.depthLevel, level > 0 else { return nil }
        let layer = DigLayer.layer(forLevel: level)
        return "\(layer.displayName) ・ 深さ \(String(format: "%02d", level))"
    }

    private func shortDate(_ raw: String) -> String {
        String(raw.prefix(10))
    }
}

private struct OllamaUnreachableCard: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Theme.error)
                    .frame(width: 7, height: 7)
                Text("Ollamaが見つかりません")
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(Theme.text)
            }

            Text("localhost:11434 に接続できませんでした。Ollama を起動してからもう一度試してください。")
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 14) {
                Button("もう一度試す") {
                    Task { await model.refreshConnection() }
                }
                .buttonStyle(QuietButtonStyle())

                Button("設定を開く") {
                    model.screen = .settings
                }
                .buttonStyle(QuietButtonStyle())
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.subtle)
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Theme.error.opacity(0.35), lineWidth: 1)
        }
    }
}

