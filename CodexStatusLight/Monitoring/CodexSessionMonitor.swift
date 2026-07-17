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

        let sql = "SELECT id, title, cwd, rollout_path, COALESCE(created_at_ms, created_at * 1000) FROM threads ORDER BY COALESCE(updated_at_ms, updated_at * 1000) DESC LIMIT 1"
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
        let candidates = [
            codexDirectory.appendingPathComponent("sessions", isDirectory: true),
            codexDirectory.appendingPathComponent("archived_sessions", isDirectory: true)
        ]
        let newest = candidates
            .compactMap { latestRolloutFile(in: $0) }
            .max { modificationDate($0) < modificationDate($1) }
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
        let lines = content.split(separator: "\n", omittingEmptySubsequences: true).suffix(400)
        for line in lines.reversed() {
            guard let lineData = line.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else { continue }
            let eventType = object["type"] as? String ?? ""
            let payload = object["payload"] as? [String: Any] ?? [:]
            let payloadType = stringValue(payload["type"])
            let phase = stringValue(payload["phase"])
            let timestampDate = (object["timestamp"] as? String).flatMap { self.timestampDate($0) }
            if lastDate == nil, let timestampDate {
                lastDate = timestampDate
            }
            if isFinalResponseEvent(eventType: eventType, payload: payload, payloadType: payloadType, phase: phase) || (eventType == "event_msg" && payloadType == "task_complete") {
                return (.finalResponse, timestampDate ?? lastDate)
            }
            if isActivityEvent(eventType: eventType, payload: payload, payloadType: payloadType, phase: phase) {
                return (.active, timestampDate ?? lastDate)
            }
        }
        return (.unknown, lastDate)
    }

    private func isFinalResponseEvent(eventType: String, payload: [String: Any], payloadType: String, phase: String) -> Bool {
        if phase == "final_answer" {
            return true
        }
        if eventType == "response_item", payloadType == "message", stringValue(payload["role"]) == "assistant" {
            return phase == "final_answer"
        }
        if eventType == "response_item", payload["completed_at"] != nil {
            return true
        }
        return false
    }

    private func isActivityEvent(eventType: String, payload: [String: Any], payloadType: String, phase: String) -> Bool {
        if eventType == "event_msg" {
            return phase != "final_answer" && payloadType != "task_complete" && payloadType != "task_started"
        }
        if eventType == "turn_context" || eventType == "world_state" || eventType == "session_meta" {
            return false
        }
        if ["reasoning", "custom_tool_call", "custom_tool_call_output", "function_call", "function_call_output"].contains(payloadType) {
            return true
        }
        if ["message", "text", "summary", "assistant_message", "tool_call", "tool_result"].contains(payloadType) {
            return true
        }
        if payload["message"] != nil || payload["text"] != nil || payload["client_id"] != nil {
            return true
        }
        return false
    }

    private func modificationDate(_ url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
    }

    private func latestRolloutFile(in directory: URL) -> URL? {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }

        var newest: URL?
        for case let url as URL in enumerator where url.pathExtension == "jsonl" {
            if newest == nil || modificationDate(url) > modificationDate(newest!) {
                newest = url
            }
        }
        return newest
    }

    private func string(_ statement: OpaquePointer, column: Int32) -> String {
        guard let bytes = sqlite3_column_text(statement, column) else { return "" }
        return String(cString: bytes)
    }

    private func stringValue(_ value: Any?) -> String {
        value as? String ?? ""
    }

    private func timestampDate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value)
    }
}
