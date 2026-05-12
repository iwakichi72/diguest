import SwiftUI

struct NoteView: View {
    @EnvironmentObject private var model: AppModel
    let note: NoteContent

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(
                title: note.metadata.theme,
                trailing: AnyView(
                    Button("戻る") {
                        model.goHome()
                    }
                    .buttonStyle(QuietButtonStyle())
                )
            )

            ScrollView {
                Text(note.rawMarkdown)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundStyle(Theme.text)
                    .textSelection(.enabled)
                    .frame(maxWidth: 760, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 36)
            }
        }
    }
}

