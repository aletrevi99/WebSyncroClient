import SwiftUI

/// Vista principale della Dashboard con supporto Pull-to-Refresh e Materiali Nativi
public struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @ObservedObject private var accountStore: AccountStore
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    @State private var showingAccountManager = false

    public init(
        viewModel: DashboardViewModel? = nil,
        accountStore: AccountStore? = nil
    ) {
        let store = accountStore ?? AccountStore.shared
        self.accountStore = store
        _viewModel = StateObject(wrappedValue: viewModel ?? DashboardViewModel(accountStore: store))
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Avviso In-App Reso Articolo (se attivo)
                    if let alert = notificationManager.activeReturnAlert {
                        returnAlertBanner(alert)
                    }

                    // Header principale con selettore Maturato / In Recesso e totali
                    SummaryHeaderView(viewModel: viewModel)

                    // Barra di ricerca Liquid Glass
                    SearchBarView(text: $viewModel.searchText)

                    // Barra filtri e ordinamento
                    filterAndSortControls

                    // Contenuto principale: Lista, Stato di caricamento o Errore
                    mainContent

                    // Spaziatore per evitare sovrapposizione con la TabBar
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(LiquidGlassBackground())
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Text(viewModel.selectedTab == .matured ? "Vendite" : "In Recesso")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                }
                #endif

                ToolbarItem(placement: .primaryAction) {
                    AccountSwitcherMenu(
                        accountStore: accountStore,
                        onManageAccounts: { showingAccountManager = true }
                    )
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showingAccountManager) {
                AccountManagerView()
            }
            .sheet(item: $viewModel.selectedItemForDetail) { item in
                SaleItemDetailSheet(item: item)
            }
            .task {
                if viewModel.maturedReport == nil {
                    await viewModel.loadData()
                }
            }
        }
    }

    // MARK: - Banner Avviso Reso In-App
    @ViewBuilder
    private func returnAlertBanner(_ alert: ReturnEvent) -> some View {
        LiquidGlassCard(cornerRadius: 18, padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Articolo Restituito (Reso)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                        Text("- € \(CurrencyFormatter.format(decimal: alert.amount))")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    Text("'\(alert.title)' è stato reso dall'acquirente durante il recesso ed è tornato in vendita in negozio.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Button(action: {
                    withAnimation {
                        notificationManager.dismissActiveReturnAlert()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Filtri e Ordinamento
    @ViewBuilder
    private var filterAndSortControls: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Menu Intervallo Temporale
                Menu {
                    ForEach(FilterRange.allCases) { range in
                        Button(action: {
                            viewModel.filterRange = range
                        }) {
                            HStack {
                                Text(range.rawValue)
                                if viewModel.filterRange == range {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(viewModel.filterRange.rawValue)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .foregroundColor(viewModel.filterRange != .all ? .brandOrange : .primary)
                    .background(viewModel.filterRange != .all ? Color.brandOrange.opacity(0.18) : Color.clear)
                    .background(.ultraThinMaterial, in: Capsule())
                }

                // Menu Ordinamento
                Menu {
                    ForEach(SortOption.allCases) { opt in
                        Button(action: {
                            viewModel.sortOption = opt
                        }) {
                            HStack {
                                Text(opt.rawValue)
                                if viewModel.sortOption == opt {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.sortOption.rawValue)
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption2)
                    }
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .foregroundColor(.primary)
                    .background(.ultraThinMaterial, in: Capsule())
                }

                Spacer()

                // Indicatore conteggio elementi
                Text("\(viewModel.filteredItems.count) vendite")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 4)
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.isLoading && viewModel.maturedReport == nil {
            loadingPlaceholder
        } else if let error = viewModel.errorMessage {
            errorStateView(message: error)
        } else if viewModel.filteredItems.isEmpty {
            emptyStateView
        } else {
            SalesListView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var loadingPlaceholder: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
                .padding(.top, 40)
            Text("Sincronizzazione vendite...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    @ViewBuilder
    private func errorStateView(message: String) -> some View {
        LiquidGlassCard(cornerRadius: 20, padding: 24) {
            VStack(spacing: 14) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 38))
                    .foregroundColor(.brandOrange)

                Text("Errore di Caricamento")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: {
                    Task { await viewModel.refresh() }
                }) {
                    Text("Riprova")
                        .font(.system(.subheadline, design: .rounded).bold())
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.brandOrange)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(.top, 6)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 20)
    }

    @ViewBuilder
    private var emptyStateView: some View {
        LiquidGlassCard(cornerRadius: 20, padding: 24) {
            VStack(spacing: 12) {
                Image(systemName: viewModel.selectedTab == .matured ? "cart.badge.questionmark" : "clock.arrow.circlepath")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary.opacity(0.7))

                Text(viewModel.selectedTab == .matured ? "Nessuna Vendita Maturata" : "Nessun Articolo in Recesso")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(viewModel.searchText.isEmpty ? "I tuoi articoli venduti compariranno qui non appena registrati dal negozio." : "Nessun risultato corrispondente alla ricerca.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 20)
    }
}
