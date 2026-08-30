import Foundation

/// Modello che rappresenta una singola vendita o articolo
public struct SaleItem: Identifiable, Hashable, Sendable, Codable {
    public let id: String           // Es. "1260224"
    public let date: Date           // Da stringa "dd/MM/yyyy"
    public let dateString: String   // "28/08/2026"
    public let amount: Decimal      // Es. 0.45
    public let title: String        // Es. Titolo libro / descrizione articolo
    public let isNonMatured: Bool   // True se in periodo di recesso (non maturato)

    public init(
        id: String,
        date: Date,
        dateString: String,
        amount: Decimal,
        title: String,
        isNonMatured: Bool = false
    ) {
        self.id = id
        self.date = date
        self.dateString = dateString
        self.amount = amount
        self.title = title
        self.isNonMatured = isNonMatured
    }

    /// Ritorna un titolo leggibile o un fallback
    public var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Articolo #\(id)" : trimmed
    }
}

/// Modello complessivo contenente il report maturato/non maturato calcolato e i metadati
public struct SalesReport: Hashable, Sendable, Codable {
    public let shopId: String
    public let userId: String
    public let syncTimestamp: String
    public let totalEarned: Decimal
    public let itemsCount: Int
    public let items: [SaleItem]
    public let optionalNotice: String?
    public let isNonMatured: Bool

    public init(
        shopId: String,
        userId: String,
        syncTimestamp: String,
        totalEarned: Decimal,
        itemsCount: Int,
        items: [SaleItem],
        optionalNotice: String? = nil,
        isNonMatured: Bool = false
    ) {
        self.shopId = shopId
        self.userId = userId
        self.syncTimestamp = syncTimestamp
        self.totalEarned = totalEarned
        self.itemsCount = itemsCount
        self.items = items
        self.optionalNotice = optionalNotice
        self.isNonMatured = isNonMatured
    }

    /// Data formattata dello snapshot se convertibile
    public var formattedSyncDate: String {
        let raw = syncTimestamp.replacingOccurrences(of: "SM_", with: "")
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        if let date = formatter.date(from: raw) {
            let displayFormatter = DateFormatter()
            displayFormatter.locale = Locale(identifier: "it_IT")
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return syncTimestamp
    }
}
