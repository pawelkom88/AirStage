import CoreGraphics
import XCTest
@testable import AirStage

final class GestureEngineTests: XCTestCase {

    func testCloseThumbAndIndexStartsPinch() {
        var engine = GestureEngine()

        let event = engine.process(closeFrame(at: CGPoint(x: 0.4, y: 0.6)))

        XCTAssertEqual(event, .pinchBegan(at: CGPoint(x: 0.4, y: 0.6)))
    }

    func testPinchMovementProducesMovedEvent() {
        var engine = GestureEngine()
        _ = engine.process(closeFrame(at: CGPoint(x: 0.4, y: 0.6)))

        let event = engine.process(closeFrame(at: CGPoint(x: 0.5, y: 0.7)))

        XCTAssertEqual(event, .pinchMoved(to: CGPoint(x: 0.5, y: 0.7)))
    }

    func testSeparatedFingersEndPinch() {
        var engine = GestureEngine()
        _ = engine.process(closeFrame(at: CGPoint(x: 0.4, y: 0.6)))

        let event = engine.process(separatedFrame())

        XCTAssertEqual(event, .pinchEnded)
    }

    func testLowConfidenceDoesNotStartPinch() {
        var engine = GestureEngine()

        let event = engine.process(
            HandPoseFrame(
                indexTip: CGPoint(x: 0.41, y: 0.6),
                thumbTip: CGPoint(x: 0.39, y: 0.6),
                confidence: 0.2
            )
        )

        XCTAssertEqual(event, .none)
    }

    private func closeFrame(at center: CGPoint) -> HandPoseFrame {
        HandPoseFrame(
            indexTip: CGPoint(x: center.x + 0.01, y: center.y),
            thumbTip: CGPoint(x: center.x - 0.01, y: center.y),
            confidence: 0.9
        )
    }

    private func separatedFrame() -> HandPoseFrame {
        HandPoseFrame(
            indexTip: CGPoint(x: 0.1, y: 0.1),
            thumbTip: CGPoint(x: 0.9, y: 0.9),
            confidence: 0.9
        )
    }
}
