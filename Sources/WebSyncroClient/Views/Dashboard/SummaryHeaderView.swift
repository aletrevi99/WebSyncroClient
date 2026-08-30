import SwiftUI

/// Header riassuntivo con totale maturato, non maturato in recesso e statistiche rapide
public struct SummaryHeaderView: View {
    @ObservedObject var viewModel: DashboardViewModel

    public init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    private var shouldShowNotice: Bool {
        guard let notice = viewModel.activeReport?.optionalNotice, !notice.isEmpty else {
            return false
        }
        let cleanNotice = notice.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        // Se è la frase di default ridondante sul recesso, non mostrarla
        if cleanNotice.contains("articoli venduti ma non rimborsabile") ||
           cleanNotice.contains("venduto non rimborsabile") {
            return false
        }
        return true
    }

    public var body: some View {
        VStack(spacing: 14) {
            // Selettore Principale: Maturato vs In Recesso
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
                        icon: "hourglass",
                        color: .brandOrange
                    )
                }
            }

            // Card Principale con Totale Attivo (perfettamente simmetrica tra Maturato e In Recesso)
            LiquidGlassCard(cornerRadius: 24, padding: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.selectedTab == .matured ? "VENDUTO MATURATO (DISPONIBILE)" : "VENDUTO IN DIRITTO DI RECESSO")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(viewModel.selectedTab == .matured ? .green : .brandOrange)
                            .tracking(0.5)

                        if let account = viewModel.activeAccount {
                            Text(account.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Importo principale in evidenza (uguale struttura in entrambe le schede)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        if let report = viewModel.activeReport {
                            Text(CurrencyFormatter.format(decimal: report.totalEarned))
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(viewModel.selectedTab == .matured ? .primary : .brandOrange)
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
                                .foregroundColor(viewModel.selectedTab == .matured ? .green : .brandOrange)
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
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Banner esplicativo per "In Recesso"
            if viewModel.selectedTab == .nonMatured {
                LiquidGlassCard(cornerRadius: 18, padding: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.brandOrange)
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

            // Avviso del negozio se presente e rilevante
            if shouldShowNotice, let notice = viewModel.activeReport?.optionalNotice {
                LiquidGlassCard(cornerRadius: 18, padding: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.brandOrange)
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
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
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
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                    } else {
                        Color.clear
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
