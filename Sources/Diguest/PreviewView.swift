import SwiftUI

struct PreviewView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(
                title: "保存前の確認",
                trailing: AnyView(
                    HStack(spacing: 18) {
                        Button("戻る") {
                            model.screen = .session
                        }
                        .buttonStyle(QuietButtonStyle())
                        Button("保存する") {
                            model.savePreview()
                        }
                        .buttonStyle(QuietButtonStyle(prominent: true))
                    }
                )
            )

            ScrollView {
                Text(model.markdownPreview)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundStyle(Theme.text)
                    .textSelection(.enabled)
                    .frame(maxWidth: 760, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 36)
            }

            if let error = model.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.error)
                    .padding(.bottom, 14)
            }
        }
    }
}

