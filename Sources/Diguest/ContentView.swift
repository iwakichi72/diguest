import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack {
            Theme.surface.ignoresSafeArea()

            switch model.screen {
            case .home:
                HomeView()
            case .themeEntry:
                ThemeEntryView()
            case .session:
                SessionView()
            case .preview:
                PreviewView()
            case .note(let note):
                NoteView(note: note)
            case .settings:
                SettingsView()
            }
        }
        .foregroundStyle(Theme.text)
    }
}

enum Theme {
    static let base = Color(red: 0.067, green: 0.063, blue: 0.035)
    static let surface = Color(red: 0.102, green: 0.094, blue: 0.078)
    static let subtle = Color(red: 0.141, green: 0.125, blue: 0.094)
    static let border = Color(red: 0.173, green: 0.157, blue: 0.125)
    static let borderFocus = Color(red: 0.353, green: 0.314, blue: 0.251)
    static let text = Color(red: 0.929, green: 0.910, blue: 0.882)
    static let secondary = Color(red: 0.478, green: 0.455, blue: 0.408)
    static let muted = Color(red: 0.267, green: 0.243, blue: 0.220)
    static let accent = Color(red: 0.769, green: 0.584, blue: 0.416)
    static let error = Color(red: 0.545, green: 0.361, blue: 0.361)
    static let success = Color(red: 0.361, green: 0.545, blue: 0.431)
}

struct QuietButtonStyle: ButtonStyle {
    var prominent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(prominent ? Theme.base : Theme.secondary)
            .padding(.horizontal, prominent ? 16 : 0)
            .padding(.vertical, prominent ? 9 : 0)
            .background(prominent ? Theme.accent.opacity(configuration.isPressed ? 0.75 : 1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

struct HeaderBar: View {
    @EnvironmentObject private var model: AppModel
    let title: String
    var trailing: AnyView?

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)
            Spacer()
            if let trailing {
                trailing
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(Theme.base)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.border).frame(height: 1)
        }
    }
}

