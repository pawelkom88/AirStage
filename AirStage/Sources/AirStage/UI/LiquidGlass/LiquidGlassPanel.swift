import SwiftUI

public struct LiquidGlassPanel<Content: View>: View {
    private let cornerRadius: CGFloat
    private let content: Content

    public init(
        cornerRadius: CGFloat = LiquidGlassTokens.panelCornerRadius,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(LiquidGlassTokens.panelStrokeOpacity), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.24), radius: LiquidGlassTokens.panelShadowRadius, x: 0, y: 20)
            .shadow(color: .white.opacity(0.06), radius: 18, x: 0, y: -4)
    }
}
