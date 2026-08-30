import Foundation

public final class MockWebSyncroService: WebSyncroServiceProtocol, @unchecked Sendable {
    public var shouldFail: Bool = false
    public var mockError: WebSyncroError?
    public var delayNanoseconds: UInt64 = 500_000_000

    public init(shouldFail: Bool = false, mockError: WebSyncroError? = nil) {
        self.shouldFail = shouldFail
        self.mockError = mockError
    }

    public func fetchSalesReport(
        shopId: String,
        userId: String,
        isNonMatured: Bool = false,
        onProgress: (@Sendable (SyncStatus) -> Void)? = nil
    ) async throws -> SalesReport {
        onProgress?(.scrapingDirectory(shopId: shopId))
        try await Task.sleep(nanoseconds: delayNanoseconds / 2)

        if shouldFail {
            throw mockError ?? WebSyncroError.networkError("Connessione simulata fallita")
        }

        let snapshot = "SM_2026-08-29T19:54:28"
        onProgress?(.downloadingReport(shopId: shopId, snapshot: snapshot, userId: userId))
        try await Task.sleep(nanoseconds: delayNanoseconds / 2)

        return isNonMatured
            ? Self.sampleNonMaturedReport(shopId: shopId, userId: userId, syncTimestamp: snapshot)
            : Self.sampleReport(shopId: shopId, userId: userId, syncTimestamp: snapshot)
    }

    public func fetchBothReports(
        shopId: String,
        userId: String,
        onProgress: (@Sendable (SyncStatus) -> Void)? = nil
    ) async throws -> (matured: SalesReport, nonMatured: SalesReport) {
        onProgress?(.scrapingDirectory(shopId: shopId))
        try await Task.sleep(nanoseconds: delayNanoseconds / 2)

        if shouldFail {
            throw mockError ?? WebSyncroError.networkError("Connessione simulata fallita")
        }

        let snapshot = "SM_2026-08-29T19:54:28"
        onProgress?(.downloadingReport(shopId: shopId, snapshot: snapshot, userId: userId))
        try await Task.sleep(nanoseconds: delayNanoseconds / 2)

        let matured = Self.sampleReport(shopId: shopId, userId: userId, syncTimestamp: snapshot)
        let nonMatured = Self.sampleNonMaturedReport(shopId: shopId, userId: userId, syncTimestamp: snapshot)

        return (matured, nonMatured)
    }

    public func fetchShopDirectory() async throws -> [ShopDetails] {
        try await Task.sleep(nanoseconds: 50_000_000)
        return [
            ShopDetails(
                name: "Armadio dell'Usato",
                slug: "armadiodellusato",
                address: "Corso Milano 122A",
                cityZip: "37138 Verona (VR)",
                phone: "045 8031777",
                email: "info@leotron.com"
            ),
            ShopDetails(
                name: "Mercatino Store",
                slug: "mercatinostore",
                address: "Via G. Mazzini 91",
                cityZip: "36027 Rosà (VI)",
                phone: "0424 582956",
                email: "info@mercatinostore.com"
            ),
            ShopDetails(
                name: "EX Novo",
                slug: "exnovomercatino",
                address: "Via Vicenza 23",
                cityZip: "31050 Vedelago (TV)",
                phone: "042 3700120",
                email: "info@exnovomercatino.it"
            )
        ]
    }

    public func fetchShopDetails(shopId: String) async throws -> ShopDetails {
        try await Task.sleep(nanoseconds: delayNanoseconds / 2)
        if shouldFail {
            throw mockError ?? WebSyncroError.shopNotFound(shopId: shopId)
        }
        let sampleRaw = "0-09:30-12:30-15:00-19:30|0-09:30-12:30-15:00-19:30|0-09:30-12:30-15:00-19:30|0-09:30-12:30-15:00-19:30|0-09:30-12:30-15:00-19:30|0-09:30-12:30-15:00-19:30|1-00:00-00:00-00:00-00:00"
        let schedule = SalesParser.parseSchedule(content: sampleRaw)
        
        return ShopDetails(
            name: "EX Novo",
            slug: shopId,
            address: "Via Vicenza 23",
            cityZip: "31050 Vedelago (TV)",
            phone: "042 3700120",
            email: "info@exnovomercatino.it",
            schedule: schedule
        )
    }

    public func fetchNotifications(shopId: String) async throws -> [ShopNotification] {
        try await Task.sleep(nanoseconds: delayNanoseconds / 2)
        if shouldFail {
            throw mockError ?? WebSyncroError.shopNotFound(shopId: shopId)
        }
        return [
            ShopNotification(
                id: "Notifica_2026-08-17T08:58:16.txt",
                dateString: "17/08/2026 08:58",
                sender: "EX Novo",
                title: "OGGI SI RIPARTE!",
                message: "Dopo la pausa di Ferragosto, oggi EX NOVO riapre! Siamo operativi con i soliti orari",
                rawFilename: "Notifica_2026-08-17T08:58:16.txt"
            ),
            ShopNotification(
                id: "Notifica_2026-08-13T08:57:26.txt",
                dateString: "13/08/2026 08:57",
                sender: "EX Novo",
                title: "Per quest'anno non cambiare...",
                message: "EX NOVO CHIUDE IL 15 E 16 AGOSTO\nRiapre regolarmente il 17 agosto!\nBUON FERRAGOSTO A TUTTI!",
                rawFilename: "Notifica_2026-08-13T08:57:26.txt"
            ),
            ShopNotification(
                id: "Notifica_2026-07-31T18:05:49.txt",
                dateString: "31/07/2026 18:05",
                sender: "EX Novo",
                title: "PARTE LA STAGIONE AUTUNNALE!",
                message: "Da lunedi 3 agosto parte il ritiro della stagione autunnale! Porta abbigliamento, oggettistica e tutto ciò che non usi più.",
                rawFilename: "Notifica_2026-07-31T18:05:49.txt"
            )
        ]
    }

