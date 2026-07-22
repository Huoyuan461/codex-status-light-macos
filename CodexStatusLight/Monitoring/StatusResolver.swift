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
            if !environmentIsHealthy {
                if previousState == .completed {
                    return .disconnected
                }
                return previousState == .running ? .disconnected : .idle
            }
            if previousState == .completed {
                return .completed
            }
            return .running
        }

        if snapshot.eventState == .finalResponse {
            return .completed
        }

        let silence = now.timeIntervalSince(snapshot.lastActivityAt)
        if !environmentIsHealthy {
            return previousState == .running || snapshot.eventState == .active ? .disconnected : .idle
        }

        switch snapshot.eventState {
        case .active:
            if silence > timeout {
                return .disconnected
            }
            return .running
        case .unknown:
            if silence > timeout {
                if previousState == .running {
                    return .disconnected
                }
                if previousState == .completed {
                    return .completed
                }
                return .idle
            }
            if previousState == .completed {
                return .running
            }
            return .running
        case .finalResponse:
            return .completed
        }
    }
}
