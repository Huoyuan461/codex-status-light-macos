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

        Window("Codex Status Light", id: Self.mainWindowID) {
            MainWindowView(model: model)
        }
        .defaultSize(width: 420, height: 560)
    }

    static let mainWindowID = "main-window"
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

private struct MainWindowView: View {
    @Bindable var model: CodexStatusModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                StatusLightView(state: model.state, size: 12, animated: false)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Codex Status Light").font(.title3.bold())
                    Text("主窗口可从 Window 菜单重新打开").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("立即刷新") { model.refreshNow() }
            }

            Divider()
            StatusPanelView(model: model)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(20)
    }
}
