import Foundation

/// Stato del ciclo di vita contrattuale dell'oggetto in carico (in base ai giorni trascorsi)
public enum ExposureStage: String, Codable, Sendable {
    case fullPrice = "Prezzo Pieno (100%)"
    case discounted50 = "In Saldo (-50%)"
    case maxRealization = "Maggior Realizzo / Scaduto"
}

/// Stato di vendita dettagliato con tracciamento delle quantità e vendite parziali
public enum InventorySaleStatus: Equatable, Sendable {
    case unsoldInShop(quantity: Int)
    case partiallySold(soldMaturedQty: Int, soldInRecessoQty: Int, remainingQty: Int, maturedAmount: Decimal, inRecessoAmount: Decimal)
    case fullySold(maturedQty: Int, inRecessoQty: Int, totalAmount: Decimal)

    public var isFullySold: Bool {
        if case .fullySold = self { return true }
        return false
    }

    public var isPartiallySold: Bool {
        if case .partiallySold = self { return true }
        return false
    }

    public var hasRemainingInShop: Bool {
        switch self {
        case .unsoldInShop(let qty):
            return qty > 0
        case .partiallySold(_, _, let remaining, _, _):
            return remaining > 0
        case .fullySold:
            return false
        }
    }

    public var remainingInShopCount: Int {
        switch self {
        case .unsoldInShop(let qty):
            return qty
        case .partiallySold(_, _, let remaining, _, _):
            return remaining
        case .fullySold:
            return 0
        }
    }
}

/// Modello di un singolo articolo presente nella lista oggetti in carico
public struct InventoryItem: Identifiable, Codable, Sendable, Equatable {
    public let id: String                       // Codice normalizzato (es. "1260214")
    public var rawCode: String                  // Codice formattato originale (es. "1.260.214")
    public var listNumber: String               // Numero lista di carico (es. "2026/009938")
    public var loadDate: Date                   // Data di presa in carico (es. 11/06/2026)
    public var title: String                    // Descrizione/Titolo dell'oggetto
    public var category: String                 // Categoria merceologica (es. "LI" per Libri)
    public var quantity: Int                    // Quantità caricata iniziale
    public var agreedPrice: Decimal             // Prezzo unitario concordato iniziale
    public var clientPayoutInitial: Decimal     // Rimborso netto unitario concordato iniziale (es. 1,35 €)
    public var exposedPriceInitial: Decimal     // Prezzo unitario esposto al pubblico iniziale (es. 3,00 €)
    public var shopId: String                   // Negozio di appartenenza (es. "exnovomercatino")
    public var userCardCode: String             // Codice tessera utente proprietario (es. "CLI001")

    public init(
        id: String,
        rawCode: String? = nil,
        listNumber: String = "",
        loadDate: Date = Date(),
        title: String,
        category: String = "LI",
        quantity: Int = 1,
        agreedPrice: Decimal = 0,
        clientPayoutInitial: Decimal = 0,
        exposedPriceInitial: Decimal = 0,
        shopId: String = "exnovomercatino",
        userCardCode: String = ""
    ) {
        self.id = id.replacingOccurrences(of: ".", with: "").trimmingCharacters(in: .whitespaces)
        self.rawCode = rawCode ?? id
        self.listNumber = listNumber
        self.loadDate = loadDate
        self.title = title
        self.category = category
        self.quantity = max(1, quantity)
        self.agreedPrice = agreedPrice
        self.clientPayoutInitial = clientPayoutInitial
        self.exposedPriceInitial = exposedPriceInitial
        self.shopId = shopId
        self.userCardCode = userCardCode
    }

    // MARK: - Calcolo Svalutazione Temporale (Clausole Mandato di Vendita)

    public func daysSinceLoad(relativeTo date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let startOfLoad = calendar.startOfDay(for: loadDate)
        let startOfTarget = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: startOfLoad, to: startOfTarget)
        return max(0, components.day ?? 0)
    }

    public func currentStage(relativeTo date: Date = Date()) -> ExposureStage {
        let days = daysSinceLoad(relativeTo: date)
        if days <= 60 {
            return .fullPrice
        } else if days <= 90 {
            return .discounted50
        } else {
            return .maxRealization
        }
    }

    public func currentExposedPrice(relativeTo date: Date = Date()) -> Decimal {
        let stage = currentStage(relativeTo: date)
        switch stage {
        case .fullPrice:
            return exposedPriceInitial
        case .discounted50, .maxRealization:
            var result = Decimal()
            var raw = exposedPriceInitial * Decimal(0.5)
            NSDecimalRound(&result, &raw, 2, .plain)
            return result
        }
    }

    public func currentClientPayout(relativeTo date: Date = Date()) -> Decimal {
        let stage = currentStage(relativeTo: date)
        switch stage {
        case .fullPrice:
            return clientPayoutInitial
        case .discounted50, .maxRealization:
            var result = Decimal()
            var raw = clientPayoutInitial * Decimal(0.5)
            NSDecimalRound(&result, &raw, 2, .plain)
            return result
        }
    }

    public func totalCurrentClientPayout(for remainingQty: Int, relativeTo date: Date = Date()) -> Decimal {
        return currentClientPayout(relativeTo: date) * Decimal(remainingQty)
    }

    public func daysUntilNextStage(relativeTo date: Date = Date()) -> (days: Int, nextStage: ExposureStage?) {
        let days = daysSinceLoad(relativeTo: date)
        if days <= 60 {
            return (60 - days, .discounted50)
        } else if days <= 90 {
            return (90 - days, .maxRealization)
        } else {
            return (0, nil)
        }
    }

    public func lifecycleProgress(relativeTo date: Date = Date()) -> Double {
        let days = Double(daysSinceLoad(relativeTo: date))
        return min(1.0, max(0.0, days / 90.0))
    }

    public var formattedLoadDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: loadDate)
    }
}

/// Modello di un intero documento/lotto di carico
public struct InventoryBatch: Identifiable, Codable, Sendable {
    public let id: UUID
    public var listNumber: String
    public var loadDate: Date
    public var shopId: String
    public var userCardCode: String
    public var totalPieces: Int
    public var totalAgreedValue: Decimal
    public var totalExposedValue: Decimal
    public var items: [InventoryItem]

    public init(
        id: UUID = UUID(),
        listNumber: String,
        loadDate: Date,
        shopId: String = "exnovomercatino",
        userCardCode: String = "",
        totalPieces: Int = 0,
        totalAgreedValue: Decimal = 0,
        totalExposedValue: Decimal = 0,
        items: [InventoryItem] = []
    ) {
        self.id = id
        self.listNumber = listNumber
        self.loadDate = loadDate
        self.shopId = shopId
        self.userCardCode = userCardCode
        self.totalPieces = totalPieces > 0 ? totalPieces : items.reduce(0) { $0 + $1.quantity }
        self.totalAgreedValue = totalAgreedValue > 0 ? totalAgreedValue : items.reduce(Decimal.zero) { $0 + ($1.agreedPrice * Decimal($1.quantity)) }
        self.totalExposedValue = totalExposedValue > 0 ? totalExposedValue : items.reduce(Decimal.zero) { $0 + ($1.exposedPriceInitial * Decimal($1.quantity)) }
        self.items = items
    }
}
