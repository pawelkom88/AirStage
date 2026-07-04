import XCTest
import CoreGraphics
@testable import AirStage

final class SceneGeometryTests: XCTestCase {
    func testClampPositionKeepsLayerPartiallyVisible() {
        let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
        let size = CGSize(width: 100, height: 100)

        // Inside bounds -> unchanged
        let pos1 = CGPoint(x: 320, y: 240)
        XCTAssertEqual(SceneGeometry.clampPosition(pos1, size: size, in: bounds), pos1)

        // Too far left -> clamped to min X
        let pos2 = CGPoint(x: -500, y: 240)
        XCTAssertEqual(SceneGeometry.clampPosition(pos2, size: size, in: bounds), CGPoint(x: -30, y: 240))

        // Too far right -> clamped to max X
        let pos3 = CGPoint(x: 1000, y: 240)
        XCTAssertEqual(SceneGeometry.clampPosition(pos3, size: size, in: bounds), CGPoint(x: 670, y: 240))

        // Too far top -> clamped to min Y
        let pos4 = CGPoint(x: 320, y: -500)
        XCTAssertEqual(SceneGeometry.clampPosition(pos4, size: size, in: bounds), CGPoint(x: 320, y: -30))

        // Too far bottom -> clamped to max Y
        let pos5 = CGPoint(x: 320, y: 1000)
        XCTAssertEqual(SceneGeometry.clampPosition(pos5, size: size, in: bounds), CGPoint(x: 320, y: 510))
    }
}
