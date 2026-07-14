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
            StatusLightView(state: model.state, size: 8)
                .accessibilityLabel(model.state.title)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var model: CodexStatusModel?
    private var setupWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let model else { return }
        if !UserDefaults.standard.bool(forKey: "didChooseDisplayMode") {
            showSetupWindow(model: model)
        }
        NotificationCenter.default.addObserver(
            forName: .showCodexStatusSetup,
            object: nil,
            queue: .main
        ) { [weak self, weak model] _ in
            MainActor.assumeIsolated {
                if let model { self?.showSetupWindow(model: model) }
            }
        }
    }

    private func showSetupWindow(model: CodexStatusModel) {
        if let setupWindow {
            setupWindow.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 390),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Codex 红绿灯设置"
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(rootView: DisplayModeSetupView(model: model) { [weak window] in
            window?.close()
        })
        setupWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}

extension Notification.Name {
    static let showCodexStatusSetup = Notification.Name("showCodexStatusSetup")
}
