import XCTest
@testable import AirStage

final class SettingsStoreTests: XCTestCase {
    private var testDefaults: UserDefaults!
    private let suiteName = "com.airstage.test.settings"

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: suiteName)
        testDefaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: suiteName)
        testDefaults = nil
        super.tearDown()
    }

    func testDebugOverlaySettingPersists() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(store.debugOverlay)

        store.debugOverlay = true
        XCTAssertTrue(testDefaults.bool(forKey: "airStage.showDebug"))

        let secondStore = SettingsStore(defaults: testDefaults)
        XCTAssertTrue(secondStore.debugOverlay)
    }

    func testHandControlSettingPersists() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(store.handControl)

        store.handControl = true
        XCTAssertTrue(testDefaults.bool(forKey: "handControl"))

        let secondStore = SettingsStore(defaults: testDefaults)
        XCTAssertTrue(secondStore.handControl)
    }

    func testSnapToGridSettingPersists() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(store.snapToGrid)

        store.snapToGrid = true
        XCTAssertTrue(testDefaults.bool(forKey: "snapToGrid"))

        let secondStore = SettingsStore(defaults: testDefaults)
        XCTAssertTrue(secondStore.snapToGrid)
    }

    func testResetOnboardingClearsCompletedState() {
        let store = SettingsStore(defaults: testDefaults)
        testDefaults.set(true, forKey: "hasCompletedOnboarding")

        let exp = expectation(description: "notification received")
        let observer = NotificationCenter.default.addObserver(
            forName: .resetOnboardingRequested,
            object: nil,
            queue: .main
        ) { _ in
            exp.fulfill()
        }

        store.resetOnboarding()
        XCTAssertFalse(testDefaults.bool(forKey: "hasCompletedOnboarding"))

        wait(for: [exp], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
}
