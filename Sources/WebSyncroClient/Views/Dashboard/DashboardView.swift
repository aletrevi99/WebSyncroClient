import SwiftUI

/// Vista principale della Dashboard con supporto Pull-to-Refresh e Materiali Nativi
public struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @StateObject private var accountStore: AccountStore
    
    @State private var showingAccountManager = false
    @State private var showingSettings = false

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
                // Sfondo con rifrazione Liquid Glass
                LiquidGlassBackground()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Header principale con totali
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
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAccountManager) {
                AccountManagerView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(isDemoMode: $viewModel.isDemoMode)
            }
            .sheet(item: $viewModel.selectedItemForDetail) { item in
                SaleItemDetailSheet(item: item)
            }
            .task {
                if viewModel.report == nil {
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
        if viewModel.syncStatus.isSyncing && viewModel.report == nil {
            EmptyOrErrorView(type: .loading(message: viewModel.syncStatus.statusDescription))
                .padding(.top, 20)
        } else if let error = viewModel.errorMessage, viewModel.report == nil {
            EmptyOrErrorView(type: .error(message: error, onRetry: {
                Task { await viewModel.loadData() }
            }))
            .padding(.top, 20)
        } else if viewModel.filteredItems.isEmpty {
            EmptyOrErrorView(
                type: .empty(
                    title: viewModel.searchText.isEmpty ? "Nessuna vendita registrata" : "Nessun risultato",
                    message: viewModel.searchText.isEmpty
                        ? "Non ci sono ancora vendite maturate per questo account."
                        : "Nessun articolo corrisponde ai criteri di ricerca impostati."
                )
            )
            .padding(.top, 20)
        } else {
            SalesListView(viewModel: viewModel)
        }
    }
}

