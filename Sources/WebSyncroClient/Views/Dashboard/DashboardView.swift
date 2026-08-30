import SwiftUI

/// Vista principale della Dashboard con supporto Pull-to-Refresh e Materiali Nativi
public struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @StateObject private var accountStore: AccountStore
    
    @State private var showingAccountManager = false
    @State private var showingShopInfo = false

    public init(
        viewModel: DashboardViewModel? = nil,
        accountStore: AccountStore? = nil
    ) {
        let store = accountStore ?? AccountStore.shared
        _accountStore = StateObject(wrappedValue: store)
        _viewModel = StateObject(wrappedValue: viewModel ?? DashboardViewModel(accountStore: store))
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Header principale con selettore Maturato / In Recesso e totali
                        SummaryHeaderView(viewModel: viewModel)

                        // Barra di ricerca Liquid Glass
                        SearchBarView(text: $viewModel.searchText)

                        // Barra filtri e ordinamento
                        filterAndSortControls

                        // Contenuto principale: Lista, Stato di caricamento o Errore
                        mainContent
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
            .navigationTitle("Maturato")
            .adaptiveLargeTitle()
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    AccountSwitcherMenu(
                        accountStore: accountStore,
                        onManageAccounts: { showingAccountManager = true }
                    )
                }

                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        HapticFeedback.selection()
                        showingShopInfo = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showingShopInfo) {
                if let shopId = viewModel.activeAccount?.shopId {
                    ShopInfoView(shopId: shopId)
                }
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

    // MARK: - Filtri e Ordinamento
    @ViewBuilder
    private var filterAndSortControls: some View {
        LiquidGlassCard(cornerRadius: 16, padding: 8) {
            HStack(spacing: 8) {
                // Menu intervallo temporale
                Menu {
                    Picker("Periodo", selection: $viewModel.filterRange) {
                        ForEach(FilterRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(viewModel.filterRange.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
                    .foregroundColor(.primary)
                }

                // Menu Ordinamento
                Menu {
                    Picker("Ordina per", selection: $viewModel.sortOption) {
                        ForEach(SortOption.allCases) { opt in
                            Text(opt.rawValue).tag(opt)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption)
                        Text(viewModel.sortOption.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
                    .foregroundColor(.primary)
                }

                Spacer()

                // Indicatore conteggio elementi
                Text("\(viewModel.filteredItems.count) vendite")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 4)
            }
        }
    }

    // MARK: - Contenuto Principale
    @ViewBuilder
    private var mainContent: some View {
        if viewModel.syncStatus.isSyncing && viewModel.activeReport == nil {
            EmptyOrErrorView(type: .loading(message: viewModel.syncStatus.statusDescription))
                .padding(.top, 20)
        } else if let error = viewModel.errorMessage, viewModel.activeReport == nil {
            EmptyOrErrorView(
                type: .error(
                    message: error,
                    onRetry: {
                        Task { await viewModel.loadData() }
                    },
                    onEditAccount: {
                        showingAccountManager = true
                    }
                )
            )
            .padding(.top, 20)
        } else if viewModel.filteredItems.isEmpty {
            EmptyOrErrorView(
                type: .empty(
                    title: viewModel.searchText.isEmpty
                        ? (viewModel.selectedTab == .matured ? "Nessun articolo maturato" : "Nessun articolo in recesso")
                        : "Nessun risultato",
                    message: viewModel.searchText.isEmpty
                        ? (viewModel.selectedTab == .matured
                            ? "Non ci sono ancora vendite maturate disponibili."
                            : "Nessun articolo attualmente in periodo di recesso.")
                        : "Nessun articolo corrisponde ai criteri di ricerca impostati."
                )
            )
            .padding(.top, 20)
        } else {
            SalesListView(viewModel: viewModel)
        }
    }
}
