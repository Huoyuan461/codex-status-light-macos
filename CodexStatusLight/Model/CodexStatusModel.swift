import AppKit
import Observation
import ServiceManagement
import SwiftUI

@MainActor
@Observable
final class CodexStatusModel {
    private(set) var state: CodexActivityState = .idle
    private(set) var snapshot: CodexSessionSnapshot?
    private(set) var processIsRunning = false
    private(set) var lastCheckedAt = Date()
    private(set) var hasCodexDirectoryAccess = false
    private(set) var startupAnimationPhase: Int = 0
    var displayMode: DisplayMode {
        didSet {
            UserDefaults.standard.set(displayMode.rawValue, forKey: Self.displayModeKey)
            UserDefaults.standard.set(true, forKey: "didChooseDisplayMode")
            updateFloatingWindow()
        }
    }
    var launchAtLoginEnabled = false

    private let processMonitor = CodexProcessMonitor()
    private let sessionMonitor = CodexSessionMonitor()
    private let directoryAccess = CodexDirectoryAccess()
    private let fileMonitor = CodexFileMonitor()
    private let resolver = StatusResolver()
    private var monitoringTask: Task<Void, Never>?
    private var floatingController: FloatingLightController?
    private static let displayModeKey = "displayMode"

    init() {
        displayMode = DisplayMode(rawValue: UserDefaults.standard.string(forKey: Self.displayModeKey) ?? "") ?? .notch
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
        hasCodexDirectoryAccess = directoryAccess.directoryURL != nil
        Task { [weak self] in await self?.playStartupAnimation() }
        monitoringTask = Task { [weak self] in await self?.monitorContinuously() }
        Task { @MainActor [weak self] in self?.updateFloatingWindow() }
    }

    func refreshNow() {
        Task { await refresh() }
    }

    func showPositionChooser() {
        NotificationCenter.default.post(name: .showCodexStatusSetup, object: nil)
    }

    func chooseCodexDirectory() {
        hasCodexDirectoryAccess = directoryAccess.chooseDirectory() != nil
        refreshNow()
    }

    func openCodex() {
        let candidates = ["/Applications/Codex.app", "/Applications/ChatGPT.app"]
        if let path = candidates.first(where: { FileManager.default.fileExists(atPath: $0) }) {
            NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: path), configuration: .init())
        }
    }

    func openWorkingDirectory() {
        guard let path = snapshot?.workingDirectory, !path.isEmpty else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }

    func closePlugin() {
        displayMode = .menuBar
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
        } catch {
            launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
        }
    }

    private func monitorContinuously() async {
        while !Task.isCancelled {
            await refresh()
            try? await Task.sleep(for: .seconds(1))
        }
    }

    private func refresh() async {
        let newSnapshot: CodexSessionSnapshot?
        if let directory = directoryAccess.resolvedDirectoryURL() {
            fileMonitor.updateMonitoredPaths(
                [
                    directory,
                    directory.appendingPathComponent("sqlite", isDirectory: true),
                    directory.appendingPathComponent("sessions", isDirectory: true),
                    directory.appendingPathComponent("archived_sessions", isDirectory: true)
                ],
                onChange: { [weak self] in
                    Task { @MainActor in
                        self?.refreshNow()
                    }
                }
            )
            newSnapshot = await sessionMonitor.latestSession(in: directory)
        } else {
            fileMonitor.stop()
            newSnapshot = nil
        }
        let shouldCheckProcess = Int(Date().timeIntervalSince1970) % 2 == 0 || !processIsRunning
        let running = shouldCheckProcess ? processMonitor.isCodexAppServerRunning() : processIsRunning
        processIsRunning = running
        snapshot = newSnapshot
        state = resolver.resolve(processIsRunning: running, snapshot: newSnapshot, previousState: state)
        hasCodexDirectoryAccess = directoryAccess.resolvedDirectoryURL() != nil
        lastCheckedAt = Date()
        floatingController?.update(state: state)
    }

    private func updateFloatingWindow() {
        if displayMode == .menuBar {
            floatingController?.hide()
            floatingController = nil
        } else {
            if floatingController == nil {
                floatingController = FloatingLightController(state: state, mode: displayMode, startupPhase: startupAnimationPhase)
            }
            floatingController?.setMode(displayMode)
            floatingController?.updateStartupPhase(startupAnimationPhase)
            floatingController?.show()
        }
    }

    private func playStartupAnimation() async {
        try? await Task.sleep(for: .milliseconds(120))
        let phases = [1, 2, 3, 4]
        for phase in phases {
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.18)) {
                startupAnimationPhase = phase
            }
            floatingController?.updateStartupPhase(phase)
            if phase < 4 {
                try? await Task.sleep(for: .milliseconds(140))
            }
        }
    }
}
