import Foundation

/// Modello che rappresenta una singola vendita o articolo maturato
public struct SaleItem: Identifiable, Hashable, Sendable, Codable {
    public let id: String           // Es. "1260224"
    public let date: Date           // Da stringa "dd/MM/yyyy"
    public let dateString: String   // "28/08/2026"
    public let amount: Decimal      // Es. 0.45
    public let title: String        // Es. Titolo libro / descrizione articolo

    public init(
        id: String,
        date: Date,
        dateString: String,
        amount: Decimal,
        title: String
    ) {
        self.id = id
        self.date = date
        self.dateString = dateString
        self.amount = amount
        self.title = title
    }

    /// Ritorna un titolo leggibile o un fallback
    public var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Articolo #\(id)" : trimmed
    }
}

/// Modello complessivo contenente il report maturato calcolato e i metadati
public struct SalesReport: Hashable, Sendable, Codable {
    public let shopId: String
    public let userId: String
    public let syncTimestamp: String
    public let totalEarned: Decimal
    public let itemsCount: Int
    public let items: [SaleItem]
    public let optionalNotice: String?

    public init(
        shopId: String,
        userId: String,
        syncTimestamp: String,
        totalEarned: Decimal,
        itemsCount: Int,
        items: [SaleItem],
        optionalNotice: String? = nil
    ) {
        self.shopId = shopId
        self.userId = userId
        self.syncTimestamp = syncTimestamp
        self.totalEarned = totalEarned
        self.itemsCount = itemsCount
        self.items = items
        self.optionalNotice = optionalNotice
    }

    /// Data formattata dello snapshot se convertibile
    public var formattedSyncDate: String {
        // Il timestamp è del tipo "SM_2026-08-29T19:54:28" oppure "2026-08-29T19:54:28"
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

