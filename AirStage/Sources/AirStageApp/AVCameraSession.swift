import AVFoundation
import AirStage

/// Real AVCaptureSession-backed implementation of CameraSession.
final class AVCameraSession: CameraSession {

    private let captureSession = AVCaptureSession()
    private var hasStarted = false

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

            if let device = AVCaptureDevice.default(for: .video) {
                do {
                    let input = try AVCaptureDeviceInput(device: device)
                    if captureSession.canAddInput(input) {
                        captureSession.addInput(input)
                    } else {
                        errorToReport = "Cannot add camera input."
                    }
                } catch {
                    errorToReport = error.localizedDescription
                }
            } else {
                errorToReport = "No camera device found."
            }

            captureSession.commitConfiguration()

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
