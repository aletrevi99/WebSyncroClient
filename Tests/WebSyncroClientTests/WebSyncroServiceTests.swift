import XCTest
@testable import WebSyncroClient

final class WebSyncroServiceTests: XCTestCase {

    func testExtractSnapshotsFromDirectoryListing() {
        let apacheHTML = """
        <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
        <html>
         <head>
          <title>Index of /WebSyncro/ClientiWebSyncro/Negozi/1042</title>
         </head>
         <body>
        <h1>Index of /WebSyncro/ClientiWebSyncro/Negozi/1042</h1>
        <table>
        <tr><td valign="top"><img src="/icons/folder.gif" alt="[DIR]"></td><td><a href="SM_2026-08-27T14:10:05/">SM_2026-08-27T14:10:05/</a></td></tr>
        <tr><td valign="top"><img src="/icons/folder.gif" alt="[DIR]"></td><td><a href="SM_2026-08-29T19:54:28/">SM_2026-08-29T19:54:28/</a></td></tr>
        <tr><td valign="top"><img src="/icons/folder.gif" alt="[DIR]"></td><td><a href="SM_2026-08-28T18:22:00/">SM_2026-08-28T18:22:00/</a></td></tr>
        </table>
        </body></html>
        """

        let snapshots = WebSyncroService.extractSnapshots(from: apacheHTML)

        XCTAssertEqual(snapshots.count, 3)
        // Il più recente deve essere in prima posizione (ordine cronologico decrescente)
        XCTAssertEqual(snapshots[0], "SM_2026-08-29T19:54:28")
        XCTAssertEqual(snapshots[1], "SM_2026-08-28T18:22:00")
        XCTAssertEqual(snapshots[2], "SM_2026-08-27T14:10:05")
    }

    func testMockServiceFetch() async throws {
        let mock = MockWebSyncroService()
        let report = try await mock.fetchSalesReport(shopId: "1042", userId: "852")

        XCTAssertEqual(report.shopId, "1042")
        XCTAssertEqual(report.userId, "852")
        XCTAssertGreaterThan(report.items.count, 0)
        XCTAssertGreaterThan(report.totalEarned, Decimal(0))
        XCTAssertNotNil(report.optionalNotice)
    }

    func testMockServiceFailure() async {
        let mock = MockWebSyncroService(shouldFail: true, mockError: .shopNotFound(shopId: "9999"))

        do {
            _ = try await mock.fetchSalesReport(shopId: "9999", userId: "1")
            XCTFail("Dovrebbe fallire")
        } catch let error as WebSyncroError {
            switch error {
            case .shopNotFound(let id):
                XCTAssertEqual(id, "9999")
            default:
                XCTFail("Tipo di errore inatteso: \(error)")
            }
        } catch {
            XCTFail("Tipo di errore inatteso: \(error)")
        }
    }
}

