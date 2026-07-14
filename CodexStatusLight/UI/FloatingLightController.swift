import AppKit
import SwiftUI

@MainActor
final class FloatingLightController: NSWindowController, NSWindowDelegate {
    private var state: CodexActivityState
    private var mode: DisplayMode
    private static let positionKey = "floatingLightOrigin"

    init(state: CodexActivityState, mode: DisplayMode) {
        self.state = state
        self.mode = mode
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 112, height: 44),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = mode == .desktop
        window.contentView = NSHostingView(rootView: FloatingLightContent(state: state))
        window.delegate = self
        placeWindow()
    }

    required init?(coder: NSCoder) { nil }

    func show() { window?.orderFrontRegardless() }
    func hide() { window?.orderOut(nil) }

    func update(state: CodexActivityState) {
        guard self.state != state else { return }
        self.state = state
        window?.contentView = NSHostingView(rootView: FloatingLightContent(state: state))
    }

    func setMode(_ mode: DisplayMode) {
        guard self.mode != mode else { return }
        self.mode = mode
        window?.isMovableByWindowBackground = mode == .desktop
        placeWindow()
    }

    func windowDidMove(_ notification: Notification) {
        guard mode == .desktop, let origin = window?.frame.origin else { return }
        UserDefaults.standard.set(NSStringFromPoint(origin), forKey: Self.positionKey)
    }

    private func placeWindow() {
        guard let window else { return }
        if mode == .desktop, let stored = UserDefaults.standard.string(forKey: Self.positionKey) {
            window.setFrameOrigin(NSPointFromString(stored))
            return
        }
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let topInset = max(0, screen.frame.maxY - visible.maxY)
        let x: CGFloat
        let y: CGFloat
        if mode == .notch {
            x = screen.frame.midX + (topInset > 28 ? 95 : 55)
            y = screen.frame.maxY - window.frame.height - max(2, topInset * 0.12)
        } else {
            x = visible.maxX - window.frame.width - 24
            y = visible.maxY - window.frame.height - 24
        }
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

private struct FloatingLightContent: View {
    let state: CodexActivityState

    var body: some View {
        StatusLightView(state: state, size: 20)
            .padding(4)
            .help(state.title)
    }
}
