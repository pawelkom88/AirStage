import OSLog

enum AppLog {
    static let app = Logger(subsystem: "com.airstage.app", category: "App")
    static let menu = Logger(subsystem: "com.airstage.app", category: "Menu")
    static let camera = Logger(subsystem: "com.airstage.app", category: "Camera")
    static let scene = Logger(subsystem: "com.airstage.app", category: "Scene")
    static let sources = Logger(subsystem: "com.airstage.app", category: "Sources")
    static let gestures = Logger(subsystem: "com.airstage.app", category: "Gestures")
    static let onboarding = Logger(subsystem: "com.airstage.app", category: "Onboarding")
    static let settings = Logger(subsystem: "com.airstage.app", category: "Settings")
    static let virtualCamera = Logger(subsystem: "com.airstage.app", category: "VirtualCamera")
}
