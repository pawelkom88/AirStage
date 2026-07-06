import CoreGraphics
import XCTest
@testable import AirStage

final class HandPoseTrackingTests: XCTestCase {

    func testFakeHandPoseFrameCanRepresentPinchCandidate() {
        let frame = HandPoseFrame(
            indexTip: CGPoint(x: 0.52, y: 0.48),
            thumbTip: CGPoint(x: 0.50, y: 0.50),
            confidence: 0.91
        )

        XCTAssertEqual(frame.indexTip, CGPoint(x: 0.52, y: 0.48))
        XCTAssertEqual(frame.thumbTip, CGPoint(x: 0.50, y: 0.50))
        XCTAssertEqual(frame.confidence, 0.91)
        XCTAssertNotNil(frame.pinchCandidateCenter)
    }

    func testNoLandmarksProducesNoGestureCandidate() {
        let frame = HandPoseFrame(indexTip: nil, thumbTip: nil, confidence: 0.95)

        XCTAssertNil(frame.pinchCandidateCenter)
    }

    func testLowConfidenceFrameIgnored() {
        let frame = HandPoseFrame(
            indexTip: CGPoint(x: 0.52, y: 0.48),
            thumbTip: CGPoint(x: 0.50, y: 0.50),
            confidence: 0.2
        )

        XCTAssertNil(frame.pinchCandidateCenter)
    }

    func testFakeHandPoseTrackerReturnsQueuedFrames() async throws {
        let expected = HandPoseFrame(
            indexTip: CGPoint(x: 0.25, y: 0.75),
            thumbTip: CGPoint(x: 0.27, y: 0.76),
            confidence: 0.88
        )
        let tracker = FakeHandPoseTracker(frames: [expected])

        let actual = try await tracker.nextFrame()

        XCTAssertEqual(actual, expected)
    }
}
