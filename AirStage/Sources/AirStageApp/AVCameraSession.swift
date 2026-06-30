import AVFoundation
import AirStage

/// Real AVCaptureSession-backed implementation of CameraSession.
final class AVCameraSession: CameraSession {

    private let captureSession = AVCaptureSession()

    func start(completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .high

            guard let device = AVCaptureDevice.default(for: .video) else {
                DispatchQueue.main.async {
                    completion("No camera device found.")
                }
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                }
            } catch {
                self.captureSession.commitConfiguration()
                DispatchQueue.main.async {
                    completion(error.localizedDescription)
                }
                return
            }

            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()

            DispatchQueue.main.async {
                AppLog.camera.info("Camera session starting device=\(device.localizedName, privacy: .public)")
                completion(nil)
            }
        }
    }

    func stop() {
        captureSession.stopRunning()
    }

    /// The underlying AVCaptureSession for attaching a preview layer.
    var session: AVCaptureSession { captureSession }
}
