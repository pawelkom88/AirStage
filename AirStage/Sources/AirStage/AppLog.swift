import OSLog

public enum AppLog {
    public static let app = Logger(subsystem: "com.airstage.app", category: "App")
    public static let menu = Logger(subsystem: "com.airstage.app", category: "Menu")
    public static let camera = Logger(subsystem: "com.airstage.app", category: "Camera")
    public static let scene = Logger(subsystem: "com.airstage.app", category: "Scene")
    public static let sources = Logger(subsystem: "com.airstage.app", category: "Sources")
    public static let gestures = Logger(subsystem: "com.airstage.app", category: "Gestures")
    public static let onboarding = Logger(subsystem: "com.airstage.app", category: "Onboarding")
    public static let settings = Logger(subsystem: "com.airstage.app", category: "Settings")
    public static let virtualCamera = Logger(subsystem: "com.airstage.app", category: "VirtualCamera")
}
