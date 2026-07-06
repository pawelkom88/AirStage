import SwiftUI

public struct LiquidGlassOverlayScrim: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .fill(.black.opacity(LiquidGlassTokens.overlayScrimOpacity))
            .background(.ultraThinMaterial.opacity(0.22))
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}
