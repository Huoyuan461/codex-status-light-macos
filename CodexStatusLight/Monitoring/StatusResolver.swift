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
        let environmentIsHealthy = processIsRunning && networkIsAvailable

        guard let snapshot else {
            if previousState == .completed {
                return .completed
            }
            if !environmentIsHealthy {
                return previousState == .running ? .disconnected : .idle
            }
            return .running
        }

        if snapshot.eventState == .finalResponse {
            return .completed
        }

        let silence = now.timeIntervalSince(snapshot.lastActivityAt)
        if !environmentIsHealthy {
            if previousState == .completed {
                return .completed
            }
            return previousState == .running || snapshot.eventState == .active ? .disconnected : .idle
        }

        if previousState == .completed, snapshot.eventState != .active {
            return .completed
        }

        switch snapshot.eventState {
        case .active:
            return .running
        case .unknown:
            if silence > timeout, previousState == .running {
                return .running
            }
            return .running
        case .finalResponse:
            return .completed
        }
    }
}
