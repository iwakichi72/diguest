import SwiftUI

struct SessionView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isFocused: Bool
    @State private var showEndConfirmation = false

    var body: some View {
        ZStack {
            if model.config.enableDigAnimation {
                DigBackgroundView(
                    depth: model.digDepth,
                    pulseTick: model.digPulseTick,
                    transitionTick: model.digTransitionTick,
                    transitionStrength: model.digTransitionStrength,
                    enabled: model.config.enableDigAnimation,
                    intensity: model.config.digAnimationIntensity
                )
                .ignoresSafeArea()
                .transition(.opacity)
            }

            sessionStack
                .digSink(
                    tick: model.digTransitionTick,
                    strength: model.digTransitionStrength * model.config.digAnimationIntensity.multiplier,
                    reduceMotion: reduceMotion || !model.config.enableDigAnimation
                )

            if model.config.enableDigAnimation {
                VStack {
                    HStack {
                        Spacer()
                        DepthMeterView(
                            depth: model.digDepth,
                            transitionTick: model.digTransitionTick
                        )
                        .padding(.trailing, 18)
                        .padding(.top, 78)
                    }
                    Spacer()
                }
                .allowsHitTesting(false)
                .transition(.opacity)
            }
        }
    }

    private var sessionStack: some View {
        VStack(spacing: 0) {
            HeaderBar(
                title: model.theme,
                trailing: AnyView(
                    Button(model.isGeneratingMarkdown ? "まとめています..." : "ここで終える") {
                        if model.isGeneratingMarkdown { return }
                        showEndConfirmation = true
                    }
                    .buttonStyle(QuietButtonStyle())
                    .disabled(model.isStreaming || model.isGeneratingMarkdown || showEndConfirmation)
                )
            )

            if showEndConfirmation {
                endConfirmationBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 34) {
                        if !model.seedText.isEmpty {
                            SeedBlock(text: model.seedText)
                                .id("seed")
                        }

                        ForEach(model.choiceTurns) { turn in
                            ChoiceTurnBlock(
                                turn: turn,
                                isActive: isActive(turn),
                                pendingChoice: pendingChoice(for: turn),
                                manualAnswerMode: model.manualAnswerMode,
                                onSelect: model.selectOption,
                                onConfirm: model.confirmPendingChoice,
                                onEdit: model.editPendingChoice
                            )
                            .id(turn.id)
                        }

                        if model.isStreaming {
                            GeneratingChoiceBlock()
                                .id("choice-streaming")
                                .transition(.opacity.combined(with: .scale(scale: 0.985, anchor: .topLeading)))
                        }

                        if model.isGeneratingMarkdown {
                            MarkdownAssemblyView()
                                .id("markdown-assembly")
                                .transition(.opacity.combined(with: .scale(scale: 0.985, anchor: .topLeading)))
                        }

                        if let error = model.errorMessage {
                            SessionErrorCard(detail: error) {
                                model.retryStreaming()
                            }
                            .quietReveal(duration: MotionToken.base, blur: 1)
                        }
                    }
                    .frame(maxWidth: 680, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.top, 56)
                    .padding(.bottom, 24)
                }
                .onChange(of: model.choiceTurns) { _ in
                    if let last = model.choiceTurns.last {
                        withAnimation(MotionToken.animation(MotionToken.scroll, reduceMotion: reduceMotion)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: model.isStreaming) { isStreaming in
                    if isStreaming {
                        withAnimation(MotionToken.animation(MotionToken.scroll, reduceMotion: reduceMotion)) {
                            proxy.scrollTo("choice-streaming", anchor: .bottom)
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
        .animation(MotionToken.animation(MotionToken.base, reduceMotion: reduceMotion), value: showEndConfirmation)
        .onAppear {
            isFocused = true
        }
        .onChange(of: model.screen) { _ in
            showEndConfirmation = false
        }
    }

    private var endConfirmationBar: some View {
        HStack(spacing: 14) {
            Text("今日はここで終えますか？")
                .font(.system(size: 13))
                .foregroundStyle(Theme.text)
            Spacer()
            Button("掘り続ける") {
                showEndConfirmation = false
            }
            .buttonStyle(QuietButtonStyle())
            .keyboardShortcut(.cancelAction)

            Button("終える") {
                showEndConfirmation = false
                model.endSession()
            }
            .buttonStyle(QuietButtonStyle(prominent: true))
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 12)
        .background(Theme.subtle)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.border).frame(height: 1)
        }
    }

    private var inputArea: some View {
        if !isEditorVisible {
            return AnyView(statusArea)
        }

        return AnyView(editorArea)
    }

    private var editorArea: some View {
        VStack(spacing: 8) {
            if showThemeReminder {
                HStack {
                    Text("テーマ ・ \(model.theme)")
                        .font(.system(size: 11, design: .serif))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                }
            }

            ZStack(alignment: .topTrailing) {
                TextEditor(text: $model.input)
                    .font(.system(size: 18, design: .serif))
                    .foregroundStyle(Theme.text)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(minHeight: 118, maxHeight: 260)
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
                Text(helperText)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
                Spacer()
                if let speechError = model.speech.errorMessage {
                    Text(speechError)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.error)
                        .quietReveal(duration: MotionToken.base, blur: 1)
                }
                if canCancelManualInput {
                    Button("戻る") {
                        model.cancelManualAnswer()
                    }
                    .buttonStyle(QuietButtonStyle())
                    .disabled(model.isStreaming || model.isGeneratingMarkdown)
                }
                Button("掘る") {
                    model.sendInput()
                }
                .buttonStyle(QuietButtonStyle())
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(
                    model.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || model.isStreaming
                        || model.isGeneratingMarkdown
                )
                Text("· \(answerCount)")
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

    private var statusArea: some View {
        HStack {
            Text(statusText)
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
            Spacer()
            Text("· \(answerCount)")
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: 680)
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(Theme.base)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.border).frame(height: 1)
        }
    }

    private var isEditorVisible: Bool {
        guard !model.isGeneratingMarkdown else { return false }
        return (model.choiceTurns.isEmpty && !model.isStreaming) || model.manualAnswerMode != nil
    }

    private var showThemeReminder: Bool {
        guard !model.theme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        return !model.seedText.isEmpty || !model.choiceTurns.isEmpty
    }

    private var helperText: String {
        if model.speech.isListening {
            return "聞いています。もう一度押すと停止します。"
        }

        switch model.manualAnswerMode {
        case .edit:
            return "少し直して Command+Return で掘る"
        case .freeWrite:
            return "自由記述を Command+Return で掘る"
        case nil:
            return "最初の言葉を Command+Return で掘る"
        }
    }

    private var statusText: String {
        if model.isStreaming {
            return "問いを整えています"
        }

        if model.pendingChoice != nil {
            return "選んだ言葉でこのまま掘るか、少し直せます"
        }

        return "近いものを選びます"
    }

    private var answerCount: Int {
        ChoiceTurnLogBuilder.answeredTurnCount(seedText: model.seedText, turns: model.choiceTurns)
    }

    private var canCancelManualInput: Bool {
        guard model.manualAnswerMode != nil else { return false }
        return model.choiceTurns.last?.options.isEmpty == false
    }

    private func isActive(_ turn: ChoiceTurn) -> Bool {
        model.choiceTurns.last?.id == turn.id
            && turn.answer == nil
            && !model.isStreaming
            && !model.isGeneratingMarkdown
    }

    private func pendingChoice(for turn: ChoiceTurn) -> ChoiceOption? {
        guard isActive(turn) else { return nil }
        return model.pendingChoice
    }
}

struct SeedBlock: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 19, design: .serif))
            .lineSpacing(8)
            .foregroundStyle(Theme.text)
            .quietReveal(duration: MotionToken.base, blur: 1)
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

