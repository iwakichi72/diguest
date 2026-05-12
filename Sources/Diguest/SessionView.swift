import SwiftUI

struct SessionView: View {
    @EnvironmentObject private var model: AppModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(
                title: model.theme,
                trailing: AnyView(
                    Button(model.isGeneratingMarkdown ? "まとめています..." : "ここで終える") {
                        model.endSession()
                    }
                    .buttonStyle(QuietButtonStyle())
                    .disabled(model.isStreaming || model.isGeneratingMarkdown)
                )
            )

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 34) {
                        ForEach(model.messages) { message in
                            DialogueBlock(message: message)
                                .id(message.id)
                        }

                        if let error = model.errorMessage {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.error)
                        }
                    }
                    .frame(maxWidth: 680, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.top, 56)
                    .padding(.bottom, 24)
                }
                .onChange(of: model.messages) { _ in
                    if let last = model.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            inputArea
        }
        .onAppear {
            isFocused = true
        }
    }

    private var inputArea: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                TextEditor(text: $model.input)
                    .font(.system(size: 18, design: .serif))
                    .foregroundStyle(Theme.text)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(minHeight: 118, maxHeight: 150)
                    .background(Theme.subtle)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isFocused ? Theme.borderFocus : Theme.border, lineWidth: 1)
                    }
                    .focused($isFocused)
                    .disabled(model.isStreaming || model.isGeneratingMarkdown)

                if model.speech.isAvailable {
                    Button {
                        model.toggleSpeech()
                    } label: {
                        Image(systemName: model.speech.isListening ? "mic.fill" : "mic")
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(model.speech.isListening ? Theme.accent : Theme.secondary)
                    .padding(10)
                    .disabled(model.isStreaming || model.isGeneratingMarkdown)
                    .help(model.speech.isListening ? "音声入力を止める" : "音声入力を始める")
                }
            }

            HStack {
                Text(model.speech.isListening ? "聞いています。もう一度押すと停止します。" : "Command+Return で送信")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
                Spacer()
                if let speechError = model.speech.errorMessage {
                    Text(speechError)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.error)
                }
                Button("置く") {
                    model.sendInput()
                }
                .buttonStyle(QuietButtonStyle())
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(model.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.isStreaming)
                Text("· \(model.messages.filter { $0.role == .user }.count)")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
            }
        }
        .frame(maxWidth: 680)
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(Theme.base)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.border).frame(height: 1)
        }
    }
}

struct DialogueBlock: View {
    let message: Message

    var body: some View {
        if message.role == .assistant {
            VStack(alignment: .leading, spacing: 16) {
                Rectangle()
                    .fill(Theme.border)
                    .frame(height: 1)
                    .opacity(0.8)
                Text(message.content.isEmpty ? " " : message.content)
                    .font(.system(size: 18, design: .serif))
                    .italic()
                    .lineSpacing(7)
                    .foregroundStyle(Theme.secondary)
                Rectangle()
                    .fill(Theme.border)
                    .frame(height: 1)
                    .opacity(0.8)
            }
        } else {
            Text(message.content)
                .font(.system(size: 19, design: .serif))
                .lineSpacing(8)
                .foregroundStyle(Theme.text)
        }
    }
}
