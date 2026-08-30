import XCTest
@testable import WebSyncroClient

@MainActor
final class InventoryOCRParserTests: XCTestCase {

    func testParseRealDocumentSample() {
        let sampleOCR = """
        EXNOVO
        seconda mano primo amore
        Lista oggetti in carico
        TRE091
        Lista Numero: 2026/009938
        Del: 11/06/2026
        Elenco degli oggetti ricevuti o modificati dal cliente privato in data odierna.
        Codice Descrizione Cat. Qtà Prezzo concordato % Prov. Provvigione mercatino unitaria Rimborso cliente unitario Iva provvigione mercatino Prezzo esposto Data ultimo prezzo
        1.260.214 Libro 2 LI 6 2,70 € 50,00 1,35 € 1,35 € 0,30 € 3,00 € 11/06/2026
        1.260.215 Libro 3-4 LI 14 2,25 € 50,00 1,12 € 1,13 € 0,25 € 2,50 € 11/06/2026
        1.260.216 La ragazza con l'orecchino di perla. Ediz. speciale Chevalier Tracy classici stranieri LI 1 2,70 € 50,00 1,35 € 1,35 € 0,30 € 3,00 € 11/06/2026
        1.260.217 Il viaggio di Buddy LI 1 1,80 € 50,00 0,90 € 0,90 € 0,20 € 2,00 € 11/06/2026
        Totali: 35
        Valore totale della merce concordato 84,15 €
        Valore della merce esposto 93,50 €
        """

        let result = InventoryOCRParser.parse(ocrText: sampleOCR, shopId: "exnovomercatino")

        XCTAssertEqual(result.listNumber, "2026/009938")
        XCTAssertEqual(result.totalAgreedValue, Decimal(string: "84.15"))
        XCTAssertEqual(result.totalExposedValue, Decimal(string: "93.50"))
        XCTAssertEqual(result.items.count, 4)

        // Verifica primo articolo
        let item1 = result.items[0]
        XCTAssertEqual(item1.id, "1260214")
        XCTAssertEqual(item1.rawCode, "1.260.214")
        XCTAssertEqual(item1.quantity, 6)
        XCTAssertEqual(item1.agreedPrice, Decimal(string: "2.70"))
        XCTAssertEqual(item1.clientPayoutInitial, Decimal(string: "1.35"))
        XCTAssertEqual(item1.exposedPriceInitial, Decimal(string: "3.00"))

        // Verifica secondo articolo
        let item2 = result.items[1]
        XCTAssertEqual(item2.id, "1260215")
        XCTAssertEqual(item2.quantity, 14)
    }

    func testLifecycleStagesAndDiscountCalculations() {
        let calendar = Calendar.current
        let today = Date()

        // 1. Articolo caricato 10 giorni fa (Prezzo Pieno, 0-60gg)
        let date10 = calendar.date(byAdding: .day, value: -10, to: today)!
        let itemRecent = InventoryItem(
            id: "1260201",
            loadDate: date10,
            title: "Articolo Recente",
            clientPayoutInitial: Decimal(string: "10.00")!,
            exposedPriceInitial: Decimal(string: "20.00")!
        )

        XCTAssertEqual(itemRecent.daysSinceLoad(relativeTo: today), 10)
        XCTAssertEqual(itemRecent.currentStage(relativeTo: today), .fullPrice)
        XCTAssertEqual(itemRecent.currentExposedPrice(relativeTo: today), Decimal(string: "20.00"))
        XCTAssertEqual(itemRecent.currentClientPayout(relativeTo: today), Decimal(string: "10.00"))
        XCTAssertEqual(itemRecent.daysUntilNextStage(relativeTo: today).days, 50)
        XCTAssertEqual(itemRecent.daysUntilNextStage(relativeTo: today).nextStage, .discounted50)

        // 2. Articolo caricato 70 giorni fa (In Saldo -50%, 61-90gg)
        let date70 = calendar.date(byAdding: .day, value: -70, to: today)!
        let itemDiscounted = InventoryItem(
            id: "1260202",
            loadDate: date70,
            title: "Articolo Scontato",
            clientPayoutInitial: Decimal(string: "10.00")!,
            exposedPriceInitial: Decimal(string: "20.00")!
        )

        XCTAssertEqual(itemDiscounted.daysSinceLoad(relativeTo: today), 70)
        XCTAssertEqual(itemDiscounted.currentStage(relativeTo: today), .discounted50)
        XCTAssertEqual(itemDiscounted.currentExposedPrice(relativeTo: today), Decimal(string: "10.00")) // Sconto 50%
        XCTAssertEqual(itemDiscounted.currentClientPayout(relativeTo: today), Decimal(string: "5.00"))  // Rimborso ridotto al 50%
        XCTAssertEqual(itemDiscounted.daysUntilNextStage(relativeTo: today).days, 20)
        XCTAssertEqual(itemDiscounted.daysUntilNextStage(relativeTo: today).nextStage, .maxRealization)

        // 3. Articolo caricato 100 giorni fa (Oltre 90gg, Maggior Realizzo)
        let date100 = calendar.date(byAdding: .day, value: -100, to: today)!
        let itemExpired = InventoryItem(
            id: "1260203",
            loadDate: date100,
            title: "Articolo Scaduto",
            clientPayoutInitial: Decimal(string: "10.00")!,
            exposedPriceInitial: Decimal(string: "20.00")!
        )

        XCTAssertEqual(itemExpired.daysSinceLoad(relativeTo: today), 100)
        XCTAssertEqual(itemExpired.currentStage(relativeTo: today), .maxRealization)
    }

    func testReconciliationWithLiveSalesReport() {
        let store = InventoryStore(userDefaults: UserDefaults(suiteName: "test_rec_\(UUID().uuidString)")!)

        let item1 = InventoryItem(id: "1260216", title: "La ragazza con orecchino", clientPayoutInitial: Decimal(string: "0.90")!)
        let item2 = InventoryItem(id: "1260228", title: "Luce suono elettricita", clientPayoutInitial: Decimal(string: "0.90")!)
        let item3 = InventoryItem(id: "1260999", title: "Libro Invenduto", clientPayoutInitial: Decimal(string: "5.00")!)

        let batch = InventoryBatch(listNumber: "2026/001", loadDate: Date(), items: [item1, item2, item3])
        store.addBatch(batch)

        let maturedReport = MockWebSyncroService.sampleReport()
        let nonMaturedReport = MockWebSyncroService.sampleNonMaturedReport()

        let status1 = store.saleStatus(for: item1, maturedReport: maturedReport, nonMaturedReport: nonMaturedReport)
        let status2 = store.saleStatus(for: item2, maturedReport: maturedReport, nonMaturedReport: nonMaturedReport)
        let status3 = store.saleStatus(for: item3, maturedReport: maturedReport, nonMaturedReport: nonMaturedReport)

        // Item 1260216 è in nonmaturato.txt -> soldInRecesso
        XCTAssertEqual(status1, .soldInRecesso(date: "24/08/2026", amount: Decimal(string: "0.90")!))

        // Item 1260228 è in maturato.txt -> soldMatured
        XCTAssertEqual(status2, .soldMatured(date: "11/06/2026", amount: Decimal(string: "0.90")!))

        // Item 1260999 non è in nessuno dei due report -> unsoldInShop
        XCTAssertEqual(status3, .unsoldInShop)
    }
}
