import SwiftUI

struct StatusLightView: View {
    let state: CodexActivityState
    var size: CGFloat = 18
    var animated = true
    @State private var flashing = false

    var body: some View {
        HStack(spacing: size * 0.38) {
            lamp(.disconnected, color: Color(red: 1, green: 0.24, blue: 0.20))
            lamp(.running, color: Color(red: 1, green: 0.78, blue: 0.08))
            lamp(.completed, color: Color(red: 0.20, green: 0.82, blue: 0.35))
        }
        .padding(.horizontal, size * 0.55)
        .padding(.vertical, size * 0.36)
        .background(Color(red: 0.12, green: 0.17, blue: 0.19), in: Capsule())
        .onAppear { flashing = true }
        .onChange(of: state) { _, _ in
            flashing = false
            flashing = true
        }
            .accessibilityLabel(state.title)
            .accessibilityValue(state.detail)
    }

    private func lamp(_ lampState: CodexActivityState, color: Color) -> some View {
        let isActive = state == lampState
        return Circle()
            .fill(isActive ? color : color.opacity(state == .idle ? 0.12 : 0.18))
            .frame(width: size, height: size)
            .opacity(isActive && animated ? (flashing ? 1 : 0.28) : 1)
            .animation(
                isActive && animated
                    ? .easeInOut(duration: 0.62).repeatForever(autoreverses: true)
                    : .default,
                value: flashing
            )
    }
}
