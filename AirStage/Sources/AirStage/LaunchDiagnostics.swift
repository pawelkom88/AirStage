import Foundation

public enum LaunchDiagnostics {
    public static func logStartup() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
        AppLog.app.info("AirStage launched version=\(version, privacy: .public)")
    }
}
