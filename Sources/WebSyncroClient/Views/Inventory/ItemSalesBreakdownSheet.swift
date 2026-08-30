import SwiftUI

/// Scheda di dettaglio e scomposizione delle vendite per un articolo dell'inventario
public struct ItemSalesBreakdownSheet: View {
    public let item: InventoryItem
    public let status: InventorySaleStatus
    @Environment(\.dismiss) private var dismiss

    public init(item: InventoryItem, status: InventorySaleStatus) {
        self.item = item
        self.status = status
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        // Header Articolo
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("#\(item.id)")
                                        .font(.system(.caption, design: .monospaced))
                                        .fontWeight(.bold)
                                        .foregroundColor(.brandOrange)

                                    Spacer()

                                    Text("Qtà Iniziale: \(item.quantity) pz")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                }

                                Text(item.title)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)

                                Divider()

                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Data di Carico")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text(item.formattedLoadDate)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("Stato Esposizione")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text("\(item.daysSinceLoad()) giorni trascorsi")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.brandOrange)
                                    }
                                }
                            }
                        }

                        // Scomposizione Vendite e Presenza in Negozio
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SCOMPOSIZIONE STATO QUANTITÀ")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)

                            switch status {
                            case .fullySold(let matured, let nonMatured, let totalAmount):
                                if matured > 0 {
                                    maturedCard(count: matured, unitPayout: item.currentClientPayout())
                                }
                                if nonMatured > 0 {
                                    inRecessoCard(count: nonMatured, unitPayout: item.currentClientPayout())
                                }
                                totalEarnedCard(amount: totalAmount)

                            case .partiallySold(let matured, let nonMatured, let remaining, let maturedAmt, let nonMaturedAmt):
                                if matured > 0 {
                                    maturedCard(count: matured, unitPayout: item.currentClientPayout())
                                }
                                if nonMatured > 0 {
                                    inRecessoCard(count: nonMatured, unitPayout: item.currentClientPayout())
                                }
                                inShopCard(count: remaining, unitPayout: item.currentClientPayout())
                                totalEarnedCard(amount: maturedAmt + nonMaturedAmt)

                            case .unsoldInShop(let qty):
                                inShopCard(count: qty, unitPayout: item.currentClientPayout())
                            }
                        }

                        // Timeline Ciclo di Vita
                        LiquidGlassCard(cornerRadius: 20, padding: 16) {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Regole di Svalutazione", systemImage: "clock.arrow.circlepath")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)

                                Divider()

                                let next = item.daysUntilNextStage()
                                if let nextStage = next.nextStage {
                                    Text("Tra \(next.days) giorni: \(nextStage == .discounted50 ? "Sconto in Saldo (-50%)" : "Maggior Realizzo")")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.brandOrange)
                                } else {
                                    Text("Oltre 90 giorni: Maggior Realizzo")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                }

                                Text(item.daysSinceLoad() <= 60
                                     ? "I primi 60 giorni l'articolo è esposto a prezzo pieno. Dal 61° giorno il prezzo e il rimborso vengono dimezzati."
                                     : (item.daysSinceLoad() <= 90
                                        ? "L'articolo è attualmente in saldo al 50%."
                                        : "L'articolo ha superato i 90 giorni di esposizione."))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Dettaglio Articolo")
            .adaptiveInlineTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func maturedCard(count: Int, unitPayout: Decimal) -> some View {
        LiquidGlassCard(cornerRadius: 18, padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Maturato (\(count) pz)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Importo riscuotibile subito in cassa.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(CurrencyFormatter.format(decimal: unitPayout * Decimal(count)))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
        }
    }

    @ViewBuilder
    private func inRecessoCard(count: Int, unitPayout: Decimal) -> some View {
        LiquidGlassCard(cornerRadius: 18, padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: "hourglass")
                    .font(.title3)
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("In Recesso (\(count) pz)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Periodo di recesso attivo (14 giorni).")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(CurrencyFormatter.format(decimal: unitPayout * Decimal(count)))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
        }
    }

    @ViewBuilder
    private func inShopCard(count: Int, unitPayout: Decimal) -> some View {
        LiquidGlassCard(cornerRadius: 18, padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: "storefront.fill")
                    .font(.title3)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("In Negozio (\(count) pz)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Ancora esposto al pubblico.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(CurrencyFormatter.format(decimal: unitPayout * Decimal(count)))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.brandOrange)
                    Text("Stima incasso")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func totalEarnedCard(amount: Decimal) -> some View {
        LiquidGlassCard(cornerRadius: 18, padding: 14) {
            HStack {
                Text("Totale Guadagno Realizzato:")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()

                Text(CurrencyFormatter.format(decimal: amount))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
        }
    }
}

