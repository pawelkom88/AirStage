import SwiftUI
import AirStage

struct EdgeDeleteZoneView: View {
    let side: EdgeDeleteSide
    let state: EdgeDeleteState

    private var isArmed: Bool {
        if case .armed = state { return true }
        if case .disintegrating = state { return true }
        return false
    }

    var body: some View {
        ZStack {
            LiquidGlassWave(isArmed: isArmed)

            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: isArmed ? 72 : 58, height: isArmed ? 72 : 58)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(isArmed ? 0.65 : 0.35), lineWidth: 1)
                )
                .shadow(color: .white.opacity(isArmed ? 0.32 : 0.16), radius: isArmed ? 24 : 10)

            Image(systemName: "trash")
                .font(.system(size: isArmed ? 30 : 24, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: isArmed ? 128 : 96, height: isArmed ? 320 : 260)
        .scaleEffect(isArmed ? 1.04 : 1.0)
        .animation(.smooth(duration: 0.45), value: isArmed)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct LiquidGlassWave: View {
    let isArmed: Bool

    @State private var pulse = false

    var body: some View {
        ZStack {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.28), lineWidth: 1)
                )

            Circle()
                .fill(.white.opacity(isArmed ? 0.18 : 0.08))
                .blur(radius: 18)
                .scaleEffect(pulse ? 1.25 : 0.82)

            Circle()
                .stroke(.white.opacity(isArmed ? 0.22 : 0.08), lineWidth: 2)
                .blur(radius: 8)
                .scaleEffect(pulse ? 1.45 : 1.0)
        }
        .onAppear {
            pulse = true
        }
        .animation(
            isArmed
                ? .easeInOut(duration: 1.1).repeatForever(autoreverses: true)
                : .easeInOut(duration: 0.4),
            value: pulse
        )
    }
}
