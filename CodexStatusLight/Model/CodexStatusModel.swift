import AppKit
import Observation
import ServiceManagement

@MainActor
@Observable
final class CodexStatusModel {
    private(set) var state: CodexActivityState = .idle
    private(set) var snapshot: CodexSessionSnapshot?
    private(set) var processIsRunning = false
    private(set) var lastCheckedAt = Date()
    private(set) var hasCodexDirectoryAccess = false
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
    private let resolver = StatusResolver()
    private var monitoringTask: Task<Void, Never>?
    private var floatingController: FloatingLightController?
    private static let displayModeKey = "displayMode"

    init() {
        displayMode = DisplayMode(rawValue: UserDefaults.standard.string(forKey: Self.displayModeKey) ?? "") ?? .notch
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
        hasCodexDirectoryAccess = directoryAccess.directoryURL != nil
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
        guard let directory = directoryAccess.directoryURL else {
            snapshot = nil
            state = .idle
            hasCodexDirectoryAccess = false
            return
        }
        let newSnapshot = await sessionMonitor.latestSession(in: directory)
        let shouldCheckProcess = Int(Date().timeIntervalSince1970) % 2 == 0 || !processIsRunning
        let running = shouldCheckProcess ? processMonitor.isCodexAppServerRunning() : processIsRunning
        processIsRunning = running
        snapshot = newSnapshot
        state = resolver.resolve(processIsRunning: running, snapshot: newSnapshot, previousState: state)
        lastCheckedAt = Date()
        floatingController?.update(state: state)
    }

    private func updateFloatingWindow() {
        if displayMode == .menuBar {
            floatingController?.hide()
            floatingController = nil
        } else {
            if floatingController == nil {
                floatingController = FloatingLightController(state: state, mode: displayMode)
            }
            floatingController?.setMode(displayMode)
            floatingController?.show()
        }
    }
}
