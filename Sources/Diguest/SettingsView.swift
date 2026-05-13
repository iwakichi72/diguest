import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(
                title: "設定",
                trailing: AnyView(
                    Button("戻る") {
                        model.goHome()
                    }
                    .buttonStyle(QuietButtonStyle())
                )
            )

            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(model.isOllamaReachable ? Theme.success : Theme.error)
                        .frame(width: 8, height: 8)
                    Text(model.isOllamaReachable ? "Ollamaに接続しています" : "Ollamaが見つかりません")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.secondary)
                    Button("再確認") {
                        Task { await model.refreshConnection() }
                    }
                    .buttonStyle(QuietButtonStyle())
                }

                settingField("Ollama URL", text: $model.config.ollamaBaseUrl)
                settingField("モデル", text: $model.config.ollamaModel)
                settingField("保存先", text: $model.config.notesDir)

                VStack(alignment: .leading, spacing: 10) {
                    Text("掘削の演出")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondary)

                    Toggle(isOn: $model.config.enableDigAnimation) {
                        Text("背景に地層と深度メーターを表示する")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.text)
                    }
                    .toggleStyle(.switch)
                    .tint(Theme.accent)

                    HStack(spacing: 14) {
                        Text("演出の強さ")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.muted)
                        ForEach(DigAnimationIntensity.allCases, id: \.self) { value in
                            Button {
                                model.config.digAnimationIntensity = value
                            } label: {
                                Text(intensityLabel(value))
                                    .font(.system(size: 12, design: .monospaced))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(model.config.digAnimationIntensity == value ? Theme.subtle : Color.clear)
                                    )
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(
                                                model.config.digAnimationIntensity == value ? Theme.borderFocus : Theme.border,
                                                lineWidth: 1
                                            )
                                    }
                                    .foregroundStyle(
                                        model.config.digAnimationIntensity == value ? Theme.text : Theme.secondary
                                    )
                            }
                            .buttonStyle(.plain)
                            .disabled(!model.config.enableDigAnimation)
                        }
                    }
                    .opacity(model.config.enableDigAnimation ? 1 : 0.55)
                }

                Button("保存") {
                    model.saveSettings()
                }
                .buttonStyle(QuietButtonStyle(prominent: true))

                if let error = model.errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.error)
                }
            }
            .frame(maxWidth: 680, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.top, 64)

            Spacer()
        }
    }

    private func intensityLabel(_ value: DigAnimationIntensity) -> String {
        switch value {
        case .minimal: return "minimal"
        case .normal: return "normal"
        case .rich: return "rich"
        }
    }

    private func settingField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondary)
            TextField("", text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(Theme.text)
                .padding(12)
                .background(Theme.subtle)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Theme.border, lineWidth: 1)
                }
        }
    }
}

