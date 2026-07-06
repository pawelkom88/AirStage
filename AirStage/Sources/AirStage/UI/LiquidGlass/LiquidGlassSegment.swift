import SwiftUI

public struct LiquidGlassSegment: View {
    public let title: String
    public let systemImage: String
    public let isSelected: Bool
    public let action: () -> Void

    public init(title: String, systemImage: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(isSelected ? 0.98 : 0.72))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(.white.opacity(0.16))
                            .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
