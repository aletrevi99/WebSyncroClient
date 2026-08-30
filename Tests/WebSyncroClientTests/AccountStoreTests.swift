import XCTest
@testable import WebSyncroClient

@MainActor
final class AccountStoreTests: XCTestCase {

    var tempDefaults: UserDefaults!
    var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "it.websyncro.test.\(UUID().uuidString)"
        tempDefaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        tempDefaults.removePersistentDomain(forName: suiteName)
        tempDefaults = nil
        super.tearDown()
    }

    func testAddAndSelectAccount() {
        let store = AccountStore(userDefaults: tempDefaults)

        let account = store.addAccount(
            shopId: "2050",
            userId: "999",
            alias: "Negozio Test Nord"
        )

        XCTAssertEqual(store.accounts.count, 2) // default + newly added
        XCTAssertEqual(store.activeAccountId, account.id)
        XCTAssertEqual(store.activeAccount?.accountAlias, "Negozio Test Nord")
    }

    func testUpdateAccount() {
        let store = AccountStore(userDefaults: tempDefaults)
        guard var first = store.accounts.first else {
            XCTFail("Account predefinito mancante")
            return
        }

        first.accountAlias = "Mercatino Rinominato"
        store.updateAccount(first)

        XCTAssertEqual(store.activeAccount?.accountAlias, "Mercatino Rinominato")
    }

    func testDeleteAccount() {
        let store = AccountStore(userDefaults: tempDefaults)
        let added = store.addAccount(shopId: "3000", userId: "100", alias: "Da Cancellare")

        XCTAssertEqual(store.activeAccountId, added.id)

        store.deleteAccount(id: added.id)

        XCTAssertFalse(store.accounts.contains(where: { $0.id == added.id }))
        XCTAssertNotEqual(store.activeAccountId, added.id)
    }

    func testRecordSuccessfulSync() {
        let store = AccountStore(userDefaults: tempDefaults)
        guard let account = store.activeAccount else {
            XCTFail("Nessun account attivo")
            return
        }

        store.recordSuccessfulSync(
            accountId: account.id,
            totalEarned: Decimal(string: "154.20")!,
            snapshotFolder: "SM_2026-08-29T19:54:28"
        )

        let updated = store.activeAccount
        XCTAssertNotNil(updated?.lastSyncDate)
        XCTAssertEqual(updated?.lastTotalEarned, Decimal(string: "154.20"))
        XCTAssertEqual(updated?.lastSnapshotFolder, "SM_2026-08-29T19:54:28")
    }
}

