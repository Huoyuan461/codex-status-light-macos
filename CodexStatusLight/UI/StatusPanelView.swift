import AppKit
import SwiftUI

struct StatusPanelView: View {
    @Bindable var model: CodexStatusModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                StatusLightView(state: model.state, size: 30, startupPhase: model.startupAnimationPhase)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.state.title).font(.headline)
                    Text(model.state.detail).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("立即刷新") {
                    model.refreshNow()
                }
                .buttonStyle(.bordered)
            }

            Divider()
            sessionDetails
            Divider()

            Picker("显示位置", selection: $model.displayMode) {
                ForEach(DisplayMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            Toggle("登录时启动", isOn: Binding(
                get: { model.launchAtLoginEnabled },
                set: { model.setLaunchAtLogin($0) }
            ))

            HStack {
                Button("打开 Codex") { model.openCodex() }
                Button("打开任务目录") { model.openWorkingDirectory() }
                    .disabled(model.snapshot?.workingDirectory.isEmpty ?? true)
                Button("关闭插件") { model.closePlugin() }
                Spacer()
                Button("退出") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(16)
        .frame(width: 370)
    }

    @ViewBuilder
    private var sessionDetails: some View {
        if let snapshot = model.snapshot {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 7) {
                detailRow("任务", snapshot.title)
                detailRow("目录", snapshot.workingDirectory.isEmpty ? "未知" : snapshot.workingDirectory)
                detailRow("持续", snapshot.startedAt.formattedDuration(to: Date()))
                detailRow("最后活动", snapshot.lastActivityAt.formatted(date: .omitted, time: .standard))
                detailRow("最近检查", model.lastCheckedAt.formatted(date: .omitted, time: .standard))
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("还没有发现本地 Codex 会话。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text("如果你已经先打开了 Codex，点一下“立即刷新”通常就会恢复。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label).foregroundStyle(.secondary)
            Text(value).lineLimit(2).truncationMode(.middle).textSelection(.enabled)
        }
        .font(.callout)
    }
}

private extension Date {
    func formattedDuration(to end: Date) -> String {
        let seconds = max(0, Int(end.timeIntervalSince(self)))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 { return "\(hours)小时 \(minutes)分钟" }
        return "\(minutes)分钟"
    }
}