struct ChoiceTurnBlock: View {
    let turn: ChoiceTurn
    let isActive: Bool
    let pendingChoice: ChoiceOption?
    let manualAnswerMode: ManualAnswerMode?
    let onSelect: (ChoiceOption) -> Void
    let onConfirm: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)
                .opacity(0.8)
                .quietRuleReveal(delay: 0.02)

            Text(turn.question)
                .font(.system(size: 18, design: .serif))
                .italic()
                .lineSpacing(7)
                .foregroundStyle(Theme.secondary)
                .quietReveal(delay: 0.08, duration: MotionToken.slow, blur: 1.5)

            if !turn.options.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(turn.options) { option in
                        ChoiceOptionRow(
                            option: option,
                            isEnabled: isActive && pendingChoice == nil && manualAnswerMode == nil,
                            isPending: pendingChoice?.id == option.id
                        ) {
                            onSelect(option)
                        }
                    }
                }
                .quietReveal(delay: 0.12, duration: MotionToken.slow, blur: 1.5)
            }

            if let pendingChoice {
                PendingChoiceConfirmation(
                    option: pendingChoice,
                    onConfirm: onConfirm,
                    onEdit: onEdit
                )
                .quietReveal(duration: MotionToken.base, blur: 1)
            }

            if let answer = turn.answer {
                Text(ChoiceTurnLogBuilder.answerText(for: answer))
                    .font(.system(size: 17, design: .serif))
                    .lineSpacing(7)
                    .foregroundStyle(Theme.text)
                    .padding(.top, 4)
                    .quietReveal(duration: MotionToken.base, blur: 1)
            }

            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)
                .opacity(0.8)
                .quietRuleReveal(delay: 0.12)
        }
        .quietReveal(duration: MotionToken.slow, blur: 1)
    }
}

