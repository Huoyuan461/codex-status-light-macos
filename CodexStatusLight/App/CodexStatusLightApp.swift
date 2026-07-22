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
            BrandBadgeView()
                .accessibilityLabel("Codex Status Light")
        }
        .menuBarExtraStyle(.window)
    }
}

private struct BrandBadgeView: View {
    var body: some View {
        HStack(spacing: 3) {
            Capsule().fill(Color.white.opacity(0.92)).frame(width: 5, height: 5)
            Capsule().fill(Color.white.opacity(0.72)).frame(width: 5, height: 5)
            Capsule().fill(Color.white.opacity(0.92)).frame(width: 5, height: 5)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(.black.opacity(0.84))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var model: CodexStatusModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        appDidLaunch()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NSApplication.shared.activate(ignoringOtherApps: true)
        return true
    }

    private func appDidLaunch() {
        model?.beginLaunchAnimation()
    }
}
