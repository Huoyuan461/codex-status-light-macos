import XCTest
@testable import CodexStatusLight

final class StatusResolverTests: XCTestCase {
    private let resolver = StatusResolver()
    private let now = Date(timeIntervalSince1970: 10_000)

    func testNoSessionIsIdle() {
        XCTAssertEqual(resolver.resolve(processIsRunning: false, snapshot: nil, previousState: .idle, now: now), .idle)
    }

    func testActiveSessionIsRunning() {
        XCTAssertEqual(resolver.resolve(processIsRunning: true, snapshot: snapshot(.active, age: 2), previousState: .idle, now: now), .running)
    }

    func testFinalResponseIsCompletedEvenAfterProcessCloses() {
        XCTAssertEqual(resolver.resolve(processIsRunning: false, snapshot: snapshot(.finalResponse, age: 2), previousState: .running, now: now), .completed)
    }

    func testRunningSessionWithoutProcessIsDisconnected() {
        XCTAssertEqual(resolver.resolve(processIsRunning: false, snapshot: snapshot(.active, age: 2), previousState: .running, now: now), .disconnected)
    }

    func testStaleActiveSessionIsDisconnected() {
        XCTAssertEqual(resolver.resolve(processIsRunning: true, snapshot: snapshot(.active, age: 91), previousState: .running, now: now), .disconnected)
    }

    private func snapshot(_ state: SessionEventState, age: TimeInterval) -> CodexSessionSnapshot {
        CodexSessionSnapshot(id: "test", title: "Test", workingDirectory: "/tmp", rolloutPath: "/tmp/test.jsonl", startedAt: now.addingTimeInterval(-120), lastActivityAt: now.addingTimeInterval(-age), eventState: state)
    }
}
