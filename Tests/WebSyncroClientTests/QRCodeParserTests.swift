import XCTest
@testable import WebSyncroClient

final class QRCodeParserTests: XCTestCase {

    func testStandardQRCodeSlashFormat() {
        let sample = "EX Novo/CLI001/1234"
        let parsed = QRCodeParser.parse(qrString: sample)

        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.rawShop, "EX Novo")
        XCTAssertEqual(parsed?.cardCode, "CLI001")
        XCTAssertEqual(parsed?.pin, "1234")
    }

    func testQRCodeWithWhitespaceAndPipe() {
        let sample = " EX Novo | ABC999 | 5678 \n"
        let parsed = QRCodeParser.parse(qrString: sample)

        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.rawShop, "EX Novo")
        XCTAssertEqual(parsed?.cardCode, "ABC999")
        XCTAssertEqual(parsed?.pin, "5678")
    }

    func testInvalidQRCode() {
        XCTAssertNil(QRCodeParser.parse(qrString: ""))
        XCTAssertNil(QRCodeParser.parse(qrString: "SoloTesto"))
        XCTAssertNil(QRCodeParser.parse(qrString: "Shop/CardOnly"))
    }
}
