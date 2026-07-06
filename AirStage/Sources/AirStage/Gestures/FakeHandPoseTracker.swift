import CoreVideo

public enum FakeHandPoseTrackerError: Error, Equatable {
    case noQueuedFrames
}

public final class FakeHandPoseTracker: HandPoseTracking {
    private var frames: [HandPoseFrame]

    public init(frames: [HandPoseFrame]) {
        self.frames = frames
    }

    public func nextFrame() async throws -> HandPoseFrame {
        guard !frames.isEmpty else {
            AppLog.gestures.debug("Fake hand pose tracker empty")
            throw FakeHandPoseTrackerError.noQueuedFrames
        }

        let frame = frames.removeFirst()
        AppLog.gestures.debug("Fake hand pose frame confidence=\(frame.confidence)")
        return frame
    }

    public func processFrame(_ frame: CVPixelBuffer) async throws -> HandPoseFrame {
        try await nextFrame()
    }
}
