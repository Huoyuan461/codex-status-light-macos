import SwiftUI

enum CodexActivityState: String, Sendable {
    case idle
    case running
    case completed
    case disconnected

    var title: String {
        switch self {
        case .idle: "未运行"
        case .running: "开发中"
        case .completed: "已完成"
        case .disconnected: "连接中断"
        }
    }

    var detail: String {
        switch self {
        case .idle: "Codex 未启动或尚无任务"
        case .running: "Codex 正在处理最近的任务"
        case .completed: "最近的任务已结束或等待你的输入"
        case .disconnected: "运行中的任务失去进程或心跳"
        }
    }

    var color: Color {
        switch self {
        case .idle: .gray
        case .running: .yellow
        case .completed: .green
        case .disconnected: .red
        }
    }
}
