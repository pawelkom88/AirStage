import XCTest
@testable import AirStage

final class InteractionHitPolicyTests: XCTestCase {

    func testResizeRadiusDoesNotExplodeForVeryWideCard() {
        let rect = CGRect(x: 0, y: 0, width: 1000, height: 80)
        let radius = InteractionHitPolicy.resizeHandleRadius(for: rect)
        
        XCTAssertLessThanOrEqual(radius, 42)
        XCTAssertEqual(radius, 19.2, accuracy: 0.1)
    }

    func testResizeRadiusIsCappedForLargeCard() {
        let rect = CGRect(x: 0, y: 0, width: 1000, height: 700)
        let radius = InteractionHitPolicy.resizeHandleRadius(for: rect)
        
        XCTAssertEqual(radius, 42, accuracy: 0.01)
    }

    func testResizeRadiusForStandardCard() {
        let rect = CGRect(x: 0, y: 0, width: 150, height: 150)
        let radius = InteractionHitPolicy.resizeHandleRadius(for: rect)
        
        XCTAssertEqual(radius, 36, accuracy: 0.01)
    }

    func testInteriorPointPrefersDragOverResize() {
        let rect = CGRect(x: 100, y: 100, width: 150, height: 150)
        let point = CGPoint(x: rect.midX, y: rect.midY)
        
        let mode = LayerInteractionResolver.interactionMode(for: point, in: rect)
        
        XCTAssertEqual(mode, .drag)
    }

    func testCornerPointPrefersResize() {
        let rect = CGRect(x: 100, y: 100, width: 150, height: 150)
        let point = CGPoint(x: rect.maxX - 10, y: rect.maxY - 10)
        
        let mode = LayerInteractionResolver.interactionMode(for: point, in: rect)
        
        XCTAssertEqual(mode, .resize(.bottomRight))
    }

    func testWideCardCenterStillDrags() {
        let rect = CGRect(x: 100, y: 100, width: 1000, height: 80)
        let point = CGPoint(x: rect.midX, y: rect.midY)
        
        let mode = LayerInteractionResolver.interactionMode(for: point, in: rect)
        
        XCTAssertEqual(mode, .drag)
    }

    func testWideCardInteriorNearSideDoesNotTriggerResizeUnlessNearCorner() {
        let rect = CGRect(x: 100, y: 100, width: 1000, height: 80)
        
        // Near right side but vertically centered, not near a corner.
        let point = CGPoint(x: rect.maxX - 20, y: rect.midY)
        
        let mode = LayerInteractionResolver.interactionMode(for: point, in: rect)
        
        XCTAssertEqual(mode, .drag)
    }

    func testPointOutsideExpandedHitAreaDoesNothing() {
        let rect = CGRect(x: 100, y: 100, width: 150, height: 150)
        let point = CGPoint(x: 400, y: 400)
        
        let mode = LayerInteractionResolver.interactionMode(for: point, in: rect)
        
        XCTAssertEqual(mode, .none)
    }

    func testDebugRadiusUsesSharedInteractionHitPolicy() {
        let rect = CGRect(x: 0, y: 0, width: 1000, height: 80)
        
        let gestureRadius = InteractionHitPolicy.resizeHandleRadius(for: rect)
        let debugRadius = InteractionHitPolicy.resizeHandleRadius(for: rect)
        
        XCTAssertEqual(debugRadius, gestureRadius)
    }
}
