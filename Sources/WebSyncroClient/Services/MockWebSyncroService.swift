import Foundation

public final class MockWebSyncroService: WebSyncroServiceProtocol, @unchecked Sendable {
    public var shouldFail: Bool = false
    public var mockError: WebSyncroError?
    public var delayNanoseconds: UInt64 = 600_000_000 // 0.6s

    public init(shouldFail: Bool = false, mockError: WebSyncroError? = nil) {
        self.shouldFail = shouldFail
        self.mockError = mockError
    }

    public func fetchSalesReport(
        shopId: String,
        userId: String,
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

        return Self.sampleReport(shopId: shopId, userId: userId, syncTimestamp: snapshot)
    }

    public func fetchAvailableSnapshots(shopId: String) async throws -> [String] {
        try await Task.sleep(nanoseconds: 200_000_000)
        if shouldFail {
            throw mockError ?? WebSyncroError.shopNotFound(shopId: shopId)
        }
        return [
            "SM_2026-08-29T19:54:28",
            "SM_2026-08-28T18:30:10",
            "SM_2026-08-27T19:15:00",
            "SM_2026-08-26T20:01:45",
            "SM_2026-08-25T17:42:12"
        ]
    }

    /// Report di prova realistico per simulazione e preview SwiftUI
    public static func sampleReport(
        shopId: String = "1042",
        userId: String = "852",
        syncTimestamp: String = "SM_2026-08-29T19:54:28"
    ) -> SalesReport {
        let items: [SaleItem] = [
            SaleItem(
                id: "1260224",
                date: Date.fromSaleDateString("28/08/2026") ?? Date(),
                dateString: "28/08/2026",
                amount: Decimal(string: "0.45")!,
                title: "Sul Grappa dopo la vittoria Malaguti Paolo letteratura italiana"
            ),
            SaleItem(
                id: "1260225",
                date: Date.fromSaleDateString("28/08/2026") ?? Date(),
                dateString: "28/08/2026",
                amount: Decimal(string: "14.50")!,
                title: "Giacca a vento The North Face taglia M azzurra"
            ),
            SaleItem(
                id: "1259981",
                date: Date.fromSaleDateString("26/08/2026") ?? Date(),
                dateString: "26/08/2026",
                amount: Decimal(string: "28.00")!,
                title: "Lampada da tavolo vintage stile Bauhaus ottone e vetro"
            ),
            SaleItem(
                id: "1259830",
                date: Date.fromSaleDateString("25/08/2026") ?? Date(),
                dateString: "25/08/2026",
                amount: Decimal(string: "6.00")!,
                title: "Vinile LP Pink Floyd - The Dark Side of the Moon (Ristampa)"
            ),
            SaleItem(
                id: "1259410",
                date: Date.fromSaleDateString("22/08/2026") ?? Date(),
                dateString: "22/08/2026",
                amount: Decimal(string: "45.00")!,
                title: "Set 6 tazzine da caffè porcellana Richard Ginori anni '70"
            ),
            SaleItem(
                id: "1258902",
                date: Date.fromSaleDateString("18/08/2026") ?? Date(),
                dateString: "18/08/2026",
                amount: Decimal(string: "3.50")!,
                title: "Fumetto Dylan Dog prima ristampa n. 12"
            ),
            SaleItem(
                id: "1258319",
                date: Date.fromSaleDateString("15/08/2026") ?? Date(),
                dateString: "15/08/2026",
                amount: Decimal(string: "12.00")!,
                title: "Macchina fotografica analogica compatta Olympus Trip 35"
            ),
            SaleItem(
                id: "1257800",
                date: Date.fromSaleDateString("10/08/2026") ?? Date(),
                dateString: "10/08/2026",
                amount: Decimal(string: "8.50")!,
                title: "Cintura in cuoio artigianale marrone"
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
            optionalNotice: "I pagamenti maturati sono ritirabili in cassa dal martedì al sabato negli orari di apertura del negozio. Ricordati di portare un documento d'identità."
        )
    }
}

