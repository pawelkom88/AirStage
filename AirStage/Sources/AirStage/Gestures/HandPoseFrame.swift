import CoreGraphics

public struct HandPoseFrame: Equatable {
    public static let minimumConfidence = 0.5
    public static let maximumPinchCandidateDistance: CGFloat = 0.08

    public var indexTip: CGPoint?
    public var thumbTip: CGPoint?
    public var confidence: Double

    public init(indexTip: CGPoint?, thumbTip: CGPoint?, confidence: Double) {
        self.indexTip = indexTip
        self.thumbTip = thumbTip
        self.confidence = confidence
    }

    public var pinchDistance: CGFloat? {
        guard let indexTip, let thumbTip else { return nil }
        return hypot(indexTip.x - thumbTip.x, indexTip.y - thumbTip.y)
    }

    public var pinchCandidateCenter: CGPoint? {
        guard
            confidence >= Self.minimumConfidence,
            let distance = pinchDistance
        else {
            return nil
        }

        guard distance <= Self.maximumPinchCandidateDistance else {
            return nil
        }

        return CGPoint(
            x: (indexTip!.x + thumbTip!.x) / 2,
            y: (indexTip!.y + thumbTip!.y) / 2
        )
    }
}
