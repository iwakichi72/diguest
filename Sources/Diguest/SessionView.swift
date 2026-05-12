import SwiftUI

struct SessionView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                            DialogueBlock(
                                message: message,
                                isStreaming: model.isStreaming && model.messages.last?.id == message.id
                            )
                            .id(message.id)
                        }

                        if model.isGeneratingMarkdown {
                            MarkdownAssemblyView()
                                .id("markdown-assembly")
                                .transition(.opacity)
                        }

                        if let error = model.errorMessage {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.error)
                                .quietReveal(duration: MotionToken.base, blur: 1)
                        }
                    }
                    .frame(maxWidth: 680, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.top, 56)
                    .padding(.bottom, 24)
                }
                .onChange(of: model.messages) { _ in
                    if let last = model.messages.last {
                        withAnimation(MotionToken.animation(MotionToken.scroll, reduceMotion: reduceMotion)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: model.isGeneratingMarkdown) { isGenerating in
                    if isGenerating {
                        withAnimation(MotionToken.animation(MotionToken.scroll, reduceMotion: reduceMotion)) {
                            proxy.scrollTo("markdown-assembly", anchor: .bottom)
                        }
                    }
                }
            }

            inputArea
        }
        .animation(MotionToken.animation(MotionToken.base, reduceMotion: reduceMotion), value: model.isGeneratingMarkdown)
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
                        ZStack {
                            ListeningPulse(isActive: model.speech.isListening)
                                .frame(width: 30, height: 30)
                            Image(systemName: model.speech.isListening ? "mic.fill" : "mic")
                                .frame(width: 30, height: 30)
                        }
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
                        .quietReveal(duration: MotionToken.base, blur: 1)
                }
                Button("置く") {
                    model.sendInput()
                }
                .buttonStyle(QuietButtonStyle())
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(
                    model.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || model.isStreaming
                        || model.isGeneratingMarkdown
                )
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
    let isStreaming: Bool

    var body: some View {
        if message.role == .assistant {
            VStack(alignment: .leading, spacing: 16) {
                Rectangle()
                    .fill(Theme.border)
                    .frame(height: 1)
                    .opacity(0.8)
                    .quietRuleReveal(delay: 0.02)

                HStack(alignment: .top, spacing: 5) {
                    Text(message.content)
                        .font(.system(size: 18, design: .serif))
                        .italic()
                        .lineSpacing(7)
                        .foregroundStyle(Theme.secondary)

                    if isStreaming {
                        StreamingCursor()
                            .padding(.top, 2)
                    }
                }
                .quietReveal(delay: 0.08, duration: MotionToken.slow, blur: 1.5)

                Rectangle()
                    .fill(Theme.border)
                    .frame(height: 1)
                    .opacity(0.8)
                    .quietRuleReveal(delay: 0.12)
            }
            .quietReveal(duration: MotionToken.slow, blur: 1)
        } else {
            Text(message.content)
                .font(.system(size: 19, design: .serif))
                .lineSpacing(8)
                .foregroundStyle(Theme.text)
                .quietReveal(duration: MotionToken.base, blur: 1)
        }
    }
}

private struct MarkdownAssemblyView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MarkdownGenerationTrace()
                .frame(maxWidth: 260)
            Text("Markdown")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.muted)
        }
        .quietReveal(duration: MotionToken.slow, blur: 1)
    }
}
