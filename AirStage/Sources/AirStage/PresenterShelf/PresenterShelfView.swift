import SwiftUI

public struct PresenterShelfView: View {
    @ObservedObject var store: PresenterShelfStore
    let onPresent: () -> Void
    let onClose: () -> Void
    
    // Callbacks for file adding
    var onAddFiles: (() -> Void)?
    var onAddFolder: (() -> Void)?

    public init(
        store: PresenterShelfStore,
        onPresent: @escaping () -> Void,
        onClose: @escaping () -> Void,
        onAddFiles: (() -> Void)? = nil,
        onAddFolder: (() -> Void)? = nil
    ) {
        self.store = store
        self.onPresent = onPresent
        self.onClose = onClose
        self.onAddFiles = onAddFiles
        self.onAddFolder = onAddFolder
    }

    private enum LayoutMode {
        case compact
        case regular
        case expanded
        
        init(width: CGFloat) {
            if width < 800 {
                self = .compact
            } else if width < 1200 {
                self = .regular
            } else {
                self = .expanded
            }
        }
        
        var panelWidth: CGFloat {
            switch self {
            case .compact: return 480
            case .regular: return 960
            case .expanded: return 1200
            }
        }
    }

    public var body: some View {
        GeometryReader { geo in
            let mode = LayoutMode(width: geo.size.width)
            
            ZStack {
                LiquidGlassOverlayScrim()
                    .onTapGesture {
                        onClose()
                    }

                LiquidGlassPanel {
                    VStack(spacing: 22) {
                        header
                        categoryTabs
                        
                        if store.filteredItems.isEmpty {
                            emptyState
                        } else {
                            carousel
                            pageDots
                        }
                    }
                    .padding(.horizontal, mode == .compact ? 24 : 34)
                    .padding(.vertical, mode == .compact ? 20 : 28)
                }
                .frame(width: mode.panelWidth, height: mode == .compact ? 500 : 560)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
    }

    private var header: some View {
        ZStack {
            HStack {
                Spacer()
                Menu {
                    Button(action: { onAddFiles?() }) {
                        Label("Add Files", systemImage: "doc.badge.plus")
                    }
                    Button(action: { onAddFolder?() }) {
                        Label("Add Folder", systemImage: "folder.badge.plus")
                    }
                    Divider()
                    Button(role: .destructive, action: { store.clear() }) {
                        Label("Clear Shelf", systemImage: "trash")
                    }
                    Divider()
                    Button(action: { onClose() }) {
                        Label("Close", systemImage: "xmark")
                    }
                } label: {
                    LiquidGlassIconButton(systemName: "ellipsis") {}
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
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

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: store.selectedCategory.systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.4))
            
            Text("No \(store.selectedCategory.title) found")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
            
            HStack(spacing: 16) {
                Button(action: { onAddFiles?() }) {
                    Text("Add Files")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.15), in: Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                
                Button(action: { onAddFolder?() }) {
                    Text("Add Folder")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.15), in: Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
        }
        .frame(maxHeight: .infinity)
    }

    private var carousel: some View {
        ZStack {
            // Note: For MVP we can just let it scroll or fit.
            // A ScrollView makes more sense for varying widths.
            ScrollView(.horizontal, showsIndicators: false) {
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
                .padding(.horizontal, 30) // padding for chevrons
            }
            .frame(height: 330)

            HStack {
                LiquidGlassIconButton(systemName: "chevron.left") { store.selectPrevious() }
                Spacer()
                LiquidGlassIconButton(systemName: "chevron.right") { store.selectNext() }
            }
            .padding(.horizontal, -12) // push outwards slightly
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
