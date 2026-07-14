import AppKit

@MainActor
struct CodexProcessMonitor {
    func isCodexAppServerRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains { application in
            let bundle = application.bundleIdentifier?.lowercased() ?? ""
            let name = application.localizedName?.lowercased() ?? ""
            return bundle.contains("codex") || name == "codex" || bundle == "com.openai.chat"
        }
    }
}
