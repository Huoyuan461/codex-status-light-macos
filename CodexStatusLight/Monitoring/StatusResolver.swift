import Foundation

struct StatusResolver {
    static let defaultTimeout: TimeInterval = 90

    func resolve(
        processIsRunning: Bool,
        networkIsAvailable: Bool,
        snapshot: CodexSessionSnapshot?,
        previousState: CodexActivityState,
        now: Date = Date(),
        timeout: TimeInterval = defaultTimeout
    ) -> CodexActivityState {
        guard let snapshot else {
            if previousState == .completed {
                return .completed
            }
            if !processIsRunning || !networkIsAvailable {
                return previousState == .running ? .disconnected : .idle
            }
            return .idle
        }

        if snapshot.eventState == .finalResponse {
            return .completed
        }

        let silence = now.timeIntervalSince(snapshot.lastActivityAt)

        if !processIsRunning || !networkIsAvailable {
            return previousState == .running || snapshot.eventState == .active ? .disconnected : .idle
        }

        if snapshot.eventState == .active && silence <= timeout {
            return .running
        }

        if snapshot.eventState == .active && silence > timeout {
            return previousState == .running ? .disconnected : .idle
        }

        if snapshot.eventState == .unknown {
            if silence <= timeout {
                return previousState == .running ? .running : .idle
            }
            return previousState == .running ? .disconnected : .idle
        }

        return previousState == .completed ? .completed : .idle
    }
}
