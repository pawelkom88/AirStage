import XCTest
import CoreGraphics
@testable import AirStage

final class AddNoteTests: XCTestCase {

    func testSelectingAddNoteEmitsIntentAndAddsNoteToStore() {
        let menuModel = MenuModel()
        let sceneStore = SceneStore()

        var emittedIntent: MenuIntent?
        menuModel.onIntent = { intent in
            emittedIntent = intent
            if intent == .addNote {
                _ = sceneStore.addNote(
                    title: "Sticky Note",
                    position: CGPoint(x: 320, y: 240),
                    size: CGSize(width: 150, height: 150)
                )
            }
        }

        // Enable addNote first (or verify it is enabled)
        let addNoteAction = menuModel.actions.first(where: { $0.id == .addNote })
        XCTAssertNotNil(addNoteAction)
        XCTAssertTrue(addNoteAction!.isEnabled)

        // Select it
        menuModel.select(.addNote)

        XCTAssertEqual(emittedIntent, .addNote)
        XCTAssertEqual(sceneStore.layers.count, 1)
        
        let note = sceneStore.layers.first!
        XCTAssertEqual(note.kind, .note)
        XCTAssertEqual(note.title, "Sticky Note")
        XCTAssertEqual(note.position, CGPoint(x: 320, y: 240))
        XCTAssertEqual(note.size, CGSize(width: 150, height: 150))
    }

    func testNewNoteSpawnsInsidePreviewBounds() {
        let sceneStore = SceneStore()
        let previewBounds = CGRect(x: 0, y: 0, width: 640, height: 480)

        let result = sceneStore.addNote(
            title: "Sticky Note",
            position: CGPoint(x: 320, y: 240),
            size: CGSize(width: 150, height: 150)
        )
        XCTAssertTrue(result.isSuccess)

        let note = sceneStore.layer(withID: result.layerID!)!
        let halfWidth = note.size.width / 2.0
        let halfHeight = note.size.height / 2.0
        let noteFrame = CGRect(
            x: note.position.x - halfWidth,
            y: note.position.y - halfHeight,
            width: note.size.width,
            height: note.size.height
        )

        XCTAssertTrue(previewBounds.contains(noteFrame), "New note must spawn fully inside preview bounds")
    }
}
