import SwiftUI

struct StatusLightView: View {
    let state: CodexActivityState
    var size: CGFloat = 18
    var animated = true
    var startupPhase: Int = 4
    @State private var blinkPhase = false

    var body: some View {
        HStack(spacing: size * 0.36) {
            lamp(.disconnected, color: Color(red: 1, green: 0.29, blue: 0.25), index: 0)
            lamp(.running, color: Color(red: 1, green: 0.82, blue: 0.18), index: 1)
            lamp(.completed, color: Color(red: 0.24, green: 0.84, blue: 0.43), index: 2)
        }
        .padding(.horizontal, size * 0.60)
        .padding(.vertical, size * 0.40)
        .background {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.15, blue: 0.18),
                            Color(red: 0.08, green: 0.11, blue: 0.13)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                )
                .overlay(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.10),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .padding(1)
                        .blur(radius: 0.4)
                )
        }
        .task(id: blinkTaskID) {
            await runBlinkLoop()
        }
        .animation(.easeOut(duration: 0.24), value: startupPhase)
        .accessibilityLabel(state.title)
        .accessibilityValue(state.detail)
    }

    private func lamp(_ lampState: CodexActivityState, color: Color, index: Int) -> some View {
        let isActive = state == lampState
        let startupInProgress = startupPhase > 0 && startupPhase < 4
        let startupLit = startupInProgress && startupPhase == index + 1
        let offOpacity: Double = state == .idle ? 0.24 : 0.16
        let activeOpacity: Double = {
            guard isActive else { return offOpacity }
            switch state {
            case .running:
                return blinkPhase ? 0.98 : 0.46
            case .completed, .disconnected:
                return blinkPhase ? 0.96 : 0.38
            case .idle:
                return 0.0
            }
        }()
        let startupOpacity: Double = startupLit ? 0.98 : 0.20
        return Circle()
            .fill(color)
            .frame(width: size, height: size)
            .opacity(startupInProgress ? startupOpacity : (animated ? activeOpacity : (isActive ? 0.96 : offOpacity)))
            .scaleEffect(startupInProgress ? (startupLit ? 1.0 : 0.80) : (isActive ? 1.0 : 0.94))
            .shadow(color: (startupInProgress || isActive) ? color.opacity(0.45) : color.opacity(0.16), radius: startupInProgress ? 3.6 : (isActive ? 2.2 : 0.8))
            .blur(radius: startupInProgress && !startupLit ? 0.5 : 0)
            .animation(
                isActive && animated
                    ? .easeInOut(duration: state == .running ? 0.34 : 0.44).repeatForever(autoreverses: true)
                    : .default,
                value: blinkPhase
            )
            .animation(.easeOut(duration: 0.30), value: startupPhase)
    }

    private var blinkTaskID: String {
        "\(state.rawValue)-\(startupPhase)"
    }

    private func blinkInterval(for state: CodexActivityState) -> Duration {
        switch state {
        case .running:
            return .milliseconds(300)
        case .disconnected:
            return .milliseconds(420)
        case .completed:
            return .milliseconds(480)
        case .idle:
            return .milliseconds(0)
        }
    }

    private func runBlinkLoop() async {
        blinkPhase = false

        guard animated, startupPhase >= 4, state != .idle else { return }

        let interval = blinkInterval(for: state)
        while !Task.isCancelled {
            withAnimation(.easeInOut(duration: 0.22)) {
                blinkPhase.toggle()
            }
            try? await Task.sleep(for: interval)
        }
    }
}
