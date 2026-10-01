import SwiftUI

struct GlowOverlayModifier: ViewModifier {
    var isActive: Bool
    var cornerRadius: CGFloat
    var colors: [Color] = [.blue, .purple, .cyan]
    
    func body(content: Content) -> some View {
        content.overlay(
            Group {
                if isActive {
                    AppleIntelligenceGlowEffect(cornerRadius: cornerRadius, colors: colors)
                }
            }
        )
    }
}

extension View {
    func glowOverlay(isActive: Bool, cornerRadius: CGFloat, colors: [Color] = [.blue, .purple, .cyan]) -> some View {
        self.modifier(GlowOverlayModifier(isActive: isActive, cornerRadius: cornerRadius, colors: colors))
    }
}
