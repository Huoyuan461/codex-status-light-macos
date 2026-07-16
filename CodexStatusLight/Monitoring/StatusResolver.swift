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
        guard let snapshot else {
            if processIsRunning {
                return .running
            }
            if previousState == .running || previousState == .disconnected {
                return .disconnected
            }
            return .idle
        }

        if snapshot.eventState == .finalResponse {
            return .completed
        }

        let silence = now.timeIntervalSince(snapshot.lastActivityAt)

        if !processIsRunning {
            if snapshot.eventState == .active || previousState == .running || previousState == .disconnected {
                return .disconnected
            }
            return .idle
        }

        if snapshot.eventState == .active && silence <= timeout {
            return .running
        }

        if snapshot.eventState == .active && silence > timeout {
            return .disconnected
        }

        if snapshot.eventState == .unknown {
            if silence > timeout {
                return previousState == .running ? .disconnected : .idle
            }
            return .running
        }

        return .running
    }
}
