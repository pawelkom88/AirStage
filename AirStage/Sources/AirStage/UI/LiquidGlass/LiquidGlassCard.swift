import SwiftUI

public struct LiquidGlassCard<Content: View>: View {
    private let isSelected: Bool
    private let content: Content

    public init(isSelected: Bool = false, @ViewBuilder content: () -> Content) {
        self.isSelected = isSelected
        self.content = content()
    }

    public var body: some View {
        content
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: LiquidGlassTokens.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LiquidGlassTokens.cardCornerRadius, style: .continuous)
                    .stroke(
                        .white.opacity(isSelected ? LiquidGlassTokens.selectedStrokeOpacity : LiquidGlassTokens.cardStrokeOpacity),
                        lineWidth: isSelected ? 1.4 : 1
                    )
            )
            .shadow(color: .black.opacity(isSelected ? 0.28 : 0.16), radius: isSelected ? 24 : LiquidGlassTokens.cardShadowRadius, x: 0, y: isSelected ? 16 : 10)
            .scaleEffect(isSelected ? 1.0 : 0.94)
            .opacity(isSelected ? 1.0 : 0.72)
            .animation(.smooth(duration: 0.32), value: isSelected)
    }
}
