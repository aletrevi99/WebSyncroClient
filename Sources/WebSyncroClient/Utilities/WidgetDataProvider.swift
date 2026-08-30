import Foundation

/// Snapshot di dati per i widget di iOS
public struct WebSyncroWidgetSnapshot: Codable, Sendable {
    public let shopName: String
    public let shopId: String
    public let cardCode: String
    public let maturedAmount: Decimal
    public let inRecessoAmount: Decimal
    public let inShopEstimatedAmount: Decimal
    public let inShopPiecesCount: Int
    public let soldPiecesCount: Int
    public let recentSales: [WidgetSaleItem]
    public let expiringItems: [WidgetExpiringItem]
    public let lastUpdated: Date

    public init(
        shopName: String = "EX NOVO Mercatino",
        shopId: String = "exnovomercatino",
        cardCode: String = "TRE091",
        maturedAmount: Decimal = 18.45,
        inRecessoAmount: Decimal = 3.50,
        inShopEstimatedAmount: Decimal = 12.15,
        inShopPiecesCount: Int = 20,
        soldPiecesCount: Int = 15,
        recentSales: [WidgetSaleItem] = WidgetSaleItem.samples,
        expiringItems: [WidgetExpiringItem] = WidgetExpiringItem.samples,
        lastUpdated: Date = Date()
    ) {
        self.shopName = shopName
        self.shopId = shopId
        self.cardCode = cardCode
        self.maturedAmount = maturedAmount
        self.inRecessoAmount = inRecessoAmount
        self.inShopEstimatedAmount = inShopEstimatedAmount
        self.inShopPiecesCount = inShopPiecesCount
        self.soldPiecesCount = soldPiecesCount
        self.recentSales = recentSales
        self.expiringItems = expiringItems
        self.lastUpdated = lastUpdated
    }
}

public struct WidgetSaleItem: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let amount: Decimal
    public let dateFormatted: String
    public let isMatured: Bool

    public init(id: String, title: String, amount: Decimal, dateFormatted: String, isMatured: Bool) {
        self.id = id
        self.title = title
        self.amount = amount
        self.dateFormatted = dateFormatted
        self.isMatured = isMatured
    }

    public static let samples: [WidgetSaleItem] = [
        WidgetSaleItem(id: "1260218", title: "Happy Feet la storia del film", amount: 0.45, dateFormatted: "Oggi", isMatured: true),
        WidgetSaleItem(id: "1260216", title: "La ragazza con l'orecchino di perla", amount: 0.68, dateFormatted: "Ieri", isMatured: false),
        WidgetSaleItem(id: "1260214", title: "Libro 2 (Volume 1)", amount: 0.68, dateFormatted: "28 Ago", isMatured: true),
        WidgetSaleItem(id: "1260215", title: "Libro 3-4 (4 copie)", amount: 2.28, dateFormatted: "26 Ago", isMatured: true)
    ]
}

public struct WidgetExpiringItem: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let daysRemaining: Int
    public let nextStage: String
    public let currentPrice: Decimal

    public init(id: String, title: String, daysRemaining: Int, nextStage: String, currentPrice: Decimal) {
        self.id = id
        self.title = title
        self.daysRemaining = daysRemaining
        self.nextStage = nextStage
        self.currentPrice = currentPrice
    }

    public static let samples: [WidgetExpiringItem] = [
        WidgetExpiringItem(id: "1260214", title: "Libro 2", daysRemaining: 10, nextStage: "Maggior Realizzo", currentPrice: 1.50),
        WidgetExpiringItem(id: "1260215", title: "Libro 3-4", daysRemaining: 10, nextStage: "Maggior Realizzo", currentPrice: 1.25),
        WidgetExpiringItem(id: "1260217", title: "Il viaggio di Buddy", daysRemaining: 10, nextStage: "Maggior Realizzo", currentPrice: 1.00)
    ]
}

/// Utility per sincronizzare i dati con i Widget di iOS
public enum WidgetDataProvider {
    private static let userDefaultsKey = "it.websyncro.client.widget_snapshot"
    private static let appGroupIdentifier = "group.it.websyncro.client"

    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? UserDefaults.standard
    }

    public static func saveSnapshot(
        shopName: String,
        shopId: String,
        cardCode: String,
        maturedAmount: Decimal,
        inRecessoAmount: Decimal,
        inShopEstimatedAmount: Decimal,
        inShopPiecesCount: Int,
        soldPiecesCount: Int,
        recentSales: [WidgetSaleItem],
        expiringItems: [WidgetExpiringItem]
    ) {
        let snapshot = WebSyncroWidgetSnapshot(
            shopName: shopName,
            shopId: shopId,
            cardCode: cardCode,
            maturedAmount: maturedAmount,
            inRecessoAmount: inRecessoAmount,
            inShopEstimatedAmount: inShopEstimatedAmount,
            inShopPiecesCount: inShopPiecesCount,
            soldPiecesCount: soldPiecesCount,
            recentSales: recentSales,
            expiringItems: expiringItems,
            lastUpdated: Date()
        )

        if let data = try? JSONEncoder().encode(snapshot) {
            sharedDefaults.setValue(data, forKey: userDefaultsKey)
            UserDefaults.standard.setValue(data, forKey: userDefaultsKey)
        }
    }

    public static func loadSnapshot() -> WebSyncroWidgetSnapshot {
        if let data = sharedDefaults.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(WebSyncroWidgetSnapshot.self, from: data) {
            return decoded
        }
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(WebSyncroWidgetSnapshot.self, from: data) {
            return decoded
        }
        return WebSyncroWidgetSnapshot()
    }
}

