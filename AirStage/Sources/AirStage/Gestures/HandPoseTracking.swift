import CoreVideo

public protocol HandPoseTracking {
    func processFrame(_ frame: CVPixelBuffer) async throws -> HandPoseFrame
}
