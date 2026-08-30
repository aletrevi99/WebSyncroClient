import XCTest
@testable import WebSyncroClient

@MainActor
final class AppSettingsStoreTests: XCTestCase {

    var tempDefaults: UserDefaults!
    var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "it.websyncro.test.settings.\(UUID().uuidString)"
        tempDefaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        tempDefaults.removePersistentDomain(forName: suiteName)
        tempDefaults = nil
        super.tearDown()
    }

    func testDefaultAndToggleExNovoOnlyMode() {
        let store = AppSettingsStore(userDefaults: tempDefaults)
        XCTAssertTrue(store.isExNovoOnlyMode)

        store.isExNovoOnlyMode = false
        XCTAssertFalse(store.isExNovoOnlyMode)

        // Verifica che ricaricando lo store il valore persista
        let reloadedStore = AppSettingsStore(userDefaults: tempDefaults)
        XCTAssertFalse(reloadedStore.isExNovoOnlyMode)
    }

    func testCustomVisionApiKey() {
        let store = AppSettingsStore(userDefaults: tempDefaults)
        store.customVisionApiKey = "test_key_123"
        XCTAssertEqual(store.customVisionApiKey, "test_key_123")

        let reloaded = AppSettingsStore(userDefaults: tempDefaults)
        XCTAssertEqual(reloaded.customVisionApiKey, "test_key_123")
    }
}
