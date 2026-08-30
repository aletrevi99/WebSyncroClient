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

        let reloadedStore = AppSettingsStore(userDefaults: tempDefaults)
        XCTAssertFalse(reloadedStore.isExNovoOnlyMode)
    }

    func testOpenRouterApiKeyAndModel() {
        let store = AppSettingsStore(userDefaults: tempDefaults)
        store.openRouterApiKey = "sk-or-v1-test-12345"
        store.openRouterModel = "openai/gpt-4o-mini"

        XCTAssertEqual(store.openRouterApiKey, "sk-or-v1-test-12345")
        XCTAssertEqual(store.openRouterModel, "openai/gpt-4o-mini")

        let reloaded = AppSettingsStore(userDefaults: tempDefaults)
        XCTAssertEqual(reloaded.openRouterApiKey, "sk-or-v1-test-12345")
        XCTAssertEqual(reloaded.openRouterModel, "openai/gpt-4o-mini")
    }

    func testNotificationPreferences() {
        let store = AppSettingsStore(userDefaults: tempDefaults)
        XCTAssertTrue(store.notifyNewSales)
        XCTAssertTrue(store.notifyMaturedCredits)
        XCTAssertTrue(store.notifyDiscount50)
        XCTAssertTrue(store.notifyExpiringItems)
        XCTAssertTrue(store.notifyReturns)
        XCTAssertEqual(store.backgroundRefreshIntervalMinutes, 30)

        store.notifyReturns = false
        store.backgroundRefreshIntervalMinutes = 60

        let reloaded = AppSettingsStore(userDefaults: tempDefaults)
        XCTAssertFalse(reloaded.notifyReturns)
        XCTAssertEqual(reloaded.backgroundRefreshIntervalMinutes, 60)
    }

    func testReturnTracking() {
        let manager = NotificationManager.shared
        let initialCount = manager.returnHistory.count
        manager.recordReturn(itemId: "999", title: "Prodotto Test", amount: Decimal(5.50), shopId: "exnovomercatino")

        XCTAssertEqual(manager.returnHistory.count, initialCount + 1)
        XCTAssertEqual(manager.activeReturnAlert?.title, "Prodotto Test")

        manager.dismissActiveReturnAlert()
        XCTAssertNil(manager.activeReturnAlert)
    }
}
