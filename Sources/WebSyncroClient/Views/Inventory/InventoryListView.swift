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

/// Schermata per la consultazione e gestione dell'inventario con analisi AI Vision e deduplicazione
public struct InventoryListView: View {
    @ObservedObject var inventoryStore: InventoryStore
    @StateObject private var dashboardViewModel: DashboardViewModel
    @ObservedObject var accountStore: AccountStore
    @ObservedObject var settingsStore: AppSettingsStore

    @State private var selectedFilter: InventoryFilter = .unsold
    @State private var searchText = ""
    @State private var showingCameraScanner = false
    @State private var showingReviewSheet = false
    @State private var scannedBatchForReview: InventoryBatch?
    @State private var currentDeduplicationReport: DeduplicationReport?
    @State private var isProcessingAI = false
    @State private var processingStatusMessage = "Analisi visiva con AI in corso..."
    @State private var saveFeedbackBanner: String?

    #if canImport(PhotosUI)
    @State private var selectedPhotoItem: PhotosPickerItem?
    #endif

    public init(
        inventoryStore: InventoryStore? = nil,
        accountStore: AccountStore? = nil,
        settingsStore: AppSettingsStore? = nil,
        dashboardViewModel: DashboardViewModel? = nil
    ) {
        let store = inventoryStore ?? InventoryStore.shared
        let accStore = accountStore ?? AccountStore.shared
        let setStore = settingsStore ?? AppSettingsStore.shared
        self.inventoryStore = store
        self.accountStore = accStore
        self.settingsStore = setStore
        self._dashboardViewModel = StateObject(wrappedValue: dashboardViewModel ?? DashboardViewModel(accountStore: accStore))
    }

    private var activeShopId: String {
        accountStore.activeAccount?.shopId ?? "exnovomercatino"
    }

    private var activeUserCardCode: String {
        accountStore.activeAccount?.cardCode ?? ""
    }

    private var reconciledList: [(item: InventoryItem, status: InventorySaleStatus)] {
        inventoryStore.reconciledItems(
            maturedReport: dashboardViewModel.maturedReport,
            nonMaturedReport: dashboardViewModel.nonMaturedReport,
            shopId: activeShopId,
            userCardCode: activeUserCardCode
        )
    }

    private var filteredList: [(item: InventoryItem, status: InventorySaleStatus)] {
        reconciledList.filter { entry in
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
            shopId: activeShopId,
            userCardCode: activeUserCardCode
        )
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Banner Feedback Salvataggio Differenziale
                        if let feedback = saveFeedbackBanner {
                            LiquidGlassCard(cornerRadius: 16, padding: 12) {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(feedback)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Button(action: {
                                        withAnimation { saveFeedbackBanner = nil }
                                    }) {
                                        Image(systemName: "xmark")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Hero Card Statistiche Inventario
                        summaryHeroCard

                        // Selettore Rapido Filtri
                        filterChipsView

                        // Barra di Ricerca
                        SearchBarView(text: $searchText)

                        // Contenuto: Lista Articoli o Stato Vuoto
                        if isProcessingAI {
                            LiquidGlassCard(cornerRadius: 22, padding: 24) {
                                VStack(spacing: 14) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                        .tint(Color.brandOrange)
                                    Text(processingStatusMessage)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Text("Estrazione intelligente della tabella e dei prezzi tramite LLM Vision.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.top, 20)
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
                            Label("Scatta Foto con Fotocamera", systemImage: "camera.fill")
                        }

                        #if canImport(PhotosUI)
                        // Selezione dalla Galleria Foto
                        #endif
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                            Text("Carica Foglio")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 12)
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
                if let batch = scannedBatchForReview, let report = currentDeduplicationReport {
                    ScanInventoryReviewSheet(
                        batch: batch,
                        deduplicationReport: report
                    ) { confirmedBatch, overwriteDuplicates in
                        let result = inventoryStore.addBatchWithDeduplication(
                            batch: confirmedBatch,
                            overwriteDuplicates: overwriteDuplicates
                        )

                        withAnimation {
                            if result.skippedCount > 0 {
                                self.saveFeedbackBanner = "Aggiunti \(result.addedCount) nuovi articoli (\(result.skippedCount) duplicati ignorati nel DB)."
                            } else if result.updatedCount > 0 {
                                self.saveFeedbackBanner = "Aggiunti \(result.addedCount) nuovi articoli e aggiornati \(result.updatedCount) articoli esistenti."
                            } else {
                                self.saveFeedbackBanner = "Salvati con successo \(result.addedCount) articoli nel database locale."
                            }
                        }
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
                        Text("\(inventoryStore.batches(for: activeShopId, userCardCode: activeUserCardCode).count) liste")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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

    // MARK: - Riga Articolo Inventario
    @ViewBuilder
    private func inventoryItemRow(_ item: InventoryItem, status: InventorySaleStatus) -> some View {
        LiquidGlassCard(cornerRadius: 20, padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
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

                // Timeline Ciclo di Vita
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
                                Text("Oltre 90 gg (Maggior Realizzo)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.red)
                            }
                        }

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

                // Dettagli Prezzi
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
            .frame(maxWidth: .infinity, alignment: .leading)
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

                    Image(systemName: "sparkles")
                        .font(.system(size: 28))
                        .foregroundColor(.brandOrange)
                }

                VStack(spacing: 4) {
                    Text(inventoryStore.batches(for: activeShopId, userCardCode: activeUserCardCode).isEmpty ? "Nessuna Lista di Carico" : "Nessun Articolo Trovato")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(inventoryStore.batches(for: activeShopId, userCardCode: activeUserCardCode).isEmpty
                        ? "Scatta una foto al foglio 'Lista oggetti in carico': l'AI Vision estrarrà automaticamente articoli, quantità e prezzi nel tuo database locale."
                        : "Nessun articolo corrisponde ai filtri selezionati.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                if inventoryStore.batches(for: activeShopId, userCardCode: activeUserCardCode).isEmpty {
                    Button(action: {
                        showingCameraScanner = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                            Text("Analizza Foglio con AI Vision")
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

    // MARK: - Elaborazione AI Vision
    #if canImport(UIKit)
    private func processScannedImage(_ uiImage: UIImage) {
        guard let jpegData = uiImage.jpegData(compressionQuality: 0.8) else { return }
        isProcessingAI = true
        processingStatusMessage = "Analisi visiva del documento con AI..."

        Task {
            do {
                let visionService = settingsStore.makeVisionService()
                let parsedBatch = try await visionService.analyzeInventoryDocument(
                    imageData: jpegData,
                    shopId: activeShopId,
                    userCardCode: activeUserCardCode
                )

                let deduplication = inventoryStore.analyzeBatchForDuplicates(
                    batch: parsedBatch,
                    shopId: activeShopId,
                    userCardCode: activeUserCardCode
                )

                await MainActor.run {
                    self.scannedBatchForReview = parsedBatch
                    self.currentDeduplicationReport = deduplication
                    self.isProcessingAI = false
                    self.showingReviewSheet = true
                }
            } catch {
                await MainActor.run {
                    self.processingStatusMessage = error.localizedDescription
                    self.isProcessingAI = false
                    HapticFeedback.notification(.error)
                }
            }
        }
    }
    #else
    private func processScannedImage(_ image: Any) {}
    #endif
}
