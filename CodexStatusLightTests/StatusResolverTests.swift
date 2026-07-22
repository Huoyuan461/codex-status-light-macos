import XCTest
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
