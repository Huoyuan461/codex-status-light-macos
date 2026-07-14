import Foundation

struct CodexSessionSnapshot: Equatable, Sendable {
    let id: String
    let title: String
    let workingDirectory: String
    let rolloutPath: String
    let startedAt: Date
    let lastActivityAt: Date
    let eventState: SessionEventState
}

enum SessionEventState: Equatable, Sendable {
    case unknown
    case active
    case finalResponse
}
