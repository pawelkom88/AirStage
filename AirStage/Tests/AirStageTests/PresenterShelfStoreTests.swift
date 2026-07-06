import XCTest
@testable import AirStage

@MainActor
final class PresenterShelfStoreTests: XCTestCase {

    func testPresenterShelfStartsHiddenWithMockSelection() {
        let store = PresenterShelfStore(items: PresenterShelfItem.mockItems)

        XCTAssertFalse(store.isVisible)
        XCTAssertNotNil(store.selectedItem)
    }

    func testPresenterShelfShowMakesItVisible() {
        let store = PresenterShelfStore(items: PresenterShelfItem.mockItems)

        store.show()

        XCTAssertTrue(store.isVisible)
    }

    func testPresenterShelfCategoryFiltersItems() {
        let store = PresenterShelfStore(items: PresenterShelfItem.mockItems)

        store.selectCategory(.notes)

        XCTAssertTrue(store.filteredItems.allSatisfy { $0.category == .notes })
    }

    func testPresenterShelfSelectionMovesNextAndPrevious() {
        let items = [
            PresenterShelfItem(title: "A", subtitle: "Deck", kind: .deck, category: .deck),
            PresenterShelfItem(title: "B", subtitle: "Deck", kind: .deck, category: .deck),
            PresenterShelfItem(title: "C", subtitle: "Deck", kind: .deck, category: .deck)
        ]

        let store = PresenterShelfStore(items: items)
        store.selectCategory(.deck)

        let first = store.selectedItemID
        store.selectNext()
        let second = store.selectedItemID
        store.selectPrevious()
        let back = store.selectedItemID

        XCTAssertNotNil(first)
        XCTAssertNotEqual(first, second)
        XCTAssertEqual(first, back)
    }
}
