import SwiftUI

public struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    @ObservedObject var cameraManager: VirtualCameraManager

    public init(store: SettingsStore, cameraManager: VirtualCameraManager) {
        self.store = store
        self.cameraManager = cameraManager
    }

    public var body: some View {
        Form {
            Section("About") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AirStage")
                        .font(.system(.headline, design: .rounded))
                    Text("Version 1.0 (Dev Build)")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                    Text("Local preview build")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }

            Section("General") {
                Toggle(isOn: $store.launchAtLogin) {
                    Text("Launch at login")
                }
                .toggleStyle(.switch)
            }

            Section("Gestures") {
                Toggle(isOn: $store.handControl) {
                    HStack(spacing: 8) {
                        Text("Hand control")
                        Text("Experimental")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                }
                .toggleStyle(.switch)

                Toggle(isOn: $store.snapToGrid) {
                    Text("Snap to grid")
                }
                .toggleStyle(.switch)
            }

            Section("Virtual Camera") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(cameraManager.status.userFriendlyMessage)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    if cameraManager.status == .notInstalled {
                        Button("Install Virtual Camera") {
                            cameraManager.requestInstall()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }

            Section("Onboarding") {
                Button("Reset Onboarding") {
                    store.resetOnboarding()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 380)
    }
}
