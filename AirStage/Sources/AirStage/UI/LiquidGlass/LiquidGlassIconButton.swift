import SwiftUI

public struct LiquidGlassIconButton: View {
    public let systemName: String
    public let action: () -> Void

    public init(systemName: String, action: @escaping () -> Void) {
        self.systemName = systemName
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
