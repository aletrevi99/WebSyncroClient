import SwiftUI

/// Scheda di revisione per confermare, modificare o rimuovere articoli estratti dall'AI Vision prima del salvataggio nel database locale
public struct ScanInventoryReviewSheet: View {
    @State private var batch: InventoryBatch
    public let deduplicationReport: DeduplicationReport
    public let onSave: (InventoryBatch, Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var overwriteDuplicates: Bool = false
    @State private var showingAddManualItemSheet = false

    public init(
        batch: InventoryBatch,
        deduplicationReport: DeduplicationReport,
        onSave: @escaping (InventoryBatch, Bool) -> Void
    ) {
        self._batch = State(initialValue: batch)
        self.deduplicationReport = deduplicationReport
        self.onSave = onSave
    }

    private var duplicateIds: Set<String> {
        Set(deduplicationReport.duplicateItems.map { $0.id })
    }

    private var updatedIds: Set<String> {
        Set(deduplicationReport.updatedItems.map { $0.id })
    }

    private var totalCalculatedPieces: Int {
        batch.items.reduce(0) { $0 + $1.quantity }
    }

    private var totalCalculatedAgreed: Decimal {
        batch.items.reduce(Decimal.zero) { $0 + ($1.agreedPrice * Decimal($1.quantity)) }
    }

    private var totalCalculatedExposed: Decimal {
        batch.items.reduce(Decimal.zero) { $0 + ($1.exposedPriceInitial * Decimal($1.quantity)) }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Card Deduplicazione
                        if deduplicationReport.hasDuplicates {
                            LiquidGlassCard(cornerRadius: 20, padding: 16) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "doc.on.doc.fill")
                                            .foregroundColor(.brandOrange)
                                        Text("Controllo Duplicati nel DB")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                    }

                                    Text("Questa scansione contiene articoli già registrati nel tuo database locale:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    HStack(spacing: 12) {
                                        Label("\(deduplicationReport.newItems.count) nuovi", systemImage: "sparkles")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)

                                        Label("\(deduplicationReport.duplicateItems.count) già presenti", systemImage: "checkmark.circle.fill")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.orange)

                                        if !deduplicationReport.updatedItems.isEmpty {
                                            Label("\(deduplicationReport.updatedItems.count) variati", systemImage: "arrow.triangle.2.circlepath")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.blue)
                                        }
                                    }

                                    Divider()

                                    Toggle(isOn: $overwriteDuplicates) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Sovrascrivi articoli duplicati")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            Text(overwriteDuplicates
                                                 ? "Gli articoli già esistenti verranno aggiornati con i nuovi dati."
                                                 : "Se disattivato, verranno aggiunti solo i \(deduplicationReport.newItems.count) nuovi articoli.")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .tint(Color.brandOrange)
                                }
                            }
                        }

                        // Header Riepilogo Lista Carico Modificabile
                        LiquidGlassCard(cornerRadius: 22, padding: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Label("Dati Documento Carico", systemImage: "doc.text.fill")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(batch.items.count) articoli (\(totalCalculatedPieces) pz)")
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
                                        Text(CurrencyFormatter.format(decimal: totalCalculatedAgreed))
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("Totale Esposto Pubblico")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text(CurrencyFormatter.format(decimal: totalCalculatedExposed))
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }

                        // Lista Articoli Estratti Modificabili
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("ARTICOLI ESTRATTI DALL'AI VISION")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)

                                Spacer()

                                Button(action: {
                                    addNewEmptyItem()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Aggiungi Articolo")
                                    }
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.brandOrange)
                                }
                            }

                            ForEach(Array(batch.items.enumerated()), id: \.element.id) { index, item in
                                let badge = itemStatusBadge(for: item.id)

                                LiquidGlassCard(cornerRadius: 18, padding: 14) {
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack(alignment: .top) {
                                            VStack(alignment: .leading, spacing: 3) {
                                                HStack(spacing: 6) {
                                                    TextField("Codice", text: Binding(
                                                        get: { batch.items[index].rawCode },
                                                        set: {
                                                            batch.items[index].rawCode = $0
                                                        }
                                                    ))
                                                    .font(.system(.caption, design: .monospaced))
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.brandOrange)
                                                    .frame(maxWidth: 120)

                                                    HStack(spacing: 3) {
                                                        Image(systemName: badge.icon)
                                                            .font(.system(size: 8))
                                                        Text(badge.text)
                                                            .font(.system(size: 9, weight: .bold))
                                                    }
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(badge.color.opacity(0.12))
                                                    .foregroundColor(badge.color)
                                                    .clipShape(Capsule())
                                                }

                                                TextField("Descrizione completa", text: Binding(
                                                    get: { batch.items[index].title },
                                                    set: { batch.items[index].title = $0 }
                                                ))
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            }

                                            Spacer()

                                            Button(action: {
                                                if index < batch.items.count {
                                                    batch.items.remove(at: index)
                                                }
                                            }) {
                                                Image(systemName: "trash")
                                                    .font(.caption)
                                                    .foregroundColor(.red.opacity(0.8))
                                                    .padding(6)
                                            }
                                        }

                                        Divider()

                                        // Campi Valori Modificabili
                                        HStack(spacing: 12) {
                                            // Quantità con Stepper
                                            HStack(spacing: 4) {
                                                Text("Qtà:")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Stepper("\(batch.items[index].quantity)", value: Binding(
                                                    get: { batch.items[index].quantity },
                                                    set: { batch.items[index].quantity = max(1, $0) }
                                                ), in: 1...999)
                                                .labelsHidden()
                                                Text("\(batch.items[index].quantity)")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.primary)
                                            }

                                            Spacer()

                                            // Rimborso Netto Unitario
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text("Rimborso Unitario")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                HStack(spacing: 2) {
                                                    Text("€")
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                    TextField("0.00", value: Binding(
                                                        get: { batch.items[index].clientPayoutInitial },
                                                        set: { batch.items[index].clientPayoutInitial = $0 }
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
                                                        get: { batch.items[index].exposedPriceInitial },
                                                        set: { batch.items[index].exposedPriceInitial = $0 }
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
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Revisione Carico AI")
            .adaptiveInlineTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva nel DB") {
                        var finalBatch = batch
                        finalBatch.totalPieces = totalCalculatedPieces
                        finalBatch.totalAgreedValue = totalCalculatedAgreed
                        finalBatch.totalExposedValue = totalCalculatedExposed
                        onSave(finalBatch, overwriteDuplicates)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.brandOrange)
                }
            }
        }
    }

    private func addNewEmptyItem() {
        let newId = "ART\(Int.random(in: 100000...999999))"
        let newItem = InventoryItem(
            id: newId,
            rawCode: newId,
            listNumber: batch.listNumber,
            loadDate: batch.loadDate,
            title: "Nuovo Articolo",
            category: "VARIE",
            quantity: 1,
            agreedPrice: Decimal(2.00),
            clientPayoutInitial: Decimal(1.00),
            exposedPriceInitial: Decimal(2.00),
            shopId: batch.shopId,
            userCardCode: batch.userCardCode
        )
        batch.items.append(newItem)
    }

    private func itemStatusBadge(for itemId: String) -> (text: String, color: Color, icon: String) {
        if duplicateIds.contains(itemId) {
            return ("Già nel DB", .orange, "checkmark.circle.fill")
        } else if updatedIds.contains(itemId) {
            return ("Modificato", .blue, "arrow.triangle.2.circlepath")
        } else {
            return ("Nuovo", .green, "sparkles")
        }
    }
}
