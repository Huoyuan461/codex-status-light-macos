import Foundation

struct StatusResolver {
    static let defaultTimeout: TimeInterval = 90

    func resolve(
        processIsRunning: Bool,
        snapshot: CodexSessionSnapshot?,
        previousState: CodexActivityState,
        now: Date = Date(),
        timeout: TimeInterval = defaultTimeout
    ) -> CodexActivityState {
        guard let snapshot else { return .idle }

        if snapshot.eventState == .finalResponse {
            return processIsRunning ? .completed : .completed
        }

        let silence = now.timeIntervalSince(snapshot.lastActivityAt)
        if snapshot.eventState == .active || previousState == .running {
            if !processIsRunning || silence > timeout {
                return .disconnected
            }
            return .running
        }

        if processIsRunning, silence <= timeout {
            return .running
        }
        return .idle
    }
}
