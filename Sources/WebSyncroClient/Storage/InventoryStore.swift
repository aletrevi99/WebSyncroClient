import Foundation
import Combine

/// Report dettagliato dell'analisi di deduplicazione di una nuova scansione rispetto al DB locale
public struct DeduplicationReport: Sendable {
    public let newItems: [InventoryItem]
    public let duplicateItems: [InventoryItem]
    public let updatedItems: [InventoryItem]

    public var hasDuplicates: Bool {
        !duplicateItems.isEmpty || !updatedItems.isEmpty
    }

    public var summaryText: String {
        var parts: [String] = []
        if !newItems.isEmpty {
            parts.append("\(newItems.count) nuovi")
        }
        if !duplicateItems.isEmpty {
            parts.append("\(duplicateItems.count) già presenti")
        }
        if !updatedItems.isEmpty {
            parts.append("\(updatedItems.count) aggiornati")
        }
        return parts.joined(separator: " • ")
    }
}

/// Gestore del database locale dell'inventario, isolato per utente e negozio, con motore di deduplicazione e riconciliazione
@MainActor
public final class InventoryStore: ObservableObject {
    public static let shared = InventoryStore()

    private let userDefaults: UserDefaults
    private let storageKey = "it.websyncro.client.inventory_batches_v2"

    @Published public private(set) var batches: [InventoryBatch] = []

