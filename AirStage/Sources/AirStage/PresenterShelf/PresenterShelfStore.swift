import Foundation
import Combine

@MainActor
public final class PresenterShelfStore: ObservableObject {
    @Published public private(set) var isVisible: Bool = false
    @Published public var selectedCategory: PresenterShelfCategory = .deck
    @Published public var selectedItemID: UUID?
    @Published public private(set) var items: [PresenterShelfItem]
    @Published public var searchQuery: String = ""

    public init(items: [PresenterShelfItem] = PresenterShelfItem.mockItems) {
        self.items = items
        self.selectedItemID = items.first?.id
    }

    public var filteredItems: [PresenterShelfItem] {
        items.filter { item in
            guard item.category == selectedCategory else { return false }
            if searchQuery.isEmpty { return true }
            return item.title.localizedCaseInsensitiveContains(searchQuery)
                || item.subtitle.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    public var selectedItem: PresenterShelfItem? {
        let candidates = filteredItems
        if let selectedItemID, let match = candidates.first(where: { $0.id == selectedItemID }) {
            return match
        }
        return candidates.first
    }

    public func show() {
        ensureValidSelection()
        isVisible = true
    }

    public func hide() {
        isVisible = false
    }

    public func toggle() {
        isVisible ? hide() : show()
    }

    public func selectCategory(_ category: PresenterShelfCategory) {
        selectedCategory = category
        ensureValidSelection()
    }

    public func selectItem(_ id: UUID) {
        selectedItemID = id
    }

    public func selectNext() {
        moveSelection(offset: 1)
    }

    public func selectPrevious() {
        moveSelection(offset: -1)
    }

    public func setItems(_ nextItems: [PresenterShelfItem]) {
        items = nextItems
        ensureValidSelection()
    }

    public func addItems(_ newItems: [PresenterShelfItem]) {
        items.append(contentsOf: newItems)
        ensureValidSelection()
    }

    public func clear() {
        items.removeAll()
        ensureValidSelection()
    }

    private func moveSelection(offset: Int) {
        let candidates = filteredItems
        guard !candidates.isEmpty else {
            selectedItemID = nil
            return
        }

        let currentIndex = selectedItemID.flatMap { id in
            candidates.firstIndex(where: { $0.id == id })
        } ?? 0

        let nextIndex = (currentIndex + offset + candidates.count) % candidates.count
        selectedItemID = candidates[nextIndex].id
    }

    private func ensureValidSelection() {
        let candidates = filteredItems
        guard !candidates.isEmpty else {
            selectedItemID = nil
            return
        }

        if let selectedItemID, candidates.contains(where: { $0.id == selectedItemID }) {
            return
        }

        selectedItemID = candidates.first?.id
    }
}
