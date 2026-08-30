import SwiftUI

/// Vista principale della Dashboard con supporto Pull-to-Refresh e Materiali Nativi
public struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @StateObject private var accountStore: AccountStore
    
    @State private var showingAccountManager = false

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
            .navigationTitle(viewModel.selectedTab == .matured ? "Vendite" : "In Recesso")
            .adaptiveLargeTitle()
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    AccountSwitcherMenu(
                        accountStore: accountStore,
                        onManageAccounts: { showingAccountManager = true }
                    )
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
                    .background(viewModel.filterRange != .all ? Color.brandOrange.opacity(0.12) : Color.clear)
                    .background(.ultraThinMaterial)
                    .foregroundColor(viewModel.filterRange != .all ? .brandOrange : .primary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(viewModel.filterRange != .all ? Color.brandOrange : Color.white.opacity(0.18), lineWidth: 1)
                    )
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
                    .background(.ultraThinMaterial)
                    .foregroundColor(.primary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
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
