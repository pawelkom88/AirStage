import XCTest
@testable import AirStage

@MainActor
final class DebugOverlayTests: XCTestCase {

    // MARK: - Visibility

    func testDebugOverlayHiddenByDefault() {
        let settings = SettingsStore(defaults: makeTestDefaults())
        let vm = PreviewViewModel(
            permissionService: FakeCameraPermissionService(status: .authorized),
            sceneStore: SceneStore(),
            settingsStore: settings
        )
        XCTAssertFalse(vm.isDebugOverlayVisible)
    }

    func testDebugOverlayVisibleWhenSettingEnabled() {
        let defaults = makeTestDefaults()
        defaults.set(true, forKey: "airStage.showDebug")
        let settings = SettingsStore(defaults: defaults)
        let vm = PreviewViewModel(
            permissionService: FakeCameraPermissionService(status: .authorized),
            sceneStore: SceneStore(),
            settingsStore: settings
        )
        XCTAssertTrue(vm.isDebugOverlayVisible)
    }

    // MARK: - Content

    func testDebugOverlayShowsLayerCountAndSelectedLayer() {
        let store = SceneStore()
        let settings = SettingsStore(defaults: makeTestDefaults())
        settings.debugOverlay = true
        let vm = PreviewViewModel(
            permissionService: FakeCameraPermissionService(status: .authorized),
            sceneStore: store,
            settingsStore: settings
        )

        // No layers yet
        var state = vm.debugOverlaySnapshot()
        XCTAssertEqual(state.layerCount, 0)
        XCTAssertNil(state.selectedLayerTitle)

        // Add and select a note
        let result = store.addNote(title: "Meeting Notes", position: .zero, size: CGSize(width: 150, height: 150))
        if let id = result.layerID {
            store.selectLayer(id)
        }

        state = vm.debugOverlaySnapshot()
        XCTAssertEqual(state.layerCount, 1)
        XCTAssertEqual(state.selectedLayerTitle, "Meeting Notes")
    }

    func testDebugOverlayShowsCameraStatus() {
        let settings = SettingsStore(defaults: makeTestDefaults())
        settings.debugOverlay = true

        let vmReady = PreviewViewModel(
            permissionService: FakeCameraPermissionService(status: .authorized),
            sceneStore: SceneStore(),
            settingsStore: settings
        )
        XCTAssertEqual(vmReady.debugOverlaySnapshot().cameraStatus, "ready")

        let vmDenied = PreviewViewModel(
            permissionService: FakeCameraPermissionService(status: .denied),
            sceneStore: SceneStore(),
            settingsStore: settings
        )
        XCTAssertEqual(vmDenied.debugOverlaySnapshot().cameraStatus, "permissionRequired")
    }

    func testDebugOverlayShowsHandControlAndGesturePlaceholder() {
        let defaults = makeTestDefaults()
        let settings = SettingsStore(defaults: defaults)
        settings.debugOverlay = true
        settings.handControl = true

        let vm = PreviewViewModel(
            permissionService: FakeCameraPermissionService(status: .authorized),
            sceneStore: SceneStore(),
            settingsStore: settings
        )

        let state = vm.debugOverlaySnapshot()
        XCTAssertTrue(state.handControlEnabled)
        XCTAssertEqual(state.gestureState, "idle")
    }

    // MARK: - Helpers

    private let suiteName = "com.airstage.test.debugOverlay"

    private func makeTestDefaults() -> UserDefaults {
        let d = UserDefaults(suiteName: suiteName)!
        d.removePersistentDomain(forName: suiteName)
        return d
    }
}
