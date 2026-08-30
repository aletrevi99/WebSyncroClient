import Foundation

/// Fase del ciclo di vita dell'oggetto in base al Mandato di Vendita (Clausole 4 e 5)
public enum ExposureStage: String, Codable, CaseIterable, Sendable {
    case fullPrice = "Prezzo Pieno"            // Giorni 0 - 60
    case discounted50 = "In Saldo (-50%)"       // Giorni 61 - 90
    case maxRealization = "Maggior Realizzo"    // Oltre i 90 giorni

    public var badgeColorName: String {
        switch self {
        case .fullPrice: return "green"
        case .discounted50: return "orange"
        case .maxRealization: return "red"
        }
    }
}

/// Stato di riconciliazione dell'oggetto con le vendite online
public enum InventorySaleStatus: Equatable, Sendable {
    case unsoldInShop                           // Ancora presente fisicamente in negozio
    case soldInRecesso(date: String, amount: Decimal)   // Venduto, in periodo di recesso (15 gg)
    case soldMatured(date: String, amount: Decimal)     // Venduto e maturato (disponibile per il ritiro)

    public var title: String {
        switch self {
        case .unsoldInShop: return "In Esposizione"
        case .soldInRecesso: return "Venduto (In Recesso)"
        case .soldMatured: return "Venduto (Maturato)"
        }
    }

    public var isSold: Bool {
        switch self {
        case .unsoldInShop: return false
        case .soldInRecesso, .soldMatured: return true
        }
    }
}

/// Singolo articolo affidato in conto vendita
public struct InventoryItem: Identifiable, Codable, Hashable, Sendable {
    public let id: String                    // ID normalizzato (es. "1260214")
    public let rawCode: String               // Codice con formattazione originale (es. "1.260.214")
    public let batchId: UUID                 // Riferimento alla lista di carico
    public let listNumber: String            // Es. "2026/009938"
    public let loadDate: Date                // Data di presa in carico (es. 11/06/2026)
    public var title: String                 // Descrizione (es. "Libro 2")
    public var category: String              // Es. "LI"
    public var quantity: Int                 // Quantità affidata
    public var agreedPrice: Decimal          // Prezzo concordato per il lotto
    public var clientPayoutInitial: Decimal  // Rimborso cliente unitario concordato
    public var exposedPriceInitial: Decimal  // Prezzo esposto al pubblico iniziale
    public var shopId: String                // Es. "exnovomercatino"
    public var notes: String?

    public init(
        id: String,
        rawCode: String? = nil,
        batchId: UUID = UUID(),
        listNumber: String = "",
        loadDate: Date = Date(),
        title: String,
        category: String = "LI",
        quantity: Int = 1,
        agreedPrice: Decimal = 0,
        clientPayoutInitial: Decimal = 0,
        exposedPriceInitial: Decimal = 0,
        shopId: String = "exnovomercatino",
        notes: String? = nil
    ) {
        self.id = id.replacingOccurrences(of: ".", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        self.rawCode = rawCode ?? id
        self.batchId = batchId
        self.listNumber = listNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        self.loadDate = loadDate
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.category = category.trimmingCharacters(in: .whitespacesAndNewlines)
        self.quantity = max(1, quantity)
        self.agreedPrice = agreedPrice
        self.clientPayoutInitial = clientPayoutInitial
        self.exposedPriceInitial = exposedPriceInitial
        self.shopId = shopId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.notes = notes
    }

    // MARK: - Calcolo Ciclo di Vita & Sconti (Clausole Mandato di Vendita)

    /// Numero di giorni trascorsi dalla data di carico
    public func daysSinceLoad(relativeTo referenceDate: Date = Date()) -> Int {
        let calendar = Calendar.current
        let startOfLoad = calendar.startOfDay(for: loadDate)
        let startOfRef = calendar.startOfDay(for: referenceDate)
        let components = calendar.dateComponents([.day], from: startOfLoad, to: startOfRef)
        return max(0, components.day ?? 0)
    }

    /// Fase attuale di esposizione in base ai giorni trascorsi
    public func currentStage(relativeTo referenceDate: Date = Date()) -> ExposureStage {
        let days = daysSinceLoad(relativeTo: referenceDate)
        if days <= 60 {
            return .fullPrice
        } else if days <= 90 {
            return .discounted50
        } else {
            return .maxRealization
        }
    }

    /// Percentuale di avanzamento nei 90 giorni totali del mandato (0.0 ... 1.0)
    public func lifecycleProgress(relativeTo referenceDate: Date = Date()) -> Double {
        let days = Double(daysSinceLoad(relativeTo: referenceDate))
        return min(1.0, max(0.0, days / 90.0))
    }

    /// Giorni rimanenti prima del prossimo cambio stato (sconto 50% o maggior realizzo)
    public func daysUntilNextStage(relativeTo referenceDate: Date = Date()) -> (days: Int, nextStage: ExposureStage?) {
        let days = daysSinceLoad(relativeTo: referenceDate)
        if days <= 60 {
            return (60 - days, .discounted50)
        } else if days <= 90 {
            return (90 - days, .maxRealization)
        } else {
            return (0, nil)
        }
    }

    /// Prezzo di vendita al pubblico attualmente applicabile
    public func currentExposedPrice(relativeTo referenceDate: Date = Date()) -> Decimal {
        switch currentStage(relativeTo: referenceDate) {
        case .fullPrice:
            return exposedPriceInitial
        case .discounted50:
            return exposedPriceInitial * Decimal(0.5)
        case .maxRealization:
            // Al maggior realizzo, valore simbolico o base concordata ridotta
            return exposedPriceInitial * Decimal(0.5)
        }
    }

    /// Rimborso netto stimato spettante al cliente per pezzo in base allo stato attuale
    public func currentClientPayout(relativeTo referenceDate: Date = Date()) -> Decimal {
        switch currentStage(relativeTo: referenceDate) {
        case .fullPrice:
            return clientPayoutInitial
        case .discounted50:
            return clientPayoutInitial * Decimal(0.5)
        case .maxRealization:
            return clientPayoutInitial * Decimal(0.5)
        }
    }

    /// Data formattata di carico
    public var formattedLoadDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateStyle = .medium
        return formatter.string(from: loadDate)
    }
}

/// Documento / Lista di carico complessiva
public struct InventoryBatch: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var listNumber: String            // Es. "2026/009938"
    public var loadDate: Date                // Data emissione
    public var shopId: String                // Negozio
    public var totalPieces: Int
    public var totalAgreedValue: Decimal
    public var totalExposedValue: Decimal
    public var scanDate: Date
    public var items: [InventoryItem]

    public init(
        id: UUID = UUID(),
        listNumber: String,
        loadDate: Date,
        shopId: String = "exnovomercatino",
        totalPieces: Int = 0,
        totalAgreedValue: Decimal = 0,
        totalExposedValue: Decimal = 0,
        scanDate: Date = Date(),
        items: [InventoryItem] = []
    ) {
        self.id = id
        self.listNumber = listNumber
        self.loadDate = loadDate
        self.shopId = shopId
        self.totalPieces = totalPieces > 0 ? totalPieces : items.reduce(0) { $0 + $1.quantity }
        self.totalAgreedValue = totalAgreedValue > 0 ? totalAgreedValue : items.reduce(Decimal.zero) { $0 + $1.agreedPrice }
        self.totalExposedValue = totalExposedValue > 0 ? totalExposedValue : items.reduce(Decimal.zero) { $0 + ($1.exposedPriceInitial * Decimal($1.quantity)) }
        self.scanDate = scanDate
        self.items = items
    }
}

