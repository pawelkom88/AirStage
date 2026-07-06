import SwiftUI

public struct PresenterShelfCardView: View {
    let item: PresenterShelfItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onPresent: () -> Void

    public var body: some View {
        LiquidGlassCard(isSelected: isSelected) {
            VStack(alignment: .leading, spacing: 12) {
                thumbnail

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title)
                        .font(.system(size: isSelected ? 20 : 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(item.subtitle)
                        .font(.system(size: isSelected ? 14 : 12, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(1)
                }

                if isSelected {
                    Button(action: onPresent) {
                        Label("Present", systemImage: "play.fill")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(.white.opacity(0.13), in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.14), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .frame(width: isSelected ? 320 : 190, height: isSelected ? 330 : 260)
        .onTapGesture { onSelect() }
    }

    @ViewBuilder
    private var thumbnail: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(thumbnailGradient)
                .frame(height: isSelected ? 160 : 120)
                .overlay(thumbnailContent)

            Image(systemName: badgeIcon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(.blue.opacity(0.9), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(8)
        }
    }

    private var thumbnailGradient: LinearGradient {
        switch item.kind {
        case .deck:
            return LinearGradient(colors: [.blue.opacity(0.9), .black.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .screenshot:
            return LinearGradient(colors: [.gray.opacity(0.65), .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
        case .media:
            return LinearGradient(colors: [.purple.opacity(0.75), .black.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .notes:
            return LinearGradient(colors: [.white.opacity(0.9), .gray.opacity(0.55)], startPoint: .top, endPoint: .bottom)
        case .folder, .file:
            return LinearGradient(colors: [.cyan.opacity(0.78), .blue.opacity(0.88)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var badgeIcon: String {
        switch item.kind {
        case .deck: return "rectangle.on.rectangle"
        case .screenshot: return "viewfinder"
        case .media: return "play.rectangle"
        case .notes: return "doc.text"
        case .folder: return "folder"
        case .file: return "doc"
        }
    }

    @ViewBuilder
    private var thumbnailContent: some View {
        switch item.kind {
        case .deck:
            VStack(alignment: .leading, spacing: 6) {
                Text("AirStage")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))

                Spacer()

                Text("Vision to\nImpact")
                    .font(.system(size: isSelected ? 28 : 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Product Update — May 2025")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

        case .notes:
            VStack(alignment: .leading, spacing: 6) {
                Text("Key Talking Points")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.black.opacity(0.78))

                Text("• Market momentum\n• Product innovation\n• Customer outcomes\n• What’s next")
                    .font(.caption2)
                    .foregroundStyle(.black.opacity(0.62))
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

        case .folder:
            Image(systemName: "folder.fill")
                .font(.system(size: isSelected ? 72 : 52, weight: .regular))
                .foregroundStyle(.white.opacity(0.88))

        default:
            Image(systemName: badgeIcon)
                .font(.system(size: isSelected ? 54 : 38, weight: .semibold))
                .foregroundStyle(.white.opacity(0.84))
        }
    }
}
