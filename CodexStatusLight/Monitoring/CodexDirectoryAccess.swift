import AppKit
import Foundation

@MainActor
final class CodexDirectoryAccess {
    private static let bookmarkKey = "codexDirectoryBookmark"
    private(set) var directoryURL: URL?
    private var isAccessing = false

    init() {
        restoreBookmark()
        if directoryURL == nil {
            directoryURL = autoLocateCodexDirectory()
        }
    }

    deinit {
        if isAccessing { directoryURL?.stopAccessingSecurityScopedResource() }
    }

    func resolvedDirectoryURL() -> URL? {
        if directoryURL == nil {
            directoryURL = autoLocateCodexDirectory()
        }
        return directoryURL
    }

    func chooseDirectory() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "选择 Codex 数据文件夹"
        panel.message = "请选择个人目录中的 .codex 文件夹。应用只会读取会话状态。"
        panel.prompt = "授权只读访问"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser

        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        guard url.lastPathComponent == ".codex" else {
            let alert = NSAlert()
            alert.messageText = "请选择 .codex 文件夹"
            alert.informativeText = "通常位于你的个人目录：~/.codex"
            alert.runModal()
            return nil
        }
        saveBookmark(for: url)
        return directoryURL
    }

    private func saveBookmark(for url: URL) {
        if isAccessing { directoryURL?.stopAccessingSecurityScopedResource() }
        do {
            let data = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(data, forKey: Self.bookmarkKey)
            directoryURL = url
            isAccessing = url.startAccessingSecurityScopedResource()
        } catch {
            directoryURL = nil
            isAccessing = false
        }
    }

    private func restoreBookmark() {
        guard let data = UserDefaults.standard.data(forKey: Self.bookmarkKey) else { return }
        var stale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        ) else { return }
        directoryURL = url
        isAccessing = url.startAccessingSecurityScopedResource()
        if stale { saveBookmark(for: url) }
    }

    private func autoLocateCodexDirectory() -> URL? {
        let candidate = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex", isDirectory: true)
        guard FileManager.default.fileExists(atPath: candidate.path) else { return nil }
        return candidate
    }
}
