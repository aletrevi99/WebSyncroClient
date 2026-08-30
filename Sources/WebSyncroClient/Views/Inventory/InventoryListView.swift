import SwiftUI
#if canImport(PhotosUI)
import PhotosUI
#endif

/// Filtro di visualizzazione inventario
public enum InventoryFilter: String, CaseIterable, Identifiable {
    case all = "Tutti"
    case unsold = "In Negozio"
    case sold = "Venduti"
    case discounted = "In Saldo (-50%)"
    case expiring = "Scaduti (>90gg)"

    public var id: String { rawValue }
}

/// Schermata per la consultazione e gestione dell'inventario degli oggetti in carico con sconti e riconciliazione vendite
public struct InventoryListView: View {
    @ObservedObject var inventoryStore: InventoryStore
    @StateObject private var dashboardViewModel: DashboardViewModel
    @ObservedObject var accountStore: AccountStore

    @State private var selectedFilter: InventoryFilter = .unsold
    @State private var searchText = ""
    @State private var showingCameraScanner = false
    @State private var showingReviewSheet = false
    @State private var scannedBatchForReview: InventoryBatch?
    @State private var isProcessingOCR = false
    @State private var ocrErrorMessage: String?

    #if canImport(PhotosUI)
    @State private var selectedPhotoItem: PhotosPickerItem?
    #endif

    public init(
        inventoryStore: InventoryStore? = nil,
        accountStore: AccountStore? = nil,
        dashboardViewModel: DashboardViewModel? = nil
    ) {
        let store = inventoryStore ?? InventoryStore.shared
        let accStore = accountStore ?? AccountStore.shared
        self.inventoryStore = store
        self.accountStore = accStore
        self._dashboardViewModel = StateObject(wrappedValue: dashboardViewModel ?? DashboardViewModel(accountStore: accStore))
    }

    private var activeShopId: String {
        accountStore.activeAccount?.shopId ?? "exnovomercatino"
    }

    private var reconciledList: [(item: InventoryItem, status: InventorySaleStatus)] {
        inventoryStore.reconciledItems(
            maturedReport: dashboardViewModel.maturedReport,
            nonMaturedReport: dashboardViewModel.nonMaturedReport,
            shopIdFilter: activeShopId
        )
    }

    private var filteredList: [(item: InventoryItem, status: InventorySaleStatus)] {
        reconciledList.filter { entry in
            // Filtro per tab
            let matchesCategory: Bool
            switch selectedFilter {
            case .all:
                matchesCategory = true
            case .unsold:
                matchesCategory = (entry.status == .unsoldInShop)
            case .sold:
                matchesCategory = entry.status.isSold
            case .discounted:
                matchesCategory = (entry.status == .unsoldInShop && entry.item.currentStage() == .discounted50)
            case .expiring:
                matchesCategory = (entry.status == .unsoldInShop && entry.item.currentStage() == .maxRealization)
            }

            // Filtro per testo
            let matchesSearch = searchText.isEmpty ||
                entry.item.title.localizedCaseInsensitiveContains(searchText) ||
                entry.item.id.localizedCaseInsensitiveContains(searchText)

            return matchesCategory && matchesSearch
        }
    }

    private var unsoldCount: Int {
        reconciledList.filter { $0.status == .unsoldInShop }.count
    }

    private var soldCount: Int {
        reconciledList.filter { $0.status.isSold }.count
    }

