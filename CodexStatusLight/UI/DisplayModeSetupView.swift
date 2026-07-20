import SwiftUI

struct DisplayModeSetupView: View {
    @Bindable var model: CodexStatusModel
    let close: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            StatusSummaryBadge(state: model.state)
            VStack(spacing: 6) {
                Text("Codex 红绿灯").font(.largeTitle.bold())
                Text("请选择状态灯显示位置，之后可以从菜单栏随时修改。")
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(DisplayMode.allCases) { mode in
                    Button {
                        model.displayMode = mode
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: icon(for: mode))
                                .font(.title2)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.title).font(.headline)
                                Text(mode.detail).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: model.displayMode == mode ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(model.displayMode == mode ? .green : .secondary)
                        }
                        .contentShape(Rectangle())
                        .padding(12)
                        .background(model.displayMode == mode ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }

            if !model.hasCodexDirectoryAccess {
                Button("选择 .codex 文件夹并授权") {
                    model.chooseCodexDirectory()
                }
                .buttonStyle(.borderedProminent)
            }

            HStack {
                Text(model.state.detail).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("完成") { close() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!model.hasCodexDirectoryAccess)
            }
        }
        .padding(24)
        .frame(width: 460)
    }

    private func icon(for mode: DisplayMode) -> String {
        switch mode {
        case .notch: "menubar.rectangle"
        case .desktop: "macwindow"
        case .menuBar: "circle.inset.filled"
        }
    }
}

private struct StatusSummaryBadge: View {
    let state: CodexActivityState

    private var tint: Color {
        switch state {
        case .disconnected: .red
        case .running: .yellow
        case .completed: .green
        case .idle: .gray
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(tint).frame(width: 12, height: 12)
            Circle().fill(tint.opacity(0.55)).frame(width: 12, height: 12)
            Circle().fill(tint.opacity(0.25)).frame(width: 12, height: 12)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.14, blue: 0.17),
                            Color(red: 0.09, green: 0.11, blue: 0.13)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
