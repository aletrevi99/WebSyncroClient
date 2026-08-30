import Foundation
import Combine

public enum SortOption: String, CaseIterable, Identifiable {
    case dateDescending = "Recenti prima"
    case dateAscending = "Meno recenti"
    case amountDescending = "Importo maggiore"
    case amountAscending = "Importo minore"

    public var id: String { rawValue }
}

public enum FilterRange: String, CaseIterable, Identifiable {
    case all = "Tutti"
    case thisMonth = "Questo mese"
    case last90Days = "Ultimi 90 gg"

    public var id: String { rawValue }
}

@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public var report: SalesReport?
    @Published public var syncStatus: SyncStatus = .idle
    @Published public var errorMessage: String?
    @Published public var searchText: String = ""
    @Published public var sortOption: SortOption = .dateDescending
    @Published public var filterRange: FilterRange = .all
    @Published public var selectedItemForDetail: SaleItem?
    @Published public var isDemoMode: Bool = false

    private let service: WebSyncroServiceProtocol
    private let mockService: WebSyncroServiceProtocol
    private let accountStore: AccountStore
    private var cancellables = Set<AnyCancellable>()

    public init(
        service: WebSyncroServiceProtocol = WebSyncroService.shared,
        mockService: WebSyncroServiceProtocol = MockWebSyncroService(),
        accountStore: AccountStore? = nil
    ) {
        self.service = service
        self.mockService = mockService
        let resolvedStore = accountStore ?? AccountStore.shared
        self.accountStore = resolvedStore

        // Osserva i cambi di account attivo
        resolvedStore.$activeAccountId
            .dropFirst()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)
    }

    public var activeAccount: UserAccount? {
        accountStore.activeAccount
    }

    /// Filtra e ordina gli articoli in base a ricerca, periodo e criterio di ordinamento
    public var filteredItems: [SaleItem] {
        guard let report = report else { return [] }
        var result = report.items

        // Filtro di ricerca per testo o ID
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter { item in
                item.title.lowercased().contains(query) ||
                item.id.lowercased().contains(query) ||
                item.dateString.contains(query)
            }
        }

        // Filtro intervallo temporale
        let now = Date()
        let calendar = Calendar.current
        switch filterRange {
        case .all:
            break
        case .thisMonth:
            result = result.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        case .last90Days:
            if let boundary = calendar.date(byAdding: .day, value: -90, to: now) {
                result = result.filter { $0.date >= boundary }
            }
        }

        // Ordinamento
        switch sortOption {
        case .dateDescending:
            result.sort { $0.date > $1.date }
        case .dateAscending:
            result.sort { $0.date < $1.date }
        case .amountDescending:
            result.sort { $0.amount > $1.amount }
        case .amountAscending:
            result.sort { $0.amount < $1.amount }
        }

        return result
    }

    /// Totale filtrato degli articoli visualizzati
    public var filteredTotalEarned: Decimal {
        filteredItems.reduce(Decimal(0)) { $0 + $1.amount }
    }

    /// Articoli raggruppati per mese/anno
    public var groupedItems: [(section: String, items: [SaleItem])] {
        let items = filteredItems
        let dict = Dictionary(grouping: items) { $0.date.monthYearSection }
        
        // Ordina le sezioni cronologicamente in base alla data del primo elemento
        return dict.map { (section: $0.key, items: $0.value) }
            .sorted { (lhs, rhs) -> Bool in
                guard let firstL = lhs.items.first, let firstR = rhs.items.first else { return false }
                return sortOption == .dateAscending ? firstL.date < firstR.date : firstL.date > firstR.date
            }
    }

    /// Carica i dati per l'account attualmente selezionato
    public func loadData() async {
        guard let account = activeAccount else {
            errorMessage = "Nessun account selezionato. Aggiungi un account per iniziare."
            return
        }

        errorMessage = nil
        let activeService: WebSyncroServiceProtocol = isDemoMode ? mockService : service

        do {
            let fetchedReport = try await activeService.fetchSalesReport(
                shopId: account.shopId,
                userId: account.userId,
                onProgress: { [weak self] status in
                    Task { @MainActor [weak self] in
                        self?.syncStatus = status
                    }
                }
            )

            self.report = fetchedReport
            self.syncStatus = .success(lastSyncDate: Date())

            // Salva l'ultima sincronizzazione riuscita nell'AccountStore
            accountStore.recordSuccessfulSync(
                accountId: account.id,
                totalEarned: fetchedReport.totalEarned,
                snapshotFolder: fetchedReport.syncTimestamp
            )

            HapticFeedback.notification(.success)
        } catch let error as WebSyncroError {
            self.syncStatus = .failure(reason: error.localizedDescription)
            self.errorMessage = error.localizedDescription
            HapticFeedback.notification(.error)
        } catch {
            let msg = error.localizedDescription
            self.syncStatus = .failure(reason: msg)
            self.errorMessage = msg
            HapticFeedback.notification(.error)
        }
    }

    /// Esegue il pull-to-refresh
    public func refresh() async {
        HapticFeedback.impact(.medium)
        await loadData()
    }
}