    public func fetchAvailableSnapshots(shopId: String) async throws -> [String] {
        try await Task.sleep(nanoseconds: 100_000_000)
        if shouldFail {
            throw mockError ?? WebSyncroError.shopNotFound(shopId: shopId)
        }
        return [
            "SM_2026-08-29T19:54:28",
            "SM_2026-08-28T18:30:10",
            "SM_2026-08-27T19:15:00"
        ]
    }

    public static func sampleReport(
        shopId: String = "exnovomercatino",
        userId: String = "TRE091_1762",
        syncTimestamp: String = "SM_2026-08-29T19:54:28"
    ) -> SalesReport {
        let items: [SaleItem] = [
            SaleItem(
                id: "1260228",
                date: Date.fromSaleDateString("11/06/2026") ?? Date(),
                dateString: "11/06/2026",
                amount: Decimal(string: "0.90")!,
                title: "Luce, suono, elettricità. Ediz. illustrata Leonardi Antonio classici ragazzi"
            ),
            SaleItem(
                id: "1260218",
                date: Date.fromSaleDateString("13/06/2026") ?? Date(),
                dateString: "13/06/2026",
                amount: Decimal(string: "0.90")!,
                title: "Happy Feet la storia con le immagini del film ragazzi 7-10 anni"
            ),
            SaleItem(
                id: "1260214",
                date: Date.fromSaleDateString("21/06/2026") ?? Date(),
                dateString: "21/06/2026",
                amount: Decimal(string: "1.35")!,
                title: "Libro narrativa contemporanea"
            ),
            SaleItem(
                id: "1260215",
                date: Date.fromSaleDateString("21/06/2026") ?? Date(),
                dateString: "21/06/2026",
                amount: Decimal(string: "2.25")!,
                title: "Libro illustrato d'arte"
            ),
            SaleItem(
                id: "1260227",
                date: Date.fromSaleDateString("22/06/2026") ?? Date(),
                dateString: "22/06/2026",
                amount: Decimal(string: "1.35")!,
                title: "Leggende e racconti popolari del Trentino Alto Adige Dal Lago Veneri Bruna M."
            ),
            SaleItem(
                id: "1260225",
                date: Date.fromSaleDateString("20/07/2026") ?? Date(),
                dateString: "20/07/2026",
                amount: Decimal(string: "1.13")!,
                title: "Il ragazzo di Varsavia Borowiec Andrew; Smith C. storia"
            ),
            SaleItem(
                id: "1260226",
                date: Date.fromSaleDateString("01/08/2026") ?? Date(),
                dateString: "01/08/2026",
                amount: Decimal(string: "1.57")!,
                title: "Una meravigliosa vita da cani Sims Graeme animali domestici"
            ),
            SaleItem(
                id: "1260220",
                date: Date.fromSaleDateString("13/08/2026") ?? Date(),
                dateString: "13/08/2026",
                amount: Decimal(string: "0.68")!,
                title: "Il passaggio Grossi Pietro letteratura italiana"
            )
        ]

        let total = items.reduce(Decimal(0)) { $0 + $1.amount }

        return SalesReport(
            shopId: shopId,
            userId: userId,
            syncTimestamp: syncTimestamp,
            totalEarned: total,
            itemsCount: items.count,
            items: items,
            optionalNotice: "I pagamenti maturati sono ritirabili in cassa dal martedì al sabato negli orari di apertura del negozio.",
            isNonMatured: false
        )
    }

    public static func sampleNonMaturedReport(
        shopId: String = "exnovomercatino",
        userId: String = "TRE091_1762",
        syncTimestamp: String = "SM_2026-08-29T19:54:28"
    ) -> SalesReport {
        let items: [SaleItem] = [
            SaleItem(
                id: "1260216",
                date: Date.fromSaleDateString("24/08/2026") ?? Date(),
                dateString: "24/08/2026",
                amount: Decimal(string: "0.90")!,
                title: "La ragazza con l'orecchino di perla. Ediz. speciale Chevalier Tracy",
                isNonMatured: true
            ),
            SaleItem(
                id: "1260224",
                date: Date.fromSaleDateString("28/08/2026") ?? Date(),
                dateString: "28/08/2026",
                amount: Decimal(string: "0.45")!,
                title: "Doppio gioco Brambati Pietro letteratura italiana",
                isNonMatured: true
            ),
            SaleItem(
                id: "1260229",
                date: Date.fromSaleDateString("28/08/2026") ?? Date(),
                dateString: "28/08/2026",
                amount: Decimal(string: "0.90")!,
                title: "Sul Grappa dopo la vittoria Malaguti Paolo letteratura italiana",
                isNonMatured: true
            )
        ]

        let total = items.reduce(Decimal(0)) { $0 + $1.amount }

        return SalesReport(
            shopId: shopId,
            userId: userId,
            syncTimestamp: syncTimestamp,
            totalEarned: total,
            itemsCount: items.count,
            items: items,
            optionalNotice: "Articoli venduti ma in periodo di recesso (non ancora rimborsabili)",
            isNonMatured: true
        )
    }
}
