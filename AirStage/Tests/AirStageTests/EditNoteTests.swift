import XCTest
@testable import AirStage

final class EditNoteTests: XCTestCase {

    func testEditingNoteUpdatesLayerText() {
        let store = SceneStore()
        guard let id = store.addNote(title: "Initial").layerID else {
            XCTFail("Failed to add note")
            return
        }

        store.updateNoteText(layerID: id, text: "Updated Content")

        XCTAssertEqual(store.layer(withID: id)?.title, "Updated Content")
    }

    func testEmptyNoteShowsPlaceholder() {
        let store = SceneStore()
        guard let id = store.addNote(title: "").layerID else {
            XCTFail("Failed to add note")
            return
        }

        let note = store.layer(withID: id)!
        XCTAssertEqual(note.displayTitle, "Empty Note")
    }

    func testEditedNoteTitleAppearsInRemoveLayerMenu() {
        let store = SceneStore()
        guard let id = store.addNote(title: "Temp").layerID else {
            XCTFail("Failed to add note")
            return
        }

        store.updateNoteText(layerID: id, text: "Clean Desk")

        let note = store.layer(withID: id)!
        XCTAssertEqual(note.displayTitle, "Clean Desk")
    }
}
