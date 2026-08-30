import XCTest
@testable import WebSyncroClient

final class SalesParserTests: XCTestCase {

    func testStandardMaturatoParsingTitleFirst() {
        let sample = """
        <#DATA>
        29/08/2026 19:53
        <#TOTALE>
        14,87€
        <#INIZIOELENCO>
        Luce, suono, elettricità. Ediz. illustrata Leonardi Antonio classici ragazzi
        1260228 11/06/2026 0,90€
        Happy Feet la storia con le immagini del film  ragazzi 7-10 anni
        1260218 13/06/2026 0,90€
        Libro
        1260214 21/06/2026 1,35€
        <#FINEELENCO>
        <#FRASEOPZIONALE>
        I pagamenti maturati sono ritirabili in cassa dal martedì al sabato.
        <#VISFRASEOPZSEMPRE>
        FALSE
        """

        let report = SalesParser.parse(
            content: sample,
            shopId: "exnovomercatino",
            userId: "TRE091_1762",
            syncTimestamp: "SM_2026-08-29T19:54:28"
        )

        XCTAssertEqual(report.shopId, "exnovomercatino")
        XCTAssertEqual(report.userId, "TRE091_1762")
        XCTAssertEqual(report.itemsCount, 3)
        XCTAssertEqual(report.items.count, 3)

        // Verifica primo articolo
        let item1 = report.items[0]
        XCTAssertEqual(item1.id, "1260228")
        XCTAssertEqual(item1.dateString, "11/06/2026")
        XCTAssertEqual(item1.amount, Decimal(string: "0.90"))
        XCTAssertEqual(item1.title, "Luce, suono, elettricità. Ediz. illustrata Leonardi Antonio classici ragazzi")

        // Verifica totale (0.90 + 0.90 + 1.35 = 3.15)
        XCTAssertEqual(report.totalEarned, Decimal(string: "3.15"))
        XCTAssertEqual(report.optionalNotice, "I pagamenti maturati sono ritirabili in cassa dal martedì al sabato.")
    }

    func testNonMaturatoParsing() {
        let sample = """
        <#DATA>
        29/08/2026 19:53
        <#TOTALE>
        2,25€
        <#INIZIOELENCO>
        La ragazza con l'orecchino di perla. Ediz. speciale Chevalier Tracy classici stranieri
        1260216 24/08/2026 0,90€
        Doppio gioco Brambati Pietro letteratura italiana
        1260224 28/08/2026 0,45€
        Sul Grappa dopo la vittoria Malaguti Paolo letteratura italiana
        1260229 28/08/2026 0,90€
        <#FINEELENCO>
        <#FRASEOPZIONALE>
        Articoli venduti ma non rimborsabile
        <#VISFRASEOPZSEMPRE>
        FALSE
        """

        let report = SalesParser.parse(
            content: sample,
            shopId: "exnovomercatino",
            userId: "TRE091_1762",
            syncTimestamp: "SM_2026-08-29T19:54:28",
            isNonMatured: true
        )

        XCTAssertEqual(report.itemsCount, 3)
        XCTAssertTrue(report.isNonMatured)
        XCTAssertEqual(report.totalEarned, Decimal(string: "2.25"))
        XCTAssertEqual(report.items[0].isNonMatured, true)
        XCTAssertEqual(report.items[0].id, "1260216")
    }

    func testParseShopDirectory() {
        let sampleDirectory = """
        Armadio dell'Usato/armadiodellusato/Corso Milano 122A/37138 Verona (VR)/045 8031777//info@leotron.com
        Mercatino Store/mercatinostore/Via G. Mazzini 91/36027 Rosà (VI)/0424 582956//info@mercatinostore.com
        EX Novo/exnovomercatino/Via Vicenza 23/31050 Vedelago (TV)/042 3700120//info@exnovomercatino.it
        """

        let shops = SalesParser.parseShopDirectory(content: sampleDirectory)

        XCTAssertEqual(shops.count, 3)
        XCTAssertEqual(shops[0].name, "Armadio dell'Usato")
        XCTAssertEqual(shops[0].slug, "armadiodellusato")
        XCTAssertEqual(shops[2].name, "EX Novo")
        XCTAssertEqual(shops[2].slug, "exnovomercatino")
        XCTAssertEqual(shops[2].address, "Via Vicenza 23")
        XCTAssertEqual(shops[2].cityZip, "31050 Vedelago (TV)")
        XCTAssertEqual(shops[2].phone, "042 3700120")
        XCTAssertEqual(shops[2].email, "info@exnovomercatino.it")
    }

    func testParseOrarioTxt() {
        let rawOrario = "0-09:30-12:30-15:00-19:30|0-09:30-12:30-15:00-19:30|0-09:30-12:30-15:00-19:30|0-09:30-12:30-15:00-19:30|0-09:30-12:30-15:00-19:30|0-09:30-12:30-15:00-19:30|1-00:00-00:00-00:00-00:00"

        let schedule = SalesParser.parseSchedule(content: rawOrario)

        XCTAssertEqual(schedule.count, 7)

        // Lunedì
        let lunedi = schedule[0]
        XCTAssertEqual(lunedi.dayName, "Lunedì")
        XCTAssertFalse(lunedi.isClosed)
        XCTAssertEqual(lunedi.morningHours, "09:30 - 12:30")
        XCTAssertEqual(lunedi.afternoonHours, "15:00 - 19:30")

        // Domenica
        let domenica = schedule[6]
        XCTAssertEqual(domenica.dayName, "Domenica")
        XCTAssertTrue(domenica.isClosed)
        XCTAssertEqual(domenica.formattedHours, "Chiuso")
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
}
