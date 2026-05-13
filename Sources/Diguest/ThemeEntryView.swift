import SwiftUI

struct ThemeEntryView: View {
    @EnvironmentObject private var model: AppModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(
                title: "新しいセッション",
                trailing: AnyView(
                    Button("戻る") {
                        model.goHome()
                    }
                    .buttonStyle(QuietButtonStyle())
                )
            )

            VStack(alignment: .leading, spacing: 22) {
                Text("今日、何を掘りますか？")
                    .font(.system(size: 30, weight: .regular, design: .serif))

                TextField("", text: $model.theme)
                    .textFieldStyle(.plain)
                    .font(.system(size: 22, design: .serif))
                    .foregroundStyle(Theme.text)
                    .padding(18)
                    .background(Theme.subtle)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Theme.borderFocus, lineWidth: isFocused ? 1 : 0.8)
                    }
                    .focused($isFocused)
                    .onSubmit {
                        model.startSession()
                    }

                Text("テーマは短く、一言で。答えではなく、問いでも構いません。")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.secondary)

                Button("掘り始める") {
                    model.startSession()
                }
                .buttonStyle(QuietButtonStyle(prominent: true))
                .disabled(model.theme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(model.theme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.35 : 1)

                if !model.recentThemes.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("掘りかけのテーマから")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.muted)
                            .padding(.top, 18)

                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(model.recentThemes, id: \.self) { theme in
                                Button {
                                    model.theme = theme
                                    isFocused = true
                                } label: {
                                    Text(theme)
                                        .font(.system(size: 14, design: .serif))
                                        .foregroundStyle(Theme.secondary)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: 680, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.top, 96)

            Spacer()
        }
        .onAppear {
            isFocused = true
        }
    }
}

