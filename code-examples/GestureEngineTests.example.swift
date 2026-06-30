import XCTest
@testable import AirStage

final class GestureEngineTests: XCTestCase {
    func testCloseThumbAndIndexStartsPinch() {
        var engine = GestureEngine()
        let frame = HandPoseFrame(
            indexTip: CGPoint(x: 100, y: 100),
            thumbTip: CGPoint(x: 108, y: 104),
            confidence: 0.95
        )

        let event = engine.update(with: frame)

        XCTAssertEqual(event, .pinchBegan(location: CGPoint(x: 104, y: 102)))
    }

    func testLowConfidenceDoesNotStartPinch() {
        var engine = GestureEngine()
        let frame = HandPoseFrame(
            indexTip: CGPoint(x: 100, y: 100),
            thumbTip: CGPoint(x: 108, y: 104),
            confidence: 0.2
        )

        let event = engine.update(with: frame)

        XCTAssertEqual(event, .none)
    }
}
