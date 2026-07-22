import XCTest
import SQLite3
@testable import CodexStatusLight

final class StatusResolverTests: XCTestCase {
    private let resolver = StatusResolver()
    private let now = Date(timeIntervalSince1970: 10_000)

    func testNoSessionIsIdle() {
        XCTAssertEqual(resolver.resolve(processIsRunning: false, networkIsAvailable: true, snapshot: nil, previousState: .idle, now: now), .idle)
    }

    func testNoSessionButProcessRunningIsRunning() {
        XCTAssertEqual(resolver.resolve(processIsRunning: true, networkIsAvailable: true, snapshot: nil, previousState: .idle, now: now), .running)
    }

    func testActiveSessionIsRunning() {
        XCTAssertEqual(resolver.resolve(processIsRunning: true, networkIsAvailable: true, snapshot: snapshot(.active, age: 2), previousState: .idle, now: now), .running)
    }

    func testRecentUnknownSessionIsRunning() {
        XCTAssertEqual(resolver.resolve(processIsRunning: true, networkIsAvailable: true, snapshot: snapshot(.unknown, age: 2), previousState: .idle, now: now), .running)
    }

    func testSilentUnknownSessionStillShowsRunning() {
        XCTAssertEqual(resolver.resolve(processIsRunning: true, networkIsAvailable: true, snapshot: snapshot(.unknown, age: 120), previousState: .idle, now: now), .running)
    }

    func testCompletedTurnWinsAfterEarlierActivity() {
        let snapshot = CodexSessionSnapshot(
            id: "test",
            title: "Test",
            workingDirectory: "/tmp",
            rolloutPath: "/tmp/test.jsonl",
            startedAt: now.addingTimeInterval(-120),
            lastActivityAt: now.addingTimeInterval(-2),
            eventState: .finalResponse
        )
        XCTAssertEqual(resolver.resolve(processIsRunning: true, networkIsAvailable: true, snapshot: snapshot, previousState: .running, now: now), .completed)
    }

    func testFinalResponseIsCompletedEvenAfterProcessCloses() {
        XCTAssertEqual(resolver.resolve(processIsRunning: false, networkIsAvailable: true, snapshot: snapshot(.finalResponse, age: 2), previousState: .running, now: now), .completed)
    }

    func testCompletedStatePersistsWhenSnapshotDisappears() {
        XCTAssertEqual(resolver.resolve(processIsRunning: true, networkIsAvailable: true, snapshot: nil, previousState: .completed, now: now), .completed)
    }

    func testCompletedStatePersistsWhenEnvironmentDrops() {
        XCTAssertEqual(resolver.resolve(processIsRunning: false, networkIsAvailable: false, snapshot: snapshot(.finalResponse, age: 120), previousState: .completed, now: now), .completed)
    }

    func testRunningSessionWithoutProcessIsDisconnected() {
        XCTAssertEqual(resolver.resolve(processIsRunning: false, networkIsAvailable: true, snapshot: snapshot(.active, age: 2), previousState: .running, now: now), .disconnected)
    }

    func testRunningStateWithoutSnapshotAndNoProcessIsDisconnected() {
        XCTAssertEqual(resolver.resolve(processIsRunning: false, networkIsAvailable: true, snapshot: nil, previousState: .running, now: now), .disconnected)
    }

    func testStaleActiveSessionIsDisconnected() {
        XCTAssertEqual(resolver.resolve(processIsRunning: true, networkIsAvailable: true, snapshot: snapshot(.active, age: 91), previousState: .running, now: now), .running)
    }

    private func snapshot(_ state: SessionEventState, age: TimeInterval) -> CodexSessionSnapshot {
        CodexSessionSnapshot(id: "test", title: "Test", workingDirectory: "/tmp", rolloutPath: "/tmp/test.jsonl", startedAt: now.addingTimeInterval(-120), lastActivityAt: now.addingTimeInterval(-age), eventState: state)
    }
}

final class CodexSessionMonitorTests: XCTestCase {
    func testLatestSessionPrefersCompletedAfterEarlierActivity() async throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let codexDirectory = root.appendingPathComponent(".codex", isDirectory: true)
        try FileManager.default.createDirectory(at: codexDirectory, withIntermediateDirectories: true)
        let rolloutURL = codexDirectory.appendingPathComponent("rollout-test.jsonl")
        try """
        {"timestamp":"2026-07-22T00:00:00.000Z","type":"turn_context","payload":{"turn_id":"turn-1"}}
        {"timestamp":"2026-07-22T00:00:01.000Z","type":"response_item","payload":{"type":"function_call_output","turn_id":"turn-1","message":"tool output"}}
        {"timestamp":"2026-07-22T00:00:02.000Z","type":"event_msg","payload":{"type":"task_complete","turn_id":"turn-1"}}
        {"timestamp":"2026-07-22T00:00:03.000Z","type":"event_msg","payload":{"type":"agent_message","phase":"final_answer","turn_id":"turn-1","message":"done"}}
        """.write(to: rolloutURL)

        try createThreadsDatabase(
            at: codexDirectory.appendingPathComponent("state_1.sqlite"),
            rolloutPath: rolloutURL.path,
            title: "完成任务测试"
        )

