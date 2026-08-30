import XCTest
@testable import WebSyncroClient

@MainActor
final class InventoryDeduplicationTests: XCTestCase {

    var store: InventoryStore!
    var userDefaults: UserDefaults!
    var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "it.websyncro.test.dedup.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)!
        store = InventoryStore(userDefaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        store = nil
        super.tearDown()
    }

    func testDeduplicationAndUserScoping() {
        let shop = "exnovomercatino"
        let user1 = "CLI001"
        let user2 = "CLI002"

        let itemA1 = InventoryItem(id: "1260214", title: "Libro 2", agreedPrice: Decimal(string: "2.70")!, shopId: shop, userCardCode: user1)
        let itemA2 = InventoryItem(id: "1260215", title: "Libro 3", agreedPrice: Decimal(string: "2.25")!, shopId: shop, userCardCode: user1)

        let initialBatch = InventoryBatch(
            listNumber: "2026/001",
            loadDate: Date(),
            shopId: shop,
            userCardCode: user1,
            items: [itemA1, itemA2]
        )

        let initialResult = store.addBatchWithDeduplication(batch: initialBatch)
        XCTAssertEqual(initialResult.addedCount, 2)
        XCTAssertEqual(initialResult.skippedCount, 0)
        XCTAssertEqual(store.items(for: shop, userCardCode: user1).count, 2)

        // Scansione 2 per lo stesso utente con 1 duplicato e 1 nuovo
        let itemA1Dup = InventoryItem(id: "1260214", title: "Libro 2", agreedPrice: Decimal(string: "2.70")!, shopId: shop, userCardCode: user1)
        let itemA3New = InventoryItem(id: "1260216", title: "Libro Nuovo", agreedPrice: Decimal(string: "3.00")!, shopId: shop, userCardCode: user1)

        let secondBatch = InventoryBatch(
            listNumber: "2026/002",
            loadDate: Date(),
            shopId: shop,
            userCardCode: user1,
            items: [itemA1Dup, itemA3New]
        )

        let analysis = store.analyzeBatchForDuplicates(batch: secondBatch, shopId: shop, userCardCode: user1)
        XCTAssertEqual(analysis.newItems.count, 1)
        XCTAssertEqual(analysis.duplicateItems.count, 1)
        XCTAssertEqual(analysis.newItems.first?.id, "1260216")
        XCTAssertEqual(analysis.duplicateItems.first?.id, "1260214")

        // Importazione con salto dei duplicati
        let secondResult = store.addBatchWithDeduplication(batch: secondBatch, overwriteDuplicates: false)
        XCTAssertEqual(secondResult.addedCount, 1)
        XCTAssertEqual(secondResult.skippedCount, 1)
        XCTAssertEqual(store.items(for: shop, userCardCode: user1).count, 3)

        // Verifica isolamento rispetto ad un altro utente (user2)
        XCTAssertEqual(store.items(for: shop, userCardCode: user2).count, 0)
    }
}

