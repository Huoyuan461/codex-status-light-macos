import SwiftUI

struct StatusLightView: View {
    let state: CodexActivityState
    var size: CGFloat = 18
    var animated = true
    var startupPhase: Int = 4
    @State private var flashing = false

    var body: some View {
        HStack(spacing: size * 0.36) {
            accentDot
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
        .onAppear { flashing = true }
        .onChange(of: state) { _, _ in
            flashing = false
            flashing = true
        }
        .animation(.easeOut(duration: 0.24), value: startupPhase)
        .accessibilityLabel(state.title)
        .accessibilityValue(state.detail)
    }

    private var accentDot: some View {
        let startupInProgress = startupPhase < 4
        let visible = startupInProgress || state == .running || state == .completed
        return Circle()
            .fill(Color(red: 0.38, green: 0.62, blue: 1.0))
            .frame(width: size * 0.34, height: size * 0.34)
            .opacity(visible ? (startupInProgress ? 0.82 : 0.42) : 0.14)
            .shadow(color: Color(red: 0.38, green: 0.62, blue: 1.0).opacity(0.35), radius: 2)
            .scaleEffect(startupInProgress ? (startupPhase > 0 ? 1.0 : 0.72) : 1.0)
            .animation(.easeOut(duration: 0.28), value: startupPhase)
    }

    private func lamp(_ lampState: CodexActivityState, color: Color, index: Int) -> some View {
        let isActive = state == lampState
        let startupInProgress = startupPhase < 4
        let startupLit = startupInProgress && startupPhase > index
        return Circle()
            .fill(isActive ? color : color.opacity(state == .idle ? 0.12 : 0.18))
            .frame(width: size, height: size)
            .opacity(startupInProgress ? (startupLit ? 0.96 : 0.10) : (isActive && animated ? (flashing ? 0.96 : 0.36) : 0.92))
            .scaleEffect(startupInProgress ? (startupLit ? 1.0 : 0.86) : (isActive ? 1.0 : 0.98))
            .shadow(color: (startupInProgress || isActive) ? color.opacity(0.40) : .clear, radius: startupInProgress ? 2.5 : 1.4)
            .blur(radius: startupInProgress && !startupLit ? 0.4 : 0)
            .animation(
                isActive && animated
                    ? .easeInOut(duration: 0.62).repeatForever(autoreverses: true)
                    : .default,
                value: flashing
            )
            .animation(.easeOut(duration: 0.26), value: startupPhase)
    }
}
