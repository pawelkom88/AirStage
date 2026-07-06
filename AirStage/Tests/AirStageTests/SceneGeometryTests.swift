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

    func testConvertHandPointToCanvas() {
        let canvas = CGSize(width: 640, height: 480)

        // Center point
        let center = CGPoint(x: 0.5, y: 0.5)
        XCTAssertEqual(SceneGeometry.convertHandPointToCanvas(center, canvasSize: canvas, isMirrored: false), CGPoint(x: 320, y: 240))
        XCTAssertEqual(SceneGeometry.convertHandPointToCanvas(center, canvasSize: canvas, isMirrored: true), CGPoint(x: 320, y: 240))

        // Top-left in Vision (0.0, 1.0) -> Top-left in Canvas (0.0, 0.0) without mirroring
        // With mirroring: Top-right in Canvas (640, 0)
        let topLeft = CGPoint(x: 0.0, y: 1.0)
        XCTAssertEqual(SceneGeometry.convertHandPointToCanvas(topLeft, canvasSize: canvas, isMirrored: false), CGPoint(x: 0, y: 0))
        XCTAssertEqual(SceneGeometry.convertHandPointToCanvas(topLeft, canvasSize: canvas, isMirrored: true), CGPoint(x: 640, y: 0))

        // Bottom-right in Vision (1.0, 0.0) -> Bottom-right in Canvas (640, 480) without mirroring
        // With mirroring: Bottom-left in Canvas (0, 480)
        let bottomRight = CGPoint(x: 1.0, y: 0.0)
        XCTAssertEqual(SceneGeometry.convertHandPointToCanvas(bottomRight, canvasSize: canvas, isMirrored: false), CGPoint(x: 640, y: 480))
        XCTAssertEqual(SceneGeometry.convertHandPointToCanvas(bottomRight, canvasSize: canvas, isMirrored: true), CGPoint(x: 0, y: 480))
    }

    func testCanvasGeometryUsesCurrentViewSizeForHandConversion() {
        let geometry = CanvasGeometry(
            viewSize: CGSize(width: 1000, height: 800),
            sourceAspectRatio: 4.0 / 3.0,
            contentMode: .fill,
            isMirrored: false
        )

        let point = geometry.convertHandPointToCanvas(CGPoint(x: 0.5, y: 0.5))

        XCTAssertEqual(point.x, 500, accuracy: 0.01)
        XCTAssertEqual(point.y, 400, accuracy: 0.01)
    }

    @MainActor
    func testCanvasGeometryUpdatesSceneBoundsAfterResize() {
        let vm = PreviewViewModel(
            permissionService: FakeCameraPermissionService(status: .authorized),
            sceneStore: SceneStore(),
            settingsStore: SettingsStore(defaults: UserDefaults(suiteName: "com.airstage.test.resize")!)
        )

        vm.updateCanvasSize(CGSize(width: 1200, height: 700))

        XCTAssertEqual(vm.sceneBounds.size.width, 1200, accuracy: 0.01)
        XCTAssertEqual(vm.sceneBounds.size.height, 700, accuracy: 0.01)
    }
}
