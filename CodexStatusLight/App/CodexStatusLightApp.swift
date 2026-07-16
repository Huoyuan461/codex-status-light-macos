import SwiftUI

@main
struct CodexStatusLightApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model: CodexStatusModel

    init() {
        let model = CodexStatusModel()
        _model = State(initialValue: model)
        appDelegate.model = model
    }

    var body: some Scene {
        MenuBarExtra {
            StatusPanelView(model: model)
        } label: {
            StatusLightView(state: model.state, size: 8, startupPhase: model.startupAnimationPhase)
                .accessibilityLabel(model.state.title)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var model: CodexStatusModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NSApplication.shared.activate(ignoringOtherApps: true)
        return true
    }
}
