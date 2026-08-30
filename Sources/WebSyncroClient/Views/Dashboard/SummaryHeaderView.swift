import SwiftUI

/// Header riassuntivo con totale maturato, non maturato in recesso e statistiche rapide
public struct SummaryHeaderView: View {
    @ObservedObject var viewModel: DashboardViewModel

    public init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 14) {
            // Selettore Principale: Maturato vs In Recesso (Non Maturato)
            LiquidGlassCard(cornerRadius: 18, padding: 6) {
                HStack(spacing: 6) {
                    // Tab Maturato
                    tabButton(
                        tab: .matured,
                        title: "Maturato",
                        amount: viewModel.totalMatured,
                        icon: "checkmark.seal.fill",
                        color: .green
                    )

                    // Tab In Recesso
                    tabButton(
                        tab: .nonMatured,
                        title: "In Recesso",
                        amount: viewModel.totalNonMatured,
                        icon: "clock.badge.exclamationmark.fill",
                        color: .orange
                    )
                }
            }

            // Card Principale con Totale Attivo
            LiquidGlassCard(cornerRadius: 24, padding: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.selectedTab == .matured ? "TOTALE MATURATO (DISPONIBILE)" : "VENDUTO IN DIRITTO DI RECESSO")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(viewModel.selectedTab == .matured ? .green : .orange)
                                .tracking(0.5)

                            if let account = viewModel.activeAccount {
                                Text(account.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        // Badge Demo
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
                        if let report = viewModel.activeReport {
                            Text(CurrencyFormatter.format(decimal: report.totalEarned))
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(viewModel.selectedTab == .matured ? .primary : .orange)
                        } else {
                            Text("€ 0,00")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.1))

                    // Metadati: Conteggio articoli & Totale Complessivo
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.selectedTab == .matured ? "cart.fill" : "hourglass")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                            Text("\(viewModel.activeReport?.itemsCount ?? 0) articoli")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            Text("Totale Generale:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(CurrencyFormatter.format(decimal: viewModel.grandTotal))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }

            // Banner esplicativo per "In Recesso"
            if viewModel.selectedTab == .nonMatured {
                LiquidGlassCard(cornerRadius: 18, padding: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Diritto di Recesso Acquirente")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text("Questi articoli sono stati acquistati di recente. Una volta trascorso il periodo di prova e garanzia di recesso, gli importi diventeranno 'Maturati' e saranno ritirabili in cassa.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            // Avviso del negozio se presente nel file maturato.txt (<#FRASEOPZIONALE>)
            if let notice = viewModel.activeReport?.optionalNotice, !notice.isEmpty {
                LiquidGlassCard(cornerRadius: 18, padding: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 16))
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

            // Statistiche rapide: Risultati Filtro
            if !viewModel.searchText.isEmpty || viewModel.filterRange != .all {
                HStack(spacing: 12) {
                    MetricStatCard(
                        title: "Risultati Filtro",
                        value: "\(viewModel.filteredItems.count) vendite",
                        subtitle: "Su \(viewModel.activeReport?.itemsCount ?? 0) totali",
                        iconName: "line.3.horizontal.decrease.circle",
                        accentColor: .blue
                    )

                    MetricStatCard(
                        title: "Somma Filtrata",
                        value: CurrencyFormatter.format(decimal: viewModel.filteredTotalEarned),
                        subtitle: "Visibile a schermo",
                        iconName: "eurosign.circle.fill",
                        accentColor: .green
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func tabButton(
        tab: SalesReportTab,
        title: String,
        amount: Decimal,
        icon: String,
        color: Color
    ) -> some View {
        let isSelected = viewModel.selectedTab == tab
        Button(action: {
            HapticFeedback.selection()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                viewModel.selectedTab = tab
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? color : .secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .primary : .secondary)

                    Text(CurrencyFormatter.format(decimal: amount))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(isSelected ? color : .secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.white.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
