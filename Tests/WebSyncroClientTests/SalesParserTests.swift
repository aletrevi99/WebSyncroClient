import XCTest
@testable import WebSyncroClient

final class SalesParserTests: XCTestCase {

    func testStandardMaturatoParsing() {
        let sample = """
        1260224 28/08/2026 0,45€
        Sul Grappa dopo la vittoria Malaguti Paolo letteratura italiana
        1260225 28/08/2026 14,50€
        Giacca a vento The North Face taglia M azzurra
        1259981 26/08/2026 28,00€
        Lampada da tavolo vintage stile Bauhaus
        <#FINEELENCO>
        <#FRASEOPZIONALE>
        I pagamenti maturati sono ritirabili in cassa dal martedì al sabato.
        <#VISFRASEOPZSEMPRE>
        """

        let report = SalesParser.parse(
            content: sample,
            shopId: "1042",
            userId: "852",
            syncTimestamp: "SM_2026-08-29T19:54:28"
        )

        XCTAssertEqual(report.shopId, "1042")
        XCTAssertEqual(report.userId, "852")
        XCTAssertEqual(report.syncTimestamp, "SM_2026-08-29T19:54:28")
        XCTAssertEqual(report.itemsCount, 3)
        XCTAssertEqual(report.items.count, 3)

        // Verifica primo articolo
        let item1 = report.items[0]
        XCTAssertEqual(item1.id, "1260224")
        XCTAssertEqual(item1.dateString, "28/08/2026")
        XCTAssertEqual(item1.amount, Decimal(string: "0.45"))
        XCTAssertEqual(item1.title, "Sul Grappa dopo la vittoria Malaguti Paolo letteratura italiana")

        // Verifica totale (0.45 + 14.50 + 28.00 = 42.95)
        XCTAssertEqual(report.totalEarned, Decimal(string: "42.95"))

        // Verifica avviso opzionale
        XCTAssertEqual(report.optionalNotice, "I pagamenti maturati sono ritirabili in cassa dal martedì al sabato.")
    }

    func testEncodingAnomalyWithCorruptedEuroSymbol() {
        let corruptedSample = """
        1260224 28/08/2026 0,45â¬
        Sul Grappa dopo la vittoria
        1260226 29/08/2026 19,90\u{00E2}\u{00AC}
        Tavolino in noce
        <#FINEELENCO>
        """

        let report = SalesParser.parse(
            content: corruptedSample,
            shopId: "100",
            userId: "200",
            syncTimestamp: "SM_2026-08-29T10:00:00"
        )

        XCTAssertEqual(report.itemsCount, 2)
        XCTAssertEqual(report.items[0].amount, Decimal(string: "0.45"))
        XCTAssertEqual(report.items[1].amount, Decimal(string: "19.90"))
        XCTAssertEqual(report.totalEarned, Decimal(string: "20.35"))
    }

    func testMissingDescriptionLineFallback() {
        let sample = """
        1260224 28/08/2026 0,45€
        1260225 29/08/2026 10,00€
        Descrizione presente per il secondo
        <#FINEELENCO>
        """

        let report = SalesParser.parse(
            content: sample,
            shopId: "100",
            userId: "200",
            syncTimestamp: "SM_2026-08-29T10:00:00"
        )

        XCTAssertEqual(report.itemsCount, 2)
        XCTAssertEqual(report.items[0].title, "")
        XCTAssertEqual(report.items[0].displayTitle, "Articolo #1260224")
        XCTAssertEqual(report.items[1].title, "Descrizione presente per il secondo")
    }

    func testAmountParsingEdgeCases() {
        XCTAssertEqual(SalesParser.parseAmount("0,45€"), Decimal(string: "0.45"))
        XCTAssertEqual(SalesParser.parseAmount("0,45â¬"), Decimal(string: "0.45"))
        XCTAssertEqual(SalesParser.parseAmount("1.250,50€"), Decimal(string: "1250.50"))
        XCTAssertEqual(SalesParser.parseAmount("15.00 EUR"), Decimal(string: "15.00"))
        XCTAssertEqual(SalesParser.parseAmount("  100,00 €  "), Decimal(string: "100.00"))
        XCTAssertEqual(SalesParser.parseAmount("0,00"), Decimal(0))
        XCTAssertNil(SalesParser.parseAmount(""))
        XCTAssertNil(SalesParser.parseAmount("invalid"))
    }

    func testEmptyContent() {
        let report = SalesParser.parse(
            content: "<#FINEELENCO>",
            shopId: "100",
            userId: "200",
            syncTimestamp: "SM_2026-08-29T10:00:00"
        )

        XCTAssertEqual(report.itemsCount, 0)
        XCTAssertEqual(report.totalEarned, Decimal(0))
        XCTAssertNil(report.optionalNotice)
    }
}

