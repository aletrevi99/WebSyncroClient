import XCTest
@testable import WebSyncroClient

@MainActor
final class DashboardViewModelTests: XCTestCase {

    var tempDefaults: UserDefaults!
    var suiteName: String!
    var accountStore: AccountStore!

    override func setUp() {
        super.setUp()
        suiteName = "it.websyncro.vmtest.\(UUID().uuidString)"
        tempDefaults = UserDefaults(suiteName: suiteName)!
        accountStore = AccountStore(userDefaults: tempDefaults)
    }

    override func tearDown() {
        tempDefaults.removePersistentDomain(forName: suiteName)
        tempDefaults = nil
        super.tearDown()
    }

    func testLoadDataWithMockService() async {
        let mockService = MockWebSyncroService()
        mockService.delayNanoseconds = 0
        let viewModel = DashboardViewModel(
            service: mockService,
            accountStore: accountStore
        )

        await viewModel.loadData()

        XCTAssertNotNil(viewModel.maturedReport)
        XCTAssertNotNil(viewModel.nonMaturedReport)
        XCTAssertEqual(viewModel.maturedReport?.shopId, "exnovomercatino")
        XCTAssertEqual(viewModel.totalMatured, Decimal(string: "10.13"))
        XCTAssertEqual(viewModel.totalNonMatured, Decimal(string: "2.25"))
        XCTAssertEqual(viewModel.grandTotal, Decimal(string: "12.38"))
        XCTAssertNil(viewModel.errorMessage)
    }

    func testTabSwitching() async {
        let mockService = MockWebSyncroService()
        mockService.delayNanoseconds = 0
        let viewModel = DashboardViewModel(
            service: mockService,
            accountStore: accountStore
        )

        await viewModel.loadData()

        viewModel.selectedTab = .matured
        XCTAssertEqual(viewModel.filteredItems.count, 8)

        viewModel.selectedTab = .nonMatured
        XCTAssertEqual(viewModel.filteredItems.count, 3)
    }

    func testSearchFiltering() async {
        let mockService = MockWebSyncroService()
        mockService.delayNanoseconds = 0
        let viewModel = DashboardViewModel(
            service: mockService,
            accountStore: accountStore
        )

        await viewModel.loadData()

        // Cerca "Luce" nel maturato
        viewModel.selectedTab = .matured
        viewModel.searchText = "Luce"
        XCTAssertEqual(viewModel.filteredItems.count, 1)
        XCTAssertTrue(viewModel.filteredItems[0].title.contains("Luce"))

        // Cerca per ID
        viewModel.searchText = "1260228"
        XCTAssertEqual(viewModel.filteredItems.count, 1)
        XCTAssertEqual(viewModel.filteredItems[0].id, "1260228")

        // Reset
        viewModel.searchText = ""
        XCTAssertEqual(viewModel.filteredItems.count, 8)
    }
}
