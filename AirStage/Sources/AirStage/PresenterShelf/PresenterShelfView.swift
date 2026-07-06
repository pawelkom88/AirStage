import SwiftUI

public struct PresenterShelfView: View {
    @ObservedObject var store: PresenterShelfStore
    let onPresent: () -> Void
    let onClose: () -> Void

    public init(store: PresenterShelfStore, onPresent: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.store = store
        self.onPresent = onPresent
        self.onClose = onClose
    }

    public var body: some View {
        ZStack {
            LiquidGlassOverlayScrim()

            LiquidGlassPanel {
                VStack(spacing: 22) {
                    header
                    categoryTabs
                    carousel
                    pageDots
                }
                .padding(.horizontal, 34)
                .padding(.vertical, 28)
            }
            .frame(width: 960, height: 560)
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
        }
    }

    private var header: some View {
        ZStack {
            HStack {
                LiquidGlassIconButton(systemName: "magnifyingglass") {}
                Spacer()
                LiquidGlassIconButton(systemName: "ellipsis") {}
            }

            VStack(spacing: 6) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.94))

                    Text("Presenter Shelf")
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Text("Preloaded for your live session")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
            }
        }
    }

    private var categoryTabs: some View {
        HStack(spacing: 4) {
            ForEach(PresenterShelfCategory.allCases) { category in
                LiquidGlassSegment(
                    title: category.title,
                    systemImage: category.systemImage,
                    isSelected: store.selectedCategory == category
                ) {
                    store.selectCategory(category)
                }
            }
        }
        .padding(4)
        .background(.white.opacity(0.08), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
    }

    private var carousel: some View {
        ZStack {
            HStack(spacing: 18) {
                ForEach(store.filteredItems) { item in
                    PresenterShelfCardView(
                        item: item,
                        isSelected: item.id == store.selectedItem?.id,
                        onSelect: { store.selectItem(item.id) },
                        onPresent: onPresent
                    )
                }
            }
            .frame(height: 330)

            HStack {
                LiquidGlassIconButton(systemName: "chevron.left") { store.selectPrevious() }
                Spacer()
                LiquidGlassIconButton(systemName: "chevron.right") { store.selectNext() }
            }
            .padding(.horizontal, -22)
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(store.filteredItems) { item in
                Circle()
                    .fill(item.id == store.selectedItem?.id ? .white : .white.opacity(0.28))
                    .frame(width: 8, height: 8)
            }
        }
    }
}
