import Foundation
import Combine
#if canImport(PDFKit)
import PDFKit
#endif
#if canImport(UIKit)
import UIKit
#endif

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

/// Gestore del database locale dell'inventario, isolato per utente e negozio, con tracciamento quantità, deduplicazione ed esportazione
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

    public func batches(for shopId: String, userCardCode: String) -> [InventoryBatch] {
        batches.filter { batch in
            let matchShop = batch.shopId.isEmpty || batch.shopId.caseInsensitiveCompare(shopId) == .orderedSame
            let matchUser = userCardCode.isEmpty || batch.userCardCode.isEmpty || batch.userCardCode.caseInsensitiveCompare(userCardCode) == .orderedSame
            return matchShop && matchUser
        }
    }

    public func items(for shopId: String, userCardCode: String) -> [InventoryItem] {
        batches(for: shopId, userCardCode: userCardCode).flatMap { $0.items }
    }

    // MARK: - Motore di Deduplicazione

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

    public func deleteBatch(id: UUID) {
        batches.removeAll(where: { $0.id == id })
        saveBatches()
        HapticFeedback.impact(.light)
    }

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

    public func updateItem(_ item: InventoryItem) {
        for bIdx in 0..<batches.count {
            if let iIdx = batches[bIdx].items.firstIndex(where: { $0.id == item.id }) {
                batches[bIdx].items[iIdx] = item
                saveBatches()
                HapticFeedback.notification(.success)
                return
            }
        }
    }

    public func addManualItem(_ item: InventoryItem, shopId: String, userCardCode: String) {
        if let firstIdx = batches.firstIndex(where: {
            $0.shopId.caseInsensitiveCompare(shopId) == .orderedSame &&
            $0.userCardCode.caseInsensitiveCompare(userCardCode) == .orderedSame
        }) {
            batches[firstIdx].items.insert(item, at: 0)
        } else {
            let newBatch = InventoryBatch(
                listNumber: "MANUALE",
                loadDate: Date(),
                shopId: shopId,
                userCardCode: userCardCode,
                items: [item]
            )
            batches.insert(newBatch, at: 0)
        }
        saveBatches()
        HapticFeedback.notification(.success)
    }

    // MARK: - Motore di Riconciliazione (Tracciamento Quantità e Vendite Parziali)

    public func saleStatus(
        for item: InventoryItem,
        maturedReport: SalesReport?,
        nonMaturedReport: SalesReport?
    ) -> InventorySaleStatus {
        let normalizedId = item.id

        let maturedMatches = maturedReport?.items.filter { $0.id == normalizedId } ?? []
        let nonMaturedMatches = nonMaturedReport?.items.filter { $0.id == normalizedId } ?? []

        let maturedCount = maturedMatches.count
        let nonMaturedCount = nonMaturedMatches.count
        let totalSoldCount = maturedCount + nonMaturedCount

        let maturedAmount = maturedMatches.reduce(Decimal.zero) { $0 + $1.amount }
        let nonMaturedAmount = nonMaturedMatches.reduce(Decimal.zero) { $0 + $1.amount }

        if totalSoldCount == 0 {
            return .unsoldInShop(quantity: item.quantity)
        } else if totalSoldCount >= item.quantity {
            return .fullySold(
                maturedQty: maturedCount,
                inRecessoQty: nonMaturedCount,
                totalAmount: maturedAmount + nonMaturedAmount
            )
        } else {
            let remaining = max(0, item.quantity - totalSoldCount)
            return .partiallySold(
                soldMaturedQty: maturedCount,
                soldInRecessoQty: nonMaturedCount,
                remainingQty: remaining,
                maturedAmount: maturedAmount,
                inRecessoAmount: nonMaturedAmount
            )
        }
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
        return list.reduce(Decimal.zero) { sum, entry in
            let remainingCount = entry.status.remainingInShopCount
            return sum + entry.item.totalCurrentClientPayout(for: remainingCount)
        }
    }

    // MARK: - Ordinamento Inventario

    public func sort(
        entries: [(item: InventoryItem, status: InventorySaleStatus)],
        by option: InventorySortOption
    ) -> [(item: InventoryItem, status: InventorySaleStatus)] {
        switch option {
        case .dateDescending:
            return entries.sorted { $0.item.loadDate > $1.item.loadDate }
        case .dateAscending:
            return entries.sorted { $0.item.loadDate < $1.item.loadDate }
        case .payoutDescending:
            return entries.sorted { $0.item.currentClientPayout() > $1.item.currentClientPayout() }
        case .payoutAscending:
            return entries.sorted { $0.item.currentClientPayout() < $1.item.currentClientPayout() }
        case .quantityDescending:
            return entries.sorted { $0.item.quantity > $1.item.quantity }
        case .titleAscending:
            return entries.sorted { $0.item.title.localizedCaseInsensitiveCompare($1.item.title) == .orderedAscending }
        case .statusInShopFirst:
            return entries.sorted {
                let leftRank = $0.status.hasRemainingInShop ? 0 : 1
                let rightRank = $1.status.hasRemainingInShop ? 0 : 1
                return leftRank < rightRank
            }
        }
    }

    // MARK: - Esportazione Diagnostica & Dati (JSON, CSV e Report)

    public func exportJSONData() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(batches)
    }

    public func exportCSVData(shopId: String, userCardCode: String) -> String {
        let scopedBatches = batches(for: shopId, userCardCode: userCardCode)
        var csv = "Codice,Titolo,Quantita,PrezzoConcordato,RimborsoNetto,PrezzoEsposto,ListaNumero,DataCarico,Negozio\n"
        for batch in scopedBatches {
            for item in batch.items {
                let cleanTitle = item.title.replacingOccurrences(of: "\"", with: "\"\"")
                csv += "\"\(item.rawCode)\",\"\(cleanTitle)\",\(item.quantity),\(item.agreedPrice),\(item.clientPayoutInitial),\(item.exposedPriceInitial),\"\(batch.listNumber)\",\"\(item.formattedLoadDate)\",\"\(batch.shopId)\"\n"
            }
        }
        return csv
    }

    public func exportDiagnosticReport(shopId: String, userCardCode: String) -> String {
        let scopedBatches = batches(for: shopId, userCardCode: userCardCode)
        var report = "=== REPORT INVENTARIO WEBSYNCRO ===\n"
        report += "Data Esportazione: \(Date())\n"
        report += "Negozio: \(shopId)\n"
        report += "Codice Tessera Utente: \(userCardCode)\n"
        report += "Lotti Totali: \(scopedBatches.count)\n"
        report += "Articoli Totali: \(scopedBatches.flatMap { $0.items }.count)\n\n"

        for (bIdx, batch) in scopedBatches.enumerated() {
            report += "--- LISTA [\(bIdx + 1)] #\(batch.listNumber) (Data: \(batch.loadDate)) ---\n"
            report += "Totale Pezzi: \(batch.totalPieces), Valore Concordato: € \(batch.totalAgreedValue), Valore Esposto: € \(batch.totalExposedValue)\n"
            for item in batch.items {
                report += " • Codice: \(item.rawCode) (ID: \(item.id)) | Qtà: \(item.quantity) | Titolo: \(item.title) | Concordato: € \(item.agreedPrice) | Rimborso: € \(item.clientPayoutInitial) | Esposto: € \(item.exposedPriceInitial)\n"
            }
            report += "\n"
        }
        return report
    }
}
