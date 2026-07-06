import CoreGraphics
import CoreVideo
import Vision

public final class VisionHandPoseTracker: HandPoseTracking {
    public init() {}

    public func processFrame(_ frame: CVPixelBuffer) async throws -> HandPoseFrame {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1
        let handler = VNImageRequestHandler(cvPixelBuffer: frame, options: [:])

        do {
            try handler.perform([request])
            let poseFrame = Self.makeFrame(from: request.results?.first)
            AppLog.gestures.debug("Hand landmarks updated count=\(poseFrame.landmarkCount)")
            return poseFrame
        } catch {
            AppLog.gestures.error("Hand pose tracking failed error=\(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    private static func makeFrame(from observation: VNHumanHandPoseObservation?) -> HandPoseFrame {
        guard let observation else {
            return HandPoseFrame(indexTip: nil, thumbTip: nil, confidence: 0)
        }

        let indexTip = try? observation.recognizedPoint(.indexTip)
        let thumbTip = try? observation.recognizedPoint(.thumbTip)
        let confidence = min(
            Double(indexTip?.confidence ?? 0),
            Double(thumbTip?.confidence ?? 0)
        )

        return HandPoseFrame(
            indexTip: indexTip?.location,
            thumbTip: thumbTip?.location,
            confidence: confidence
        )
    }
}

private extension HandPoseFrame {
    var landmarkCount: Int {
        [indexTip, thumbTip].compactMap { $0 }.count
    }
}
