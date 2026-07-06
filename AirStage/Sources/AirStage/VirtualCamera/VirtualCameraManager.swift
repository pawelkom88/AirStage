import Foundation
import OSLog

public enum VirtualCameraStatus: Equatable {
    case notInstalled
    case pendingApproval
    case installed
    case error(String)

    public var userFriendlyMessage: String {
        switch self {
        case .notInstalled:
            return "Virtual camera is not installed."
        case .pendingApproval:
            return "Virtual camera installation pending system approval. Please check System Settings -> Privacy & Security -> Camera/Extensions."
        case .installed:
            return "Virtual camera is ready."
        case .error(let msg):
            return "Virtual camera error: \(msg)"
        }
    }
}

public final class VirtualCameraManager: ObservableObject {
    @Published public private(set) var status: VirtualCameraStatus = .notInstalled

    public init() {}

    public func requestInstall() {
        AppLog.virtualCamera.info("Virtual camera install requested")
        // Real system extension request needs developer signing.
        // We set status to pendingApproval and log action.
        self.status = .pendingApproval
        AppLog.virtualCamera.info("Virtual camera status updated to pendingApproval")
    }

    public func updateStatus(_ newStatus: VirtualCameraStatus) {
        self.status = newStatus
        AppLog.virtualCamera.info("Virtual camera status manually updated to \(String(describing: newStatus))")
    }
}
