import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Schermata per la modifica rapida, aggiunta ed eliminazione diretta degli articoli dell'inventario
public struct EditInventorySheet: View {
    @ObservedObject var inventoryStore: InventoryStore
    @ObservedObject var accountStore: AccountStore
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var itemToDelete: InventoryItem?
    @State private var showingDeleteAlert = false
    @State private var showingAddModal = false

    // Nuovo articolo manuale
    @State private var newTitle = ""
    @State private var newCode = ""
    @State private var newQuantity = 1
    @State private var newAgreedPrice: Decimal = 2.00
    @State private var newPayout: Decimal = 1.00
    @State private var newExposed: Decimal = 2.00

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

    private var scopedItems: [InventoryItem] {
        let all = inventoryStore.items(for: activeShopId, userCardCode: activeUserCardCode)
        if searchText.isEmpty {
            return all
        }
        return all.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.id.localizedCaseInsensitiveContains(searchText) ||
            $0.rawCode.localizedCaseInsensitiveContains(searchText)
        }
    }

    public var body: some View {
        NavigationStack {
            mainListContent
                .navigationTitle("Modifica Inventario (\(scopedItems.count))")
                .adaptiveInlineTitle()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Chiudi") { dismiss() }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            prepareNewItem()
                            showingAddModal = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.brandOrange.opacity(0.85))
                        }
                    }
                }
                .sheet(isPresented: $showingAddModal) {
                    newItemModalView
                }
                .alert("Eliminare questo Articolo?", isPresented: $showingDeleteAlert) {
                    Button("Annulla", role: .cancel) { itemToDelete = nil }
                    Button("Elimina", role: .destructive) {
                        if let item = itemToDelete {
                            inventoryStore.deleteItem(id: item.id, shopId: activeShopId, userCardCode: activeUserCardCode)
                            itemToDelete = nil
                        }
                    }
                } message: {
                    Text("L'articolo '\(itemToDelete?.title ?? "")' verrà rimosso permanentemente dal database locale.")
                }
        }
    }

    @ViewBuilder
    private var mainListContent: some View {
        ZStack {
            LiquidGlassBackground()

            ScrollView {
                LazyVStack(spacing: 14) {
                    SearchBarView(text: $searchText)

                    if scopedItems.isEmpty {
                        emptyItemsPlaceholder
                    } else {
                        ForEach(scopedItems) { item in
                            itemEditCard(item)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(16)
            }
        }
    }

    @ViewBuilder
    private var emptyItemsPlaceholder: some View {
        LiquidGlassCard(cornerRadius: 20, padding: 24) {
            VStack(spacing: 10) {
                Image(systemName: "pencil.slash")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("Nessun articolo trovato da modificare.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 20)
    }

    @ViewBuilder
    private var newItemModalView: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        newItemCardForm
                        Spacer()
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Nuovo Articolo")
            .adaptiveInlineTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { showingAddModal = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Aggiungi") {
                        saveNewManualItem()
                        showingAddModal = false
                    }
                    .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundColor(.brandOrange)
                    .fontWeight(.bold)
                }
            }
        }
    }

    @ViewBuilder
    private var newItemCardForm: some View {
        LiquidGlassCard(cornerRadius: 20, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Dati Nuovo Articolo")
                    .font(.headline)
                    .foregroundColor(.primary)

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Codice Fornitore (ID)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("Es. 1.260.999", text: $newCode)
                        .font(.system(.body, design: .monospaced))
                        .padding(10)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Descrizione / Titolo")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("Titolo completo", text: $newTitle)
                        .font(.body)
                        .padding(10)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quantità Pezzi")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Stepper("\(newQuantity) pz", value: $newQuantity, in: 1...999)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Quota Spettante")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        TextField("0.00", value: $newPayout, format: .number.precision(.fractionLength(2)))
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 80)
                            .padding(10)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Prezzo Esposto al Pubblico")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("0.00", value: $newExposed, format: .number.precision(.fractionLength(2)))
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 80)
                        .padding(10)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    @ViewBuilder
    private func itemEditCard(_ item: InventoryItem) -> some View {
        let totalQuota = item.clientPayoutInitial * Decimal(item.quantity)

        LiquidGlassCard(cornerRadius: 18, padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            TextField("Codice", text: Binding(
                                get: { item.rawCode },
                                set: {
                                    var updated = item
                                    updated.rawCode = $0
                                    inventoryStore.updateItem(updated)
                                }
                            ))
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.brandOrange)
                            .frame(maxWidth: 130)

                            HStack(spacing: 4) {
                                Text("Quota:")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text(CurrencyFormatter.format(decimal: totalQuota))
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.12), in: Capsule())
                        }

                        TextField("Titolo / Descrizione", text: Binding(
                            get: { item.title },
                            set: {
                                var updated = item
                                updated.title = $0
                                inventoryStore.updateItem(updated)
                            }
                        ))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    }

                    Spacer()

                    Button(role: .destructive, action: {
                        itemToDelete = item
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                            .padding(6)
                    }
                }

                Divider()

                HStack(spacing: 12) {
                    // Stepper Quantità
                    HStack(spacing: 4) {
                        Text("Qtà:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Stepper("\(item.quantity)", value: Binding(
                            get: { item.quantity },
                            set: {
                                var updated = item
                                updated.quantity = max(1, $0)
                                inventoryStore.updateItem(updated)
                            }
                        ), in: 1...999)
                        .labelsHidden()
                        Text("\(item.quantity) pz")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    // Quota / Rimborso Unitario
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Quota Singola")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        HStack(spacing: 2) {
                            Text("€")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            TextField("0.00", value: Binding(
                                get: { item.clientPayoutInitial },
                                set: {
                                    var updated = item
                                    updated.clientPayoutInitial = $0
                                    inventoryStore.updateItem(updated)
                                }
                            ), format: .number.precision(.fractionLength(2)))
                            .font(.caption)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 55)
                        }
                    }

                    Spacer()

                    // Esposto Iniziale
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Esposto")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        HStack(spacing: 2) {
                            Text("€")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            TextField("0.00", value: Binding(
                                get: { item.exposedPriceInitial },
                                set: {
                                    var updated = item
                                    updated.exposedPriceInitial = $0
                                    inventoryStore.updateItem(updated)
                                }
                            ), format: .number.precision(.fractionLength(2)))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 55)
                        }
                    }
                }
            }
        }
    }

    private func prepareNewItem() {
        newTitle = ""
        newCode = "1.\(Int.random(in: 100...999)).\(Int.random(in: 100...999))"
        newQuantity = 1
        newAgreedPrice = Decimal(2.00)
        newPayout = Decimal(1.00)
        newExposed = Decimal(2.00)
    }

    private func saveNewManualItem() {
        let item = InventoryItem(
            id: newCode,
            rawCode: newCode,
            listNumber: "MANUALE",
            loadDate: Date(),
            title: newTitle.trimmingCharacters(in: .whitespaces),
            category: "VARIE",
            quantity: newQuantity,
            agreedPrice: newAgreedPrice,
            clientPayoutInitial: newPayout,
            exposedPriceInitial: newExposed,
            shopId: activeShopId,
            userCardCode: activeUserCardCode
        )
        inventoryStore.addManualItem(item, shopId: activeShopId, userCardCode: activeUserCardCode)
    }
}
