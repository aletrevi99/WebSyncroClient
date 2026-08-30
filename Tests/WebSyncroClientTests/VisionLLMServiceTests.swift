import XCTest
@testable import WebSyncroClient

final class VisionLLMServiceTests: XCTestCase {

    func testParseLLMResponseWithMarkdownCodeBlock() throws {
        let sampleLLMJSON = """
        {
          "id": "gen-12345",
          "choices": [
            {
              "message": {
                "role": "assistant",
                "content": "Ecco i dati estratti dal documento:\\n\\n```json\\n{\\n  \\"list_number\\": \\"2026/009938\\",\\n  \\"load_date\\": \\"11/06/2026\\",\\n  \\"total_pieces\\": 35,\\n  \\"total_agreed_value\\": 84.15,\\n  \\"total_exposed_value\\": 93.50,\\n  \\"items\\": [\\n    {\\n      \\"code\\": \\"1.260.214\\",\\n      \\"title\\": \\"Libro 2\\",\\n      \\"category\\": \\"LI\\",\\n      \\"quantity\\": 6,\\n      \\"agreed_price\\": 2.70,\\n      \\"client_payout\\": 1.35,\\n      \\"exposed_price\\": 3.00\\n    },\\n    {\\n      \\"code\\": \\"1.260.215\\",\\n      \\"title\\": \\"Libro 3-4\\",\\n      \\"category\\": \\"LI\\",\\n      \\"quantity\\": 14,\\n      \\"agreed_price\\": 2.25,\\n      \\"client_payout\\": 1.12,\\n      \\"exposed_price\\": 2.50\\n    }\\n  ]\\n}\\n```"
              }
            }
          ]
        }
        """

        let data = sampleLLMJSON.data(using: .utf8)!
        let batch = try OpenRouterVisionService.parseLLMResponse(
            data: data,
            shopId: "exnovomercatino",
            userCardCode: "CLI001"
        )

        XCTAssertEqual(batch.listNumber, "2026/009938")
        XCTAssertEqual(batch.shopId, "exnovomercatino")
        XCTAssertEqual(batch.userCardCode, "CLI001")
        XCTAssertEqual(batch.totalAgreedValue, Decimal(string: "84.15"))
        XCTAssertEqual(batch.totalExposedValue, Decimal(string: "93.50"))
        XCTAssertEqual(batch.items.count, 2)

        let item1 = batch.items[0]
        XCTAssertEqual(item1.id, "1260214")
        XCTAssertEqual(item1.title, "Libro 2")
        XCTAssertEqual(item1.quantity, 6)
        XCTAssertEqual(item1.agreedPrice, Decimal(string: "2.70"))
        XCTAssertEqual(item1.clientPayoutInitial, Decimal(string: "1.35"))
        XCTAssertEqual(item1.exposedPriceInitial, Decimal(string: "3.00"))

        let item2 = batch.items[1]
        XCTAssertEqual(item2.id, "1260215")
        XCTAssertEqual(item2.title, "Libro 3-4")
        XCTAssertEqual(item2.quantity, 14)
    }

    func testParseBatchJSONDirectly() throws {
        let directJSON = """
        {
          "list_number": "2026/009938",
          "load_date": "11/06/2026",
          "total_pieces": 1,
          "total_agreed_value": 2.70,
          "total_exposed_value": 3.00,
          "items": [
            {
              "code": "1.260.216",
              "title": "La ragazza con l'orecchino di perla",
              "category": "LI",
              "quantity": 1,
              "agreed_price": 2.70,
              "client_payout": 1.35,
              "exposed_price": 3.00
            }
          ]
        }
        """

        let data = directJSON.data(using: .utf8)!
        let batch = try OpenRouterVisionService.parseBatchJSON(
            data: data,
            shopId: "exnovomercatino",
            userCardCode: "CLI001"
        )

        XCTAssertEqual(batch.items.count, 1)
        XCTAssertEqual(batch.items[0].id, "1260216")
        XCTAssertEqual(batch.items[0].title, "La ragazza con l'orecchino di perla")
    }
}
