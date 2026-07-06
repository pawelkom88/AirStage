import AVFoundation
import AirStage

/// Real AVCaptureSession-backed implementation of CameraSession.
final class AVCameraSession: NSObject, CameraSession {

    private let captureSession = AVCaptureSession()
    private var hasStarted = false
    var onFrameCaptured: ((CVPixelBuffer) -> Void)?

    func start(completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            guard !hasStarted else {
                DispatchQueue.main.async {
                    completion("Camera session already started.")
                }
                return
            }

            captureSession.beginConfiguration()
            captureSession.sessionPreset = .high

            var errorToReport: String?
            let videoDataOutput = AVCaptureVideoDataOutput()

            if let device = AVCaptureDevice.default(for: .video) {
                do {
                    let input = try AVCaptureDeviceInput(device: device)
                    if captureSession.canAddInput(input) {
                        captureSession.addInput(input)
                    } else {
                        errorToReport = "Cannot add camera input."
                    }

                    videoDataOutput.alwaysDiscardsLateVideoFrames = true
                    videoDataOutput.videoSettings = [
                        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                    ]
                    let queue = DispatchQueue(label: "com.airstage.camera.outputQueue", qos: .userInteractive)
                    videoDataOutput.setSampleBufferDelegate(self, queue: queue)

                    if captureSession.canAddOutput(videoDataOutput) {
                        captureSession.addOutput(videoDataOutput)
                    } else if errorToReport == nil {
                        errorToReport = "Cannot add video data output."
                    }
                } catch {
                    errorToReport = error.localizedDescription
                }
            } else {
                errorToReport = "No camera device found."
            }

            captureSession.commitConfiguration()

            if errorToReport == nil {
                if let connection = videoDataOutput.connection(with: .video) {
                    if connection.isVideoMirroringSupported {
                        connection.automaticallyAdjustsVideoMirroring = false
                        connection.isVideoMirrored = true
                    }
                }
            }

            if let error = errorToReport {
                DispatchQueue.main.async {
                    completion(error)
                }
            } else {
                hasStarted = true
                captureSession.startRunning()
                DispatchQueue.main.async {
                    AppLog.camera.info("Camera session started")
                    completion(nil)
                }
            }
        }
    }

    func stop() {
        hasStarted = false
        captureSession.stopRunning()
    }

    /// The underlying AVCaptureSession for attaching a preview layer.
    var session: AVCaptureSession { captureSession }
}

extension AVCameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        onFrameCaptured?(pixelBuffer)
    }
}
