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
            mockService: mockService,
            accountStore: accountStore
        )

        await viewModel.loadData()

        XCTAssertNotNil(viewModel.report)
        XCTAssertEqual(viewModel.report?.shopId, "1042")
        XCTAssertEqual(viewModel.report?.userId, "852")
        XCTAssertGreaterThan(viewModel.filteredItems.count, 0)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSearchFiltering() async {
        let mockService = MockWebSyncroService()
        mockService.delayNanoseconds = 0
        let viewModel = DashboardViewModel(
            service: mockService,
            mockService: mockService,
            accountStore: accountStore
        )

        await viewModel.loadData()

        // Cerca "North Face"
        viewModel.searchText = "North Face"
        XCTAssertEqual(viewModel.filteredItems.count, 1)
        XCTAssertTrue(viewModel.filteredItems[0].title.contains("North Face"))

        // Cerca per ID
        viewModel.searchText = "1260224"
        XCTAssertEqual(viewModel.filteredItems.count, 1)
        XCTAssertEqual(viewModel.filteredItems[0].id, "1260224")

        // Reset
        viewModel.searchText = ""
        XCTAssertEqual(viewModel.filteredItems.count, 8)
    }

    func testSortingOptions() async {
        let mockService = MockWebSyncroService()
        mockService.delayNanoseconds = 0
        let viewModel = DashboardViewModel(
            service: mockService,
            mockService: mockService,
            accountStore: accountStore
        )

        await viewModel.loadData()

        // Ordina per importo maggiore
        viewModel.sortOption = .amountDescending
        if let first = viewModel.filteredItems.first, let last = viewModel.filteredItems.last {
            XCTAssertGreaterThanOrEqual(first.amount, last.amount)
        }

        // Ordina per importo minore
        viewModel.sortOption = .amountAscending
        if let first = viewModel.filteredItems.first, let last = viewModel.filteredItems.last {
            XCTAssertLessThanOrEqual(first.amount, last.amount)
        }
    }
}

