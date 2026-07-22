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
            return previousState == .running ? .running : .idle
        }

        switch snapshot.eventState {
        case .active:
            if !environmentIsHealthy {
                return .disconnected
            }
            return .running
        case .finalResponse:
            return .completed
        case .unknown:
            if !environmentIsHealthy {
                if previousState == .completed {
                    return .completed
                }
                return previousState == .running ? .disconnected : .idle
            }
            if previousState == .running || previousState == .completed {
                return .completed
            }
            return .idle
        }
    }
}
