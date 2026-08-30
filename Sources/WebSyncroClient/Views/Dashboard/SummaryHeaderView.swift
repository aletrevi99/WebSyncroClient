import SwiftUI

/// Header riassuntivo con totale maturato, statistiche rapide e avvisi negozio
public struct SummaryHeaderView: View {
    @ObservedObject var viewModel: DashboardViewModel

    public init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 14) {
            // Card Principale: Totale Maturato
            LiquidGlassCard(cornerRadius: 24, padding: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TOTALE MATURATO")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .tracking(1)

                            if let account = viewModel.activeAccount {
                                Text(account.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        // Badge di stato / demo
                        if viewModel.isDemoMode {
                            Text("DEMO")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.15))
                                .foregroundColor(.purple)
                                .clipShape(Capsule())
                        }
                    }

                    // Importo principale in evidenza
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        if let report = viewModel.report {
                            Text(CurrencyFormatter.format(decimal: report.totalEarned))
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(.primary)
                        } else {
                            Text("€ 0,00")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.1))

                    // Metadati secondari: Articoli & Ultimo snapshot
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "cart.fill")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                            Text("\(viewModel.report?.itemsCount ?? 0) articoli venduti")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.2.circlepath")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(viewModel.report?.formattedSyncDate ?? "Mai")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Avviso del negozio se presente nel file maturato.txt (<#FRASEOPZIONALE>)
            if let notice = viewModel.report?.optionalNotice, !notice.isEmpty {
                LiquidGlassCard(cornerRadius: 18, padding: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Comunicazione dal Mercatino")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text(notice)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            // Statistiche rapide: Totale filtrato (se diversa dalla vista globale) e conteggio
            if !viewModel.searchText.isEmpty || viewModel.filterRange != .all {
                HStack(spacing: 12) {
                    MetricStatCard(
                        title: "Risultati Filtro",
                        value: "\(viewModel.filteredItems.count) vendite",
                        subtitle: "Su \(viewModel.report?.itemsCount ?? 0) totali",
                        iconName: "line.3.horizontal.decrease.circle",
                        accentColor: .blue
                    )

                    MetricStatCard(
                        title: "Maturato Filtrato",
                        value: CurrencyFormatter.format(decimal: viewModel.filteredTotalEarned),
                        subtitle: "Somma visibile",
                        iconName: "eurosign.circle.fill",
                        accentColor: .green
                    )
                }
            }
        }
    }
}