private struct ChoiceOptionRow: View {
    let option: ChoiceOption
    let isEnabled: Bool
    let isPending: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if option.isFreeWrite {
                Rectangle()
                    .fill(Theme.border.opacity(0.45))
                    .frame(height: 1)
                    .padding(.top, 2)
            }

            Button(action: action) {
                HStack(alignment: .firstTextBaseline, spacing: 13) {
                    Text("\(option.index)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(option.isFreeWrite ? Theme.accent.opacity(0.7) : Theme.secondary)
                        .frame(width: 18, alignment: .leading)

                    Text(option.isFreeWrite ? "あるいは、自分の言葉で書く" : option.text)
                        .font(.system(size: 16, design: .serif))
                        .italic(option.isFreeWrite)
                        .lineSpacing(5)
                        .foregroundStyle(option.isFreeWrite ? Theme.secondary : Theme.text)

                    Spacer(minLength: 12)
                }
                .padding(.vertical, 11)
                .padding(.horizontal, 12)
                .background(isPending ? Theme.subtle : Color.clear)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isPending ? Theme.borderFocus : Theme.border, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
            .opacity(isEnabled || isPending ? 1 : 0.58)
        }
    }
}

private struct PendingChoiceConfirmation: View {
    let option: ChoiceOption
    let onConfirm: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("選択: \(option.index). \(option.text)")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(Theme.text)
                .lineSpacing(5)

            HStack(spacing: 18) {
                Button("このまま掘る", action: onConfirm)
                    .buttonStyle(QuietButtonStyle(prominent: true))
                Button("少し直す", action: onEdit)
                    .buttonStyle(QuietButtonStyle())
            }
        }
        .padding(.top, 2)
    }
}

private struct GeneratingChoiceBlock: View {
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("問いを整えています")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Theme.secondary)
            StreamingCursor()
                .frame(width: 8)
        }
        .quietReveal(duration: MotionToken.base, blur: 1)
    }
}

private struct MarkdownAssemblyView: View {
    var body: some View {
        PaperAssemblyView()
            .quietReveal(duration: 0.44, blur: 4, scale: 0.985)
    }
}

private struct SessionErrorCard: View {
    let detail: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Theme.error)
                    .frame(width: 7, height: 7)
                Text("接続が切れました")
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(Theme.text)
            }

            Text("Ollama との接続が途切れました。対話内容はまだ残っています。接続を確認してください。")
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if !detail.isEmpty {
                Text(detail)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button("もう一度試す", action: onRetry)
                .buttonStyle(QuietButtonStyle())
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
