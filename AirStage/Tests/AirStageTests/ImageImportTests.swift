import XCTest
import UniformTypeIdentifiers
@testable import AirStage

final class FakeImageSourcePicker: ImageSourcePicker {
    var pickedURL: URL?
    func pickImage(completion: @escaping (URL?) -> Void) {
        completion(pickedURL)
    }
}

final class ImageImportTests: XCTestCase {
    private var store: SceneStore!
    private var importer: ImageImporter!
    private var picker: FakeImageSourcePicker!

    override func setUp() {
        super.setUp()
        store = SceneStore()
        importer = ImageImporter(store: store)
        picker = FakeImageSourcePicker()
    }

    override func tearDown() {
        store = nil
        importer = nil
        picker = nil
        super.tearDown()
    }

    private func createTempFile(name: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent(name)
        try? "dummy data".write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func testShareImageAddsImageLayerFromSelectedFile() {
        let fileURL = createTempFile(name: "test_image.png")
        picker.pickedURL = fileURL

        let expectation = self.expectation(description: "picker completion")
        var resultId: UUID?

        picker.pickImage { [weak self] url in
            guard let self = self, let url = url else {
                XCTFail("Picker should have returned a URL")
                expectation.fulfill()
                return
            }
            let res = self.importer.importImage(from: url)
            if case .success(let id) = res {
                resultId = id
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)

        XCTAssertNotNil(resultId)
        guard let id = resultId else { return }
        let layer = store.layer(withID: id)
        XCTAssertNotNil(layer)
        XCTAssertEqual(layer?.kind, .image)
        XCTAssertEqual(layer?.imageURL, fileURL)
    }

    func testUnsupportedFileShowsFriendlyError() {
        let fileURL = createTempFile(name: "not_an_image.txt")
        let res = importer.importImage(from: fileURL)

        XCTAssertEqual(res, .failure(.unsupportedFormat))
        XCTAssertEqual(res.error?.errorDescription, "The selected file is not a supported image format. Please select a PNG, JPEG, HEIC, or TIFF image.")
    }

    func testImageLayerUsesFilenameAsTitle() {
        let fileURL = createTempFile(name: "cool_screenshot.heic")
        let res = importer.importImage(from: fileURL)

        XCTAssertTrue(res.isSuccess)
        guard let id = res.layerID else { return }
        let layer = store.layer(withID: id)
        XCTAssertEqual(layer?.title, "cool_screenshot.heic")
    }

    func testImageLayerLimitIsEnforced() {
        // Limit is 3 images
        for i in 1...3 {
            let fileURL = createTempFile(name: "img\(i).png")
            let res = importer.importImage(from: fileURL)
            XCTAssertTrue(res.isSuccess, "Should succeed adding image \(i)")
        }

        // 4th image should fail or replace oldest depending on option
        let fileURL4 = createTempFile(name: "img4.png")
        let res4 = importer.importImage(from: fileURL4, replaceOldestIfFull: false)
        XCTAssertEqual(res4, .failure(.limitExceeded))
        XCTAssertEqual(res4.error?.errorDescription, "Cannot add image layer. The maximum limit of 3 image layers has been reached.")

        // Test with replaceOldestIfFull: true
        let resReplace = importer.importImage(from: fileURL4, replaceOldestIfFull: true)
        XCTAssertTrue(resReplace.isSuccess, "Should replace oldest and succeed")
    }
}

// Helper helpers to make Result easier to read/assert in tests
extension Result {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var layerID: Success? {
        if case .success(let val) = self { return val }
        return nil
    }

    var error: Failure? {
        if case .failure(let err) = self { return err }
        return nil
    }
}
