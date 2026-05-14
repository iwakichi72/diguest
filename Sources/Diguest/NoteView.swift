import SwiftUI

struct NoteView: View {
    @EnvironmentObject private var model: AppModel
    let note: NoteContent

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(
                title: note.metadata.theme,
                trailing: AnyView(
                    HStack(spacing: 18) {
                        if note.resumeSnapshot != nil {
                            Button("続きを掘る") {
                                model.resumeFromNote(note)
                            }
                            .buttonStyle(QuietButtonStyle(prominent: true))
                        }
                        Button("戻る") {
                            model.goHome()
                        }
                        .buttonStyle(QuietButtonStyle())
                    }
                )
            )

            ScrollView {
                Text(ResumeSnapshotEncoder.stripBlock(from: note.rawMarkdown))
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

