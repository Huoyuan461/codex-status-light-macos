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

        if !processIsRunning {
            if snapshot.eventState == .active || previousState == .running || previousState == .disconnected {
                return .disconnected
            }
            return .idle
        }

        if snapshot.eventState == .active {
            return .running
        }

        if snapshot.eventState == .unknown {
            return .running
        }

        let silence = now.timeIntervalSince(snapshot.lastActivityAt)
        if silence > timeout, previousState == .running {
            return .running
        }
        return .running
    }
}
