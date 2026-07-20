import AppKit
import SwiftUI

@MainActor
final class FloatingLightController: NSWindowController, NSWindowDelegate {
    private var state: CodexActivityState
    private var mode: DisplayMode
    private var startupPhase: Int
    private static let positionKey = "floatingLightOrigin"

    init(state: CodexActivityState, mode: DisplayMode, startupPhase: Int) {
        self.state = state
        self.mode = mode
        self.startupPhase = startupPhase
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 112, height: 44),
            styleMask: [.titled, .fullSizeContentView, .closable],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = mode == .desktop
        window.hidesOnDeactivate = false
        window.contentView = NSHostingView(rootView: FloatingLightContent(state: state, startupPhase: startupPhase) { [weak self] in
            self?.hide()
        })
        window.delegate = self
        placeWindow()
    }

    required init?(coder: NSCoder) { nil }

    func show() {
        window?.alphaValue = 1
        window?.orderFrontRegardless()
        window?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    func hide() { window?.orderOut(nil) }

    func update(state: CodexActivityState) {
        guard self.state != state else { return }
        self.state = state
        refreshContent()
    }

    func setMode(_ mode: DisplayMode) {
        guard self.mode != mode else { return }
        self.mode = mode
        window?.isMovableByWindowBackground = mode == .desktop
        placeWindow()
        refreshContent()
    }

    func updateStartupPhase(_ startupPhase: Int) {
        self.startupPhase = startupPhase
        refreshContent()
    }

    func windowDidMove(_ notification: Notification) {
        guard mode == .desktop, let origin = window?.frame.origin else { return }
        UserDefaults.standard.set(NSStringFromPoint(origin), forKey: Self.positionKey)
    }

    private func placeWindow() {
        guard let window else { return }
        if mode == .desktop, let stored = UserDefaults.standard.string(forKey: Self.positionKey) {
            let origin = NSPointFromString(stored)
            let proposedFrame = NSRect(origin: origin, size: window.frame.size)
            if let screen = screenContaining(frame: proposedFrame) {
                let clampedOrigin = clamp(origin: origin, into: screen.visibleFrame, size: window.frame.size)
                window.setFrameOrigin(clampedOrigin)
                return
            }
        }
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
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

    private func screenContaining(frame: NSRect) -> NSScreen? {
        NSScreen.screens.first { $0.frame.intersects(frame) || $0.visibleFrame.intersects(frame) }
    }

    private func clamp(origin: NSPoint, into visibleFrame: NSRect, size: NSSize) -> NSPoint {
        let minX = visibleFrame.minX + 8
        let maxX = max(minX, visibleFrame.maxX - size.width - 8)
        let minY = visibleFrame.minY + 8
        let maxY = max(minY, visibleFrame.maxY - size.height - 8)
        return NSPoint(
            x: min(max(origin.x, minX), maxX),
            y: min(max(origin.y, minY), maxY)
        )
    }

    private func refreshContent() {
        guard let window else { return }
        window.contentView = NSHostingView(rootView: FloatingLightContent(state: state, startupPhase: startupPhase) { [weak self] in
            self?.hide()
        })
    }
}

private struct FloatingLightContent: View {
    let state: CodexActivityState
    var startupPhase: Int = 4
    let closeAction: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            StatusLightView(state: state, size: 20, startupPhase: startupPhase)
                .padding(4)
                .help(state.title)

            Button(action: closeAction) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.86))
                    .padding(5)
                    .background(.black.opacity(0.28), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(3)
            .accessibilityLabel("关闭插件")
        }
    }
}
