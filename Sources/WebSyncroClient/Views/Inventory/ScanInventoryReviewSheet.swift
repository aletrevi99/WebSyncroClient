import SwiftUI

/// Modale di revisione, deduplicazione e conferma della lista oggetti prima del salvataggio nel database locale
public struct ScanInventoryReviewSheet: View {
    @State var batch: InventoryBatch
    @State var overwriteDuplicates: Bool = false
    let deduplicationReport: DeduplicationReport
    let onSave: (InventoryBatch, Bool) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(
        batch: InventoryBatch,
        deduplicationReport: DeduplicationReport,
        onSave: @escaping (InventoryBatch, Bool) -> Void
    ) {
        self._batch = State(initialValue: batch)
        self.deduplicationReport = deduplicationReport
        self.onSave = onSave
    }

    private func itemStatusBadge(for itemId: String) -> (text: String, color: Color, icon: String) {
        if deduplicationReport.newItems.contains(where: { $0.id == itemId }) {
            return ("Nuovo", .green, "sparkles")
        } else if deduplicationReport.updatedItems.contains(where: { $0.id == itemId }) {
            return ("Aggiornato", .blue, "arrow.triangle.2.circlepath")
        } else {
            return ("Già nel DB", .orange, "checkmark.circle")
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        // Card Analisi Deduplicazione
                        if deduplicationReport.hasDuplicates {
                            LiquidGlassCard(cornerRadius: 20, padding: 16) {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "doc.on.doc.fill")
                                            .foregroundColor(.brandOrange)
                                        Text("Controllo Duplicati nel DB")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }

                                    Text("Questa scansione contiene articoli già registrati nel tuo database locale:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    HStack(spacing: 12) {
                                        HStack(spacing: 4) {
                                            Circle().fill(Color.green).frame(width: 8, height: 8)
                                            Text("\(deduplicationReport.newItems.count) nuovi")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                        }

                                        HStack(spacing: 4) {
                                            Circle().fill(Color.orange).frame(width: 8, height: 8)
                                            Text("\(deduplicationReport.duplicateItems.count) già presenti")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                        }

                                        if !deduplicationReport.updatedItems.isEmpty {
                                            HStack(spacing: 4) {
                                                Circle().fill(Color.blue).frame(width: 8, height: 8)
                                                Text("\(deduplicationReport.updatedItems.count) modificati")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                            }
                                        }
                                    }

                                    Divider()

                                    Toggle(isOn: $overwriteDuplicates) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Sovrascrivi articoli duplicati")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            Text("Se disattivato, verranno aggiunti solo i \(deduplicationReport.newItems.count) nuovi articoli.")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .tint(Color.brandOrange)
                                }
                            }
                        }

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
                            Text("ARTICOLI ESTRATTI DALL'AI VISION")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)

                            ForEach($batch.items) { $item in
                                let badge = itemStatusBadge(for: item.id)

                                LiquidGlassCard(cornerRadius: 18, padding: 14) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(alignment: .top) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                HStack(spacing: 6) {
                                                    Text("#\(item.id)")
                                                        .font(.system(.caption, design: .monospaced))
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.brandOrange)

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
            .navigationTitle("Revisione Carico AI")
            .adaptiveInlineTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva nel DB") {
                        onSave(batch, overwriteDuplicates)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.brandOrange)
                }
            }
        }
    }
}
