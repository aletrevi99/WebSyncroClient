import SwiftUI

/// Schermata per la consultazione e gestione delle liste di carico già registrate nel DB locale
public struct BatchesManagerSheet: View {
    @ObservedObject var inventoryStore: InventoryStore
    @ObservedObject var accountStore: AccountStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedBatchForDetail: InventoryBatch?
    @State private var batchToDelete: InventoryBatch?
    @State private var showingDeleteAlert = false

    public init(
        inventoryStore: InventoryStore? = nil,
        accountStore: AccountStore? = nil
    ) {
        self.inventoryStore = inventoryStore ?? InventoryStore.shared
        self.accountStore = accountStore ?? AccountStore.shared
    }

    private var activeShopId: String {
        accountStore.activeAccount?.shopId ?? "exnovomercatino"
    }

    private var activeUserCardCode: String {
        accountStore.activeAccount?.cardCode ?? ""
    }

    private var userBatches: [InventoryBatch] {
        inventoryStore.batches(for: activeShopId, userCardCode: activeUserCardCode)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        if userBatches.isEmpty {
                            LiquidGlassCard(cornerRadius: 22, padding: 24) {
                                VStack(spacing: 12) {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    Text("Nessuna Lista Salvata")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Scansiona una ricevuta per aggiungere la prima lista di carico al database locale.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.top, 20)
                        } else {
                            ForEach(userBatches) { batch in
                                batchCard(batch)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Liste di Carico (\(userBatches.count))")
            .adaptiveInlineTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
            .sheet(item: $selectedBatchForDetail) { batch in
                BatchDetailSheet(batch: batch)
            }
            .alert("Eliminare questa Lista?", isPresented: $showingDeleteAlert) {
                Button("Annulla", role: .cancel) { batchToDelete = nil }
                Button("Elimina", role: .destructive) {
                    if let b = batchToDelete {
                        inventoryStore.deleteBatch(id: b.id)
                        batchToDelete = nil
                    }
                }
            } message: {
                Text("Verranno rimossi tutti gli articoli appartenenti alla lista #\(batchToDelete?.listNumber ?? "").")
            }
        }
    }

    @ViewBuilder
    private func batchCard(_ batch: InventoryBatch) -> some View {
        LiquidGlassCard(cornerRadius: 20, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Lista #\(batch.listNumber.isEmpty ? "Senza Numero" : batch.listNumber)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("Data di Carico: \(formattedDate(batch.loadDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("\(batch.items.count) articoli (\(batch.totalPieces) pz)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.brandOrange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.brandOrange.opacity(0.12))
                        .clipShape(Capsule())
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Totale Concordato")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(CurrencyFormatter.format(decimal: batch.totalAgreedValue))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Totale Esposto")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(CurrencyFormatter.format(decimal: batch.totalExposedValue))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }

                Divider()

                HStack {
                    Button(action: {
                        selectedBatchForDetail = batch
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "list.bullet")
                            Text("Vedi Articoli (\(batch.items.count))")
                        }
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.brandOrange)
                    }

                    Spacer()

                    Button(role: .destructive, action: {
                        batchToDelete = batch
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

/// Schermata di dettaglio per una singola lista di carico
public struct BatchDetailSheet: View {
    public let batch: InventoryBatch
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(batch.items) { item in
                            LiquidGlassCard(cornerRadius: 16, padding: 14) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("#\(item.id)")
                                            .font(.system(.caption, design: .monospaced))
                                            .fontWeight(.bold)
                                            .foregroundColor(.brandOrange)

                                        Spacer()

                                        Text("Qtà: \(item.quantity) pz")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                    }

                                    Text(item.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)

                                    Divider()

                                    HStack {
                                        Text("Esposto Iniziale: \(CurrencyFormatter.format(decimal: item.exposedPriceInitial))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)

                                        Spacer()

                                        Text("Rimborso: \(CurrencyFormatter.format(decimal: item.clientPayoutInitial))")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Lista #\(batch.listNumber)")
            .adaptiveInlineTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
    }
}