    private var estimatedUnsoldTotal: Decimal {
        inventoryStore.estimatedUnsoldValue(
            maturedReport: dashboardViewModel.maturedReport,
            nonMaturedReport: dashboardViewModel.nonMaturedReport,
            shopIdFilter: activeShopId
        )
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Hero Card Statistiche Inventario
                        summaryHeroCard

                        // Selettore Rapido Filtri
                        filterChipsView

                        // Barra di Ricerca
                        SearchBarView(text: $searchText)

                        // Contenuto: Lista Articoli o Stato Vuoto
                        if isProcessingOCR {
                            EmptyOrErrorView(type: .loading(message: "Analisi OCR della lista di carico in corso..."))
                                .padding(.top, 30)
                        } else if filteredList.isEmpty {
                            emptyStateView
                                .padding(.top, 20)
                        } else {
                            ForEach(filteredList, id: \.item.id) { entry in
                                inventoryItemRow(entry.item, status: entry.status)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .refreshable {
                    await dashboardViewModel.refresh()
                }
            }
            .navigationTitle("Inventario")
            .adaptiveLargeTitle()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: {
                            showingCameraScanner = true
                        }) {
                            Label("Scansiona con Fotocamera", systemImage: "camera.viewfinder")
                        }

                        #if canImport(PhotosUI)
                        // Selezione da Galleria
                        #endif
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("Aggiungi Lista")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.brandOrange)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                }
            }
            .sheet(isPresented: $showingCameraScanner) {
                DocumentCameraScannerView { scannedImage in
                    processScannedImage(scannedImage)
                }
            }
            .sheet(isPresented: $showingReviewSheet) {
                if let batch = scannedBatchForReview {
                    ScanInventoryReviewSheet(batch: batch) { confirmedBatch in
                        inventoryStore.addBatch(confirmedBatch)
                    }
                }
            }
            .task {
                if dashboardViewModel.maturedReport == nil {
                    await dashboardViewModel.loadData()
                }
            }
        }
    }

    // MARK: - Summary Hero Card
    @ViewBuilder
    private var summaryHeroCard: some View {
        LiquidGlassCard(cornerRadius: 24, padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("VALORE RESIDUO IN NEGOZIO")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.brandOrange)
                        .tracking(0.5)

                    Text("Stima incasso su merce ancora esposta")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(CurrencyFormatter.format(decimal: estimatedUnsoldTotal))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.primary)

                    Spacer()
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "storefront.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("\(unsoldCount) in negozio")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("\(soldCount) venduti")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: "doc.plaintext")
                            .font(.caption)
                            .foregroundColor(.brandOrange)
                        Text("\(inventoryStore.batches.count) liste caricate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Filtri Rapidi
    @ViewBuilder
    private var filterChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(InventoryFilter.allCases) { filter in
                    let isSelected = selectedFilter == filter
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    }) {
                        Text(filter.rawValue)
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(isSelected ? .bold : .medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.brandOrange : Color.secondary.opacity(0.12))
                            .foregroundColor(isSelected ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Riga Articolo Inventario con Sconti e Timeline
    @ViewBuilder
    private func inventoryItemRow(_ item: InventoryItem, status: InventorySaleStatus) -> some View {
        LiquidGlassCard(cornerRadius: 20, padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                // Header Riga: ID, Titolo e Badge Stato Vendita
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.system(.subheadline, design: .default))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            Text("#\(item.id)")
                                .font(.system(.caption2, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)

                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary.opacity(0.5))

                            Text("Carico: \(item.formattedLoadDate)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    saleStatusBadge(status)
                }

                Divider()
                    .background(Color.white.opacity(0.06))

                // Timeline Ciclo di Vita (0-60gg, 61-90gg, >90gg)
                if status == .unsoldInShop {
                    let days = item.daysSinceLoad()
                    let stage = item.currentStage()
                    let next = item.daysUntilNextStage()

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Esposizione: \(days) gg trascorsi")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Spacer()

                            if let nextStage = next.nextStage {
                                Text("-\(next.days) gg a \(nextStage.rawValue)")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.brandOrange)
                            } else {
                                Text("Oltre i 90 gg (Maggior Realizzo)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.red)
                            }
                        }

                        // Barra grafica di progresso 90 giorni
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.secondary.opacity(0.15))
                                    .frame(height: 6)

                                Capsule()
                                    .fill(stage == .fullPrice ? Color.green : (stage == .discounted50 ? Color.orange : Color.red))
                                    .frame(width: proxy.size.width * CGFloat(item.lifecycleProgress()), height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                }

                // Dettagli Prezzi (Esposto & Rimborso Cliente)
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Prezzo al Pubblico:")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        HStack(spacing: 6) {
                            Text(CurrencyFormatter.format(decimal: item.currentExposedPrice()))
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            if item.currentStage() == .discounted50 && status == .unsoldInShop {
                                Text(CurrencyFormatter.format(decimal: item.exposedPriceInitial))
                                    .font(.caption2)
                                    .strikethrough()
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(status == .unsoldInShop ? "Tuo Rimborso Netto:" : "Importo Realizzato:")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(CurrencyFormatter.format(decimal: item.currentClientPayout()))
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .foregroundColor(status.isSold ? .green : .brandOrange)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func saleStatusBadge(_ status: InventorySaleStatus) -> some View {
        switch status {
        case .soldMatured(let date, _):
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption2)
                Text("Maturato (\(date))")
                    .font(.system(size: 11, weight: .bold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.15))
            .foregroundColor(.green)
            .clipShape(Capsule())

        case .soldInRecesso(let date, _):
            HStack(spacing: 4) {
                Image(systemName: "hourglass")
                    .font(.caption2)
                Text("In Recesso (\(date))")
                    .font(.system(size: 11, weight: .bold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.brandOrange.opacity(0.15))
            .foregroundColor(.brandOrange)
            .clipShape(Capsule())

        case .unsoldInShop:
            HStack(spacing: 4) {
                Image(systemName: "storefront.fill")
                    .font(.caption2)
                Text("In Negozio")
                    .font(.system(size: 11, weight: .semibold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.12))
            .foregroundColor(.blue)
            .clipShape(Capsule())
        }
    }

    // MARK: - Empty State View
    @ViewBuilder
    private var emptyStateView: some View {
        LiquidGlassCard(cornerRadius: 22, padding: 24) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.brandOrange.opacity(0.15))
                        .frame(width: 60, height: 60)

                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 28))
                        .foregroundColor(.brandOrange)
                }

                VStack(spacing: 4) {
                    Text(inventoryStore.batches.isEmpty ? "Nessuna Lista di Carico" : "Nessun Articolo Trovato")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(inventoryStore.batches.isEmpty
                        ? "Scatta una foto al foglio 'Lista oggetti in carico' rilasciato dal mercatino per sincronizzare tutti i tuoi articoli ed i prezzi scontati."
                        : "Nessun articolo corrisponde ai filtri selezionati.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                if inventoryStore.batches.isEmpty {
                    Button(action: {
                        showingCameraScanner = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                            Text("Scansiona Lista Foglio Carico")
                        }
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Color.brandOrange)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                    .padding(.top, 6)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Elaborazione OCR
    #if canImport(UIKit)
    private func processScannedImage(_ uiImage: UIImage) {
        guard let cgImage = uiImage.cgImage else { return }
        isProcessingOCR = true
        ocrErrorMessage = nil

        Task {
            do {
                let recognizedText = try await OCRManager.recognizeText(from: cgImage)
                let parsedResult = InventoryOCRParser.parse(ocrText: recognizedText, shopId: activeShopId)

                let batch = InventoryBatch(
                    listNumber: parsedResult.listNumber,
                    loadDate: parsedResult.loadDate,
                    shopId: activeShopId,
                    totalPieces: parsedResult.totalPieces,
                    totalAgreedValue: parsedResult.totalAgreedValue,
                    totalExposedValue: parsedResult.totalExposedValue,
                    items: parsedResult.items
                )

                await MainActor.run {
                    self.scannedBatchForReview = batch
                    self.isProcessingOCR = false
                    self.showingReviewSheet = true
                }
            } catch {
                await MainActor.run {
                    self.ocrErrorMessage = error.localizedDescription
                    self.isProcessingOCR = false
                }
            }
        }
    }
    #else
    private func processScannedImage(_ image: Any) {}
    #endif
}