    public var allItems: [InventoryItem] {
        batches.flatMap { $0.items }
    }

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadBatches()
    }

    public func loadBatches() {
        if let data = userDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([InventoryBatch].self, from: data) {
            self.batches = decoded
        } else {
            // Retrocompatibilità
            if let legacyData = userDefaults.data(forKey: "it.websyncro.client.inventory_batches"),
               let legacyDecoded = try? JSONDecoder().decode([InventoryBatch].self, from: legacyData) {
                self.batches = legacyDecoded
                saveBatches()
            } else {
                self.batches = []
            }
        }
    }

    private func saveBatches() {
        if let data = try? JSONEncoder().encode(batches) {
            userDefaults.setValue(data, forKey: storageKey)
        }
    }

    // MARK: - Filtri per Negozio & Utente Scoped

    /// Ritorna solo le liste appartenenti allo specifico negozio e codice tessera utente
    public func batches(for shopId: String, userCardCode: String) -> [InventoryBatch] {
        batches.filter { batch in
            let matchShop = batch.shopId.isEmpty || batch.shopId.caseInsensitiveCompare(shopId) == .orderedSame
            let matchUser = userCardCode.isEmpty || batch.userCardCode.isEmpty || batch.userCardCode.caseInsensitiveCompare(userCardCode) == .orderedSame
            return matchShop && matchUser
        }
    }

    /// Ritorna tutti gli articoli dell'utente attivo nel negozio attivo
    public func items(for shopId: String, userCardCode: String) -> [InventoryItem] {
        batches(for: shopId, userCardCode: userCardCode).flatMap { $0.items }
    }

    // MARK: - Motore di Deduplicazione

    /// Analizza gli articoli del nuovo lotto e li confronta con il DB locale per rilevare duplicati
    public func analyzeBatchForDuplicates(
        batch: InventoryBatch,
        shopId: String,
        userCardCode: String
    ) -> DeduplicationReport {
        let existing = items(for: shopId, userCardCode: userCardCode)
        let existingMap = Dictionary(grouping: existing, by: { $0.id }).compactMapValues { $0.first }

        var newItems: [InventoryItem] = []
        var duplicateItems: [InventoryItem] = []
        var updatedItems: [InventoryItem] = []

        for candidate in batch.items {
            if let existingItem = existingMap[candidate.id] {
                // Controlla se i dati di prezzo/quantità sono cambiati
                if existingItem.agreedPrice != candidate.agreedPrice ||
                   existingItem.quantity != candidate.quantity ||
                   existingItem.exposedPriceInitial != candidate.exposedPriceInitial {
                    updatedItems.append(candidate)
                } else {
                    duplicateItems.append(candidate)
                }
            } else {
                newItems.append(candidate)
            }
        }

        return DeduplicationReport(
            newItems: newItems,
            duplicateItems: duplicateItems,
            updatedItems: updatedItems
        )
    }

    /// Aggiunge o aggiorna un lotto applicando la logica di deduplicazione selezionata dall'utente
    public func addBatchWithDeduplication(
        batch: InventoryBatch,
        overwriteDuplicates: Bool = false
    ) -> (addedCount: Int, skippedCount: Int, updatedCount: Int) {
        var mutableBatch = batch

        let existing = items(for: batch.shopId, userCardCode: batch.userCardCode)
        let existingIds = Set(existing.map { $0.id })

        var addedCount = 0
        var skippedCount = 0
        var updatedCount = 0

        var finalItems: [InventoryItem] = []

        for item in mutableBatch.items {
            if existingIds.contains(item.id) {
                if overwriteDuplicates {
                    // Rimuovi la versione precedente e inserisci la nuova
                    deleteItem(id: item.id, shopId: batch.shopId, userCardCode: batch.userCardCode)
                    finalItems.append(item)
                    updatedCount += 1
                } else {
                    skippedCount += 1
                }
            } else {
                finalItems.append(item)
                addedCount += 1
            }
        }

        if !finalItems.isEmpty {
            mutableBatch.items = finalItems
            batches.insert(mutableBatch, at: 0)
            saveBatches()
        }

        HapticFeedback.notification(.success)
        return (addedCount, skippedCount, updatedCount)
    }

    /// Rimuove un'intera lista di carico
    public func deleteBatch(id: UUID) {
        batches.removeAll(where: { $0.id == id })
        saveBatches()
        HapticFeedback.impact(.light)
    }

    /// Rimuove un singolo articolo da tutte le liste dell'utente
    public func deleteItem(id: String, shopId: String? = nil, userCardCode: String? = nil) {
        let cleanId = id.replacingOccurrences(of: ".", with: "")
        for i in 0..<batches.count {
            if let s = shopId, !s.isEmpty, batches[i].shopId.caseInsensitiveCompare(s) != .orderedSame {
                continue
            }
            if let u = userCardCode, !u.isEmpty, !batches[i].userCardCode.isEmpty, batches[i].userCardCode.caseInsensitiveCompare(u) != .orderedSame {
                continue
            }
            batches[i].items.removeAll(where: { $0.id == cleanId })
        }
        batches.removeAll(where: { $0.items.isEmpty })
        saveBatches()
    }

    // MARK: - Motore di Riconciliazione (In Carico vs Vendite Online)

    public func saleStatus(
        for item: InventoryItem,
        maturedReport: SalesReport?,
        nonMaturedReport: SalesReport?
    ) -> InventorySaleStatus {
        let normalizedId = item.id

        if let maturedItem = maturedReport?.items.first(where: { $0.id == normalizedId }) {
            return .soldMatured(date: maturedItem.dateString, amount: maturedItem.amount)
        }

        if let nonMaturedItem = nonMaturedReport?.items.first(where: { $0.id == normalizedId }) {
            return .soldInRecesso(date: nonMaturedItem.dateString, amount: nonMaturedItem.amount)
        }

        return .unsoldInShop
    }

    public func reconciledItems(
        maturedReport: SalesReport?,
        nonMaturedReport: SalesReport?,
        shopId: String,
        userCardCode: String
    ) -> [(item: InventoryItem, status: InventorySaleStatus)] {
        let scopedItems = items(for: shopId, userCardCode: userCardCode)
        return scopedItems.map { item in
            let status = saleStatus(for: item, maturedReport: maturedReport, nonMaturedReport: nonMaturedReport)
            return (item: item, status: status)
        }
    }

    public func estimatedUnsoldValue(
        maturedReport: SalesReport?,
        nonMaturedReport: SalesReport?,
        shopId: String,
        userCardCode: String
    ) -> Decimal {
        let list = reconciledItems(
            maturedReport: maturedReport,
            nonMaturedReport: nonMaturedReport,
            shopId: shopId,
            userCardCode: userCardCode
        )
        return list.filter { $0.status == .unsoldInShop }
            .reduce(Decimal.zero) { sum, entry in
                sum + (entry.item.currentClientPayout() * Decimal(entry.item.quantity))
            }
    }
}
