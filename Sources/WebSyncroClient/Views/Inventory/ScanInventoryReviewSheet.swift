import SwiftUI

/// Modale di revisione e conferma della lista oggetti scansionata prima del salvataggio nel database locale
public struct ScanInventoryReviewSheet: View {
    @State var batch: InventoryBatch
    let onSave: (InventoryBatch) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(batch: InventoryBatch, onSave: @escaping (InventoryBatch) -> Void) {
        self._batch = State(initialValue: batch)
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        // Card Intestazione Documento
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Label("Dati Documento Carico", systemImage: "doc.text.fill")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(batch.items.count) articoli")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.brandOrange)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.brandOrange.opacity(0.12))
                                        .clipShape(Capsule())
                                }

                                Divider()

                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Numero Lista")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        TextField("Numero lista", text: $batch.listNumber)
                                            .font(.system(.body, design: .monospaced))
                                            .fontWeight(.bold)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("Data di Carico")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        DatePicker("", selection: $batch.loadDate, displayedComponents: .date)
                                            .labelsHidden()
                                    }
                                }

                                Divider()

                                HStack(spacing: 16) {
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
                                        Text("Totale Esposto Pubblico")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text(CurrencyFormatter.format(decimal: batch.totalExposedValue))
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }

                        // Lista Articoli Estratti
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ARTICOLI ESTRATTI DALLA FOTO")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)

                            ForEach($batch.items) { $item in
                                LiquidGlassCard(cornerRadius: 18, padding: 14) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(alignment: .top) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("#\(item.id)")
                                                    .font(.system(.caption, design: .monospaced))
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.brandOrange)

                                                TextField("Descrizione", text: $item.title)
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                            }

                                            Spacer()

                                            Button(action: {
                                                if let idx = batch.items.firstIndex(where: { $0.id == item.id }) {
                                                    batch.items.remove(at: idx)
                                                }
                                            }) {
                                                Image(systemName: "trash")
                                                    .font(.caption)
                                                    .foregroundColor(.red.opacity(0.8))
                                            }
                                        }

                                        Divider()

                                        HStack(spacing: 12) {
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text("Qtà")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Text("\(item.quantity)")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                            }

                                            Spacer()

                                            VStack(alignment: .center, spacing: 1) {
                                                Text("Rimborso Unitario")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Text(CurrencyFormatter.format(decimal: item.clientPayoutInitial))
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.primary)
                                            }

                                            Spacer()

                                            VStack(alignment: .trailing, spacing: 1) {
                                                Text("Esposto Iniziale")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Text(CurrencyFormatter.format(decimal: item.exposedPriceInitial))
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.green)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Revisione Carico")
            .adaptiveInlineTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva nel DB") {
                        onSave(batch)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.brandOrange)
                }
            }
        }
    }
}
