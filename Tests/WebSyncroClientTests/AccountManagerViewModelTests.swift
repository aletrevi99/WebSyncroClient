import XCTest
@testable import WebSyncroClient

@MainActor
final class AccountManagerViewModelTests: XCTestCase {

    var tempDefaults: UserDefaults!
    var suiteName: String!
    var accountStore: AccountStore!

    override func setUp() {
        super.setUp()
        suiteName = "it.websyncro.mgrtest.\(UUID().uuidString)"
        tempDefaults = UserDefaults(suiteName: suiteName)!
        accountStore = AccountStore(userDefaults: tempDefaults)
    }

    override func tearDown() {
        tempDefaults.removePersistentDomain(forName: suiteName)
        tempDefaults = nil
        super.tearDown()
    }

    func testFormValidation() {
        let viewModel = AccountManagerViewModel(accountStore: accountStore)

        viewModel.prepareAddAccount()
        viewModel.formShopId = ""
        viewModel.formUserId = ""

        let success = viewModel.saveAccount()
        XCTAssertFalse(success)
        XCTAssertNotNil(viewModel.formValidationError)

        viewModel.formShopId = "1050"
        viewModel.formUserId = ""
        XCTAssertFalse(viewModel.saveAccount())

        viewModel.formUserId = "777"
        viewModel.formAlias = "Negozio Sud"
        XCTAssertTrue(viewModel.saveAccount())
        XCTAssertNil(viewModel.formValidationError)

        XCTAssertEqual(accountStore.accounts.count, 2)
        XCTAssertEqual(accountStore.activeAccount?.shopId, "1050")
        XCTAssertEqual(accountStore.activeAccount?.userId, "777")
    }

    func testEditAccount() {
        let viewModel = AccountManagerViewModel(accountStore: accountStore)
        guard let first = accountStore.accounts.first else {
            XCTFail("Account mancante")
            return
        }

        viewModel.prepareEditAccount(first)
        viewModel.formAlias = "Nuovo Alias Modificato"
        XCTAssertTrue(viewModel.saveAccount())

        XCTAssertEqual(accountStore.activeAccount?.accountAlias, "Nuovo Alias Modificato")
    }
}

