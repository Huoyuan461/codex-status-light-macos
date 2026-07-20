import SwiftUI

struct StatusLightView: View {
    let state: CodexActivityState
    var size: CGFloat = 18
    var animated = true
    var startupPhase: Int = 4
    @State private var flashing = false

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
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
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
        .onAppear { flashing = state == .running }
        .onChange(of: state) { _, newState in
            flashing = newState == .running
        }
        .animation(.easeOut(duration: 0.24), value: startupPhase)
        .accessibilityLabel(state.title)
        .accessibilityValue(state.detail)
    }

    private func lamp(_ lampState: CodexActivityState, color: Color, index: Int) -> some View {
        let isActive = state == lampState
        let startupInProgress = startupPhase > 0 && startupPhase < 4
        let startupLit = startupInProgress && startupPhase == index + 1
        let shouldShow = startupInProgress ? startupLit : isActive && state != .idle
        let dimOpacity: Double = {
            guard !isActive else {
                switch state {
                case .running:
                    return flashing ? 0.96 : 0.42
                case .disconnected, .completed:
                    return 0.96
                case .idle:
                    return 0.18
                }
            }
            if state == .idle { return 0.16 }
            return 0.14
        }()
        let startupOpacity: Double = startupLit ? 0.96 : 0.16
        let steadyOpacity: Double = {
            guard state != .idle, isActive else { return dimOpacity }
            switch state {
            case .running:
                return flashing ? 0.96 : 0.42
            case .disconnected, .completed:
                return 0.96
            case .idle:
                return 0
            }
        }()
        return Circle()
            .fill(color)
            .frame(width: size, height: size)
            .opacity(startupInProgress ? startupOpacity : (animated ? steadyOpacity : (isActive ? 0.96 : dimOpacity)))
            .scaleEffect(startupInProgress ? (startupLit ? 1.0 : 0.80) : (isActive ? 1.0 : 0.94))
            .shadow(color: shouldShow ? color.opacity(0.42) : .clear, radius: startupInProgress ? 3.2 : (isActive ? 1.8 : 0))
            .blur(radius: startupInProgress && !startupLit ? 0.5 : 0)
            .animation(
                isActive && animated
                    ? .easeInOut(duration: 0.48).repeatForever(autoreverses: true)
                    : .default,
                value: flashing
            )
            .animation(.easeOut(duration: 0.30), value: startupPhase)
    }
}
