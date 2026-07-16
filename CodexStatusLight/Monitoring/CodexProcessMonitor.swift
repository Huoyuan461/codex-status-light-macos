import AppKit
import Foundation

@MainActor
struct CodexProcessMonitor {
    func isCodexAppServerRunning() -> Bool {
        if NSWorkspace.shared.runningApplications.contains(where: matchesRunningApplication(_:)) {
            return true
        }
        return processTableContainsCodex()
    }

    private func matchesRunningApplication(_ application: NSRunningApplication) -> Bool {
        let bundle = application.bundleIdentifier?.lowercased() ?? ""
        let name = application.localizedName?.lowercased() ?? ""
        return bundle.contains("codex") || name.contains("codex") || bundle == "com.openai.chat"
    }

    private func processTableContainsCodex() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-axo", "comm=,args="]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return false
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard !data.isEmpty, let output = String(data: data, encoding: .utf8)?.lowercased() else {
            return false
        }

        return output.contains("app-server")
            || output.contains("codex")
            || output.contains("com.openai.chat")
            || output.contains("chatgpt.app")
    }
}
