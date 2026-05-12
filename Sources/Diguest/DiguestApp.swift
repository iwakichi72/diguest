import SwiftUI

@main
struct DiguestApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Diguest") {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 760, minHeight: 640)
                .task {
                    await model.bootstrap()
                }
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("新しいセッション") {
                    model.showThemeEntry()
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
    }
}
