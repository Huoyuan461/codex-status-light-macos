import Foundation
import SQLite3

actor CodexSessionMonitor {
    private let fileManager = FileManager.default
    private var codexDirectory: URL?

    func latestSession(in directory: URL) -> CodexSessionSnapshot? {
        codexDirectory = directory
        if let row = latestSessionFromDatabase(), let snapshot = snapshot(from: row) {
            return snapshot
        }
        return latestSessionFromFiles()
    }

    private struct SessionRow {
        let id: String
        let title: String
        let cwd: String
        let rolloutPath: String
        let createdAt: Date
    }

    private func latestSessionFromDatabase() -> SessionRow? {
        guard let databaseURL = newestStateDatabase() else { return nil }
        var database: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX
        guard sqlite3_open_v2(databaseURL.path, &database, flags, nil) == SQLITE_OK, let database else {
            if database != nil { sqlite3_close(database) }
            return nil
        }
        defer { sqlite3_close(database) }

        let sql = "SELECT id, title, cwd, rollout_path, COALESCE(created_at_ms, created_at * 1000) FROM threads WHERE archived = 0 ORDER BY COALESCE(updated_at_ms, updated_at * 1000) DESC LIMIT 1"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK, let statement else { return nil }
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }

        return SessionRow(
            id: string(statement, column: 0),
            title: string(statement, column: 1),
            cwd: string(statement, column: 2),
            rolloutPath: string(statement, column: 3),
            createdAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 4) / 1000)
        )
    }

    private func newestStateDatabase() -> URL? {
        guard let codexDirectory else { return nil }
        guard let urls = try? fileManager.contentsOfDirectory(
            at: codexDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }
        return urls
            .filter { $0.lastPathComponent.hasPrefix("state_") && $0.pathExtension == "sqlite" }
            .max { modificationDate($0) < modificationDate($1) }
    }

    private func snapshot(from row: SessionRow) -> CodexSessionSnapshot? {
        let rolloutURL = URL(fileURLWithPath: NSString(string: row.rolloutPath).expandingTildeInPath)
        guard fileManager.fileExists(atPath: rolloutURL.path) else { return nil }
        let parsed = parseRollout(rolloutURL)
        return CodexSessionSnapshot(
            id: row.id,
            title: row.title.isEmpty ? "未命名 Codex 任务" : row.title,
            workingDirectory: row.cwd,
            rolloutPath: rolloutURL.path,
            startedAt: row.createdAt,
            lastActivityAt: parsed.date ?? modificationDate(rolloutURL),
            eventState: parsed.state
        )
    }

    private func latestSessionFromFiles() -> CodexSessionSnapshot? {
        guard let codexDirectory else { return nil }
        let sessions = codexDirectory.appendingPathComponent("sessions", isDirectory: true)
        guard let enumerator = fileManager.enumerator(
            at: sessions,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }

        var newest: URL?
        for case let url as URL in enumerator where url.pathExtension == "jsonl" {
            if newest == nil || modificationDate(url) > modificationDate(newest!) { newest = url }
        }
        guard let newest else { return nil }
        let parsed = parseRollout(newest)
        let attributes = try? fileManager.attributesOfItem(atPath: newest.path)
        let created = attributes?[.creationDate] as? Date ?? modificationDate(newest)
        let id = newest.deletingPathExtension().lastPathComponent.split(separator: "-").suffix(5).joined(separator: "-")
        return CodexSessionSnapshot(
            id: id,
            title: "最近的 Codex 任务",
            workingDirectory: "",
            rolloutPath: newest.path,
            startedAt: created,
            lastActivityAt: parsed.date ?? modificationDate(newest),
            eventState: parsed.state
        )
    }

    private func parseRollout(_ url: URL) -> (state: SessionEventState, date: Date?) {
        guard let data = try? Data(contentsOf: url, options: [.mappedIfSafe]),
              let content = String(data: data.suffix(512 * 1024), encoding: .utf8) else {
            return (.unknown, nil)
        }

        var lastDate: Date?
        var state: SessionEventState = .unknown
        let lines = content.split(separator: "\n", omittingEmptySubsequences: true).suffix(400)
        for line in lines {
            guard let lineData = line.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else { continue }
            if let timestamp = object["timestamp"] as? String,
               let date = timestampDate(timestamp) {
                lastDate = date
            }
            guard let type = object["type"] as? String,
                  let payload = object["payload"] as? [String: Any] else { continue }
            let payloadType = payload["type"] as? String ?? ""
            if type == "response_item", payloadType == "message",
               payload["role"] as? String == "assistant",
               payload["phase"] as? String == "final_answer" {
                state = .finalResponse
            } else if type == "event_msg", payloadType == "agent_message",
                      payload["phase"] as? String == "final_answer" {
                state = .finalResponse
            } else if ["reasoning", "custom_tool_call", "custom_tool_call_output", "function_call", "function_call_output"].contains(payloadType) {
                state = .active
            } else if type == "turn_context" || (type == "event_msg" && payloadType == "user_message") {
                state = .active
            }
        }
        return (state, lastDate)
    }

    private func modificationDate(_ url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
    }

    private func string(_ statement: OpaquePointer, column: Int32) -> String {
        guard let bytes = sqlite3_column_text(statement, column) else { return "" }
        return String(cString: bytes)
    }

    private func timestampDate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value)
    }
}