        let monitor = CodexSessionMonitor()
        let snapshot = await monitor.latestSession(in: codexDirectory)

        XCTAssertEqual(snapshot?.eventState, .finalResponse)
        XCTAssertEqual(snapshot?.title, "完成任务测试")
        XCTAssertEqual(snapshot?.rolloutPath, rolloutURL.path)
    }

    func testLatestSessionKeepsActiveWhenNoCompletionArrives() async throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let codexDirectory = root.appendingPathComponent(".codex", isDirectory: true)
        try FileManager.default.createDirectory(at: codexDirectory, withIntermediateDirectories: true)
        let rolloutURL = codexDirectory.appendingPathComponent("rollout-active.jsonl")
        try """
        {"timestamp":"2026-07-22T00:00:00.000Z","type":"turn_context","payload":{"turn_id":"turn-2"}}
        {"timestamp":"2026-07-22T00:00:01.000Z","type":"response_item","payload":{"type":"function_call_output","turn_id":"turn-2","message":"tool output"}}
        {"timestamp":"2026-07-22T00:00:02.000Z","type":"event_msg","payload":{"type":"agent_message","phase":"commentary","turn_id":"turn-2","message":"still working"}}
        """.write(to: rolloutURL)

        try createThreadsDatabase(
            at: codexDirectory.appendingPathComponent("state_1.sqlite"),
            rolloutPath: rolloutURL.path,
            title: "进行中测试"
        )

        let monitor = CodexSessionMonitor()
        let snapshot = await monitor.latestSession(in: codexDirectory)

        XCTAssertEqual(snapshot?.eventState, .active)
        XCTAssertEqual(snapshot?.title, "进行中测试")
        XCTAssertEqual(snapshot?.rolloutPath, rolloutURL.path)
    }

    private func makeTempDirectory() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("codex-status-light-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func createThreadsDatabase(at url: URL, rolloutPath: String, title: String) throws {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK, let db else {
            throw NSError(domain: "CodexSessionMonitorTests", code: 100)
        }
        defer { sqlite3_close(db) }

        let createSQL = """
        CREATE TABLE threads (
            id TEXT PRIMARY KEY,
            rollout_path TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            source TEXT NOT NULL,
            model_provider TEXT NOT NULL,
            cwd TEXT NOT NULL,
            title TEXT NOT NULL,
            sandbox_policy TEXT NOT NULL,
            approval_mode TEXT NOT NULL,
            tokens_used INTEGER NOT NULL DEFAULT 0,
            has_user_event INTEGER NOT NULL DEFAULT 0,
            archived INTEGER NOT NULL DEFAULT 0,
            archived_at INTEGER,
            git_sha TEXT,
            git_branch TEXT,
            git_origin_url TEXT,
            cli_version TEXT NOT NULL DEFAULT '',
            first_user_message TEXT NOT NULL DEFAULT '',
            agent_nickname TEXT,
            agent_role TEXT,
            memory_mode TEXT NOT NULL DEFAULT 'enabled',
            model TEXT,
            reasoning_effort TEXT,
            agent_path TEXT,
            created_at_ms INTEGER,
            updated_at_ms INTEGER,
            thread_source TEXT,
            preview TEXT NOT NULL DEFAULT '',
            recency_at INTEGER NOT NULL DEFAULT 0,
            recency_at_ms INTEGER NOT NULL DEFAULT 0,
            history_mode TEXT NOT NULL DEFAULT 'legacy'
        );
        """
        try execute(sql: createSQL, on: db)

        let insertSQL = """
        INSERT INTO threads (
            id, rollout_path, created_at, updated_at, source, model_provider, cwd, title,
            sandbox_policy, approval_mode, tokens_used, has_user_event, archived, archived_at,
            git_sha, git_branch, git_origin_url, cli_version, first_user_message, agent_nickname,
            agent_role, memory_mode, model, reasoning_effort, agent_path, created_at_ms,
            updated_at_ms, thread_source, preview, recency_at, recency_at_ms, history_mode
        ) VALUES (
            'thread-1', ?, 1784680000000, 1784680100000, 'vscode', 'openai',
            '/tmp', ?, 'full-access', 'never', 0, 0, 0, NULL,
            NULL, NULL, NULL, '', '', NULL,
            NULL, 'enabled', NULL, NULL, NULL, 1784680000000,
            1784680100000, NULL, ?, 0, 0, 'legacy'
        );
        """
        try execute(sql: insertSQL, on: db, bindings: [rolloutPath, title, title])
    }

    private func execute(sql: String, on db: OpaquePointer, bindings: [String] = []) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw NSError(domain: "CodexSessionMonitorTests", code: 1)
        }
        defer { sqlite3_finalize(statement) }

        for (index, value) in bindings.enumerated() {
            let _: Void = value.withCString { cString in
                sqlite3_bind_text(statement, Int32(index + 1), cString, -1, transientDestructor())
            }
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw NSError(domain: "CodexSessionMonitorTests", code: 2)
        }
    }

    private func transientDestructor() -> sqlite3_destructor_type {
        unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    }
}

private extension String {
    func write(to url: URL) throws {
        try Data(utf8).write(to: url)
    }
}
