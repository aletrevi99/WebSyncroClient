import Foundation
import Combine

/// Gestore del database locale dell'inventario e motore di riconciliazione con le vendite online
@MainActor
public final class InventoryStore: ObservableObject {
    public static let shared = InventoryStore()

    private let userDefaults: UserDefaults
    private let storageKey = "it.websyncro.client.inventory_batches"

    @Published public private(set) var batches: [InventoryBatch] = []

    public var allItems: [InventoryItem] {
        batches.flatMap { $0.items }
    }

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadBatches()
    }

    /// Carica le liste di carico dal database locale
    public func loadBatches() {
        if let data = userDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([InventoryBatch].self, from: data) {
            self.batches = decoded
        } else {
            self.batches = []
        }
    }

    /// Salva i lotti nel database locale
    private func saveBatches() {
        if let data = try? JSONEncoder().encode(batches) {
            userDefaults.setValue(data, forKey: storageKey)
        }
    }

    /// Aggiunge una nuova lista di carico scansionata
    public func addBatch(_ batch: InventoryBatch) {
        // Se esiste già una lista con lo stesso numero, la aggiorna/sostituisce
        if let index = batches.firstIndex(where: { $0.listNumber == batch.listNumber && !$0.listNumber.isEmpty }) {
            batches[index] = batch
        } else {
            batches.insert(batch, at: 0)
        }
        saveBatches()
        HapticFeedback.notification(.success)
    }

    /// Rimuove un'intera lista di carico
    public func deleteBatch(id: UUID) {
        batches.removeAll(where: { $0.id == id })
        saveBatches()
        HapticFeedback.impact(.light)
    }

    /// Rimuove un singolo articolo da tutte le liste
    public func deleteItem(id: String) {
        let cleanId = id.replacingOccurrences(of: ".", with: "")
        for i in 0..<batches.count {
            batches[i].items.removeAll(where: { $0.id == cleanId })
        }
        batches.removeAll(where: { $0.items.isEmpty })
        saveBatches()
    }

    // MARK: - Motore di Riconciliazione (In Carico vs Vendite Online)

    /// Determina lo stato di vendita di un singolo articolo confrontandolo con i report online
    public func saleStatus(
        for item: InventoryItem,
        maturedReport: SalesReport?,
        nonMaturedReport: SalesReport?
    ) -> InventorySaleStatus {
        let normalizedId = item.id

        // 1. Controllo nel report maturato (Venduto e pronto per incasso)
        if let maturedItem = maturedReport?.items.first(where: { $0.id == normalizedId }) {
            return .soldMatured(date: maturedItem.dateString, amount: maturedItem.amount)
        }

        // 2. Controllo nel report in recesso (Venduto, in attesa di 15 giorni)
        if let nonMaturedItem = nonMaturedReport?.items.first(where: { $0.id == normalizedId }) {
            return .soldInRecesso(date: nonMaturedItem.dateString, amount: nonMaturedItem.amount)
        }

        // 3. Altrimenti è ancora fisicamente esposto in negozio
        return .unsoldInShop
    }

    /// Ritorna tutti gli articoli con il loro stato di vendita calcolato in tempo reale
    public func reconciledItems(
        maturedReport: SalesReport?,
        nonMaturedReport: SalesReport?,
        shopIdFilter: String? = nil
    ) -> [(item: InventoryItem, status: InventorySaleStatus)] {
        var result: [(item: InventoryItem, status: InventorySaleStatus)] = []
        for item in allItems {
            if let filter = shopIdFilter, !filter.isEmpty {
                guard item.shopId.caseInsensitiveCompare(filter) == .orderedSame else { continue }
            }
            let status = saleStatus(for: item, maturedReport: maturedReport, nonMaturedReport: nonMaturedReport)
            result.append((item: item, status: status))
        }
        return result
    }

    /// Calcola la stima del valore netto degli articoli attualmente ancora invenduti in negozio
    public func estimatedUnsoldValue(
        maturedReport: SalesReport?,
        nonMaturedReport: SalesReport?,
        shopIdFilter: String? = nil
    ) -> Decimal {
        let list = reconciledItems(maturedReport: maturedReport, nonMaturedReport: nonMaturedReport, shopIdFilter: shopIdFilter)
        return list.filter { $0.status == .unsoldInShop }
            .reduce(Decimal.zero) { sum, entry in
                sum + (entry.item.currentClientPayout() * Decimal(entry.item.quantity))
            }
    }
}
