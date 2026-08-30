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

/// Schermata per la consultazione e gestione dell'inventario con tracciamento quantità, AI Vision, ordinamento avanzato ed editing
public struct InventoryListView: View {
    @ObservedObject var inventoryStore: InventoryStore
    @StateObject private var dashboardViewModel: DashboardViewModel
    @ObservedObject var accountStore: AccountStore
    @ObservedObject var settingsStore: AppSettingsStore

    @State private var selectedFilter: InventoryFilter = .all
    @State private var selectedSortOption: InventorySortOption = .dateDescending
    @State private var searchText = ""

    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var showingFilePicker = false
    @State private var showingReviewSheet = false
    @State private var showingBatchesManager = false
    @State private var showingEditSheet = false

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

    private var filteredAndSortedList: [(item: InventoryItem, status: InventorySaleStatus)] {
        let filtered = reconciledList.filter { entry in
            let matchesCategory: Bool
            switch selectedFilter {
            case .all:
                matchesCategory = true
            case .unsold:
                matchesCategory = entry.status.hasRemainingInShop
            case .sold:
                matchesCategory = entry.status.isFullySold || entry.status.isPartiallySold
            case .discounted:
                matchesCategory = (entry.status.hasRemainingInShop && entry.item.currentStage() == .discounted50)
            case .expiring:
                matchesCategory = (entry.status.hasRemainingInShop && entry.item.currentStage() == .maxRealization)
            }

            let matchesSearch = searchText.isEmpty ||
                entry.item.title.localizedCaseInsensitiveContains(searchText) ||
                entry.item.id.localizedCaseInsensitiveContains(searchText)

            return matchesCategory && matchesSearch
        }

        return inventoryStore.sort(entries: filtered, by: selectedSortOption)
    }

    private var unsoldPiecesCount: Int {
        reconciledList.reduce(0) { $0 + $1.status.remainingInShopCount }
    }

    private var soldPiecesCount: Int {
        reconciledList.reduce(0) { sum, entry in
            switch entry.status {
            case .unsoldInShop:
                return sum
            case .partiallySold(let matured, let nonMatured, _, _, _):
                return sum + matured + nonMatured
            case .fullySold(let matured, let nonMatured, _):
                return sum + matured + nonMatured
            }
        }
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
                            LiquidGlassCard(cornerRadius: 18, padding: 12) {
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

                        // Barra Filtri con Tasto Ordina Fisso a Destra
                        filterAndSortBar

                        // Barra di Ricerca
                        SearchBarView(text: $searchText)

                        // Contenuto: Lista Articoli, Loading AI o Stato Vuoto
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
                        } else if filteredAndSortedList.isEmpty {
                            emptyStateView
                                .padding(.top, 20)
                        } else {
                            ForEach(filteredAndSortedList, id: \.item.id) { entry in
                                inventoryItemRow(entry.item, status: entry.status)
                            }
                        }

                        // Spaziatore per evitare sovrapposizione con la TabBar fluttuante
                        Spacer(minLength: 90)
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
                ToolbarItemGroup(placement: .primaryAction) {
                    // Tasto Matitina (Modifica Inventario) - Stile pulito non arancione
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    // Tasto + Arancione Pulito (Menu Caricamento)
                    uploadMenuToolbarButton
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditInventorySheet(
                    inventoryStore: inventoryStore,
                    accountStore: accountStore
                )
            }
            .sheet(isPresented: $showingCamera) {
                ModernAVCameraView { capturedImage in
                    processCapturedUIImage(capturedImage)
                }
            }
            .sheet(isPresented: $showingFilePicker) {
                FileDocumentPickerView { docData, fileName in
                    processImportedDocumentData(docData, fileName: fileName)
                }
            }
            .sheet(isPresented: $showingBatchesManager) {
                BatchesManagerSheet()
            }
            #if os(iOS)
            .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let item = newItem else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        processCapturedUIImage(img)
                    }
                    selectedPhotoItem = nil
                }
            }
            #endif
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

    // MARK: - Toolbar Upload Button (+ Arancione Pulito)
    @ViewBuilder
    private var uploadMenuToolbarButton: some View {
        Menu {
            Button(action: {
                showingCamera = true
            }) {
                Label("Scatta Foto al Foglio", systemImage: "camera.fill")
            }

            Button(action: {
                showingPhotoPicker = true
            }) {
                Label("Scegli da Galleria Foto", systemImage: "photo.on.rectangle.angled")
            }

            Button(action: {
                showingFilePicker = true
            }) {
                Label("Importa File PDF / Immagine", systemImage: "doc.badge.plus")
            }

            Divider()

            Button(action: {
                showingBatchesManager = true
            }) {
                Label("Archivio Liste di Carico (\(inventoryStore.batches(for: activeShopId, userCardCode: activeUserCardCode).count))", systemImage: "doc.stack.fill")
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.brandOrange)
                .clipShape(Circle())
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

                HStack(spacing: 12) {
                    HStack(spacing: 5) {
                        Image(systemName: "storefront.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("\(unsoldPiecesCount) pz in negozio")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("\(soldPiecesCount) pz venduti")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: {
                        showingBatchesManager = true
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "doc.stack.fill")
                                .font(.caption)
                                .foregroundColor(.brandOrange)
                            Text("\(inventoryStore.batches(for: activeShopId, userCardCode: activeUserCardCode).count) liste")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.brandOrange)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Barra Filtri con Tasto Ordina Fisso a Destra
    @ViewBuilder
    private var filterAndSortBar: some View {
        HStack(spacing: 8) {
            // Scrollview Filtri Categoria
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
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    ZStack {
                                        if isSelected {
                                            Color.brandOrange
                                        } else {
                                            Color.clear
                                        }
                                    }
                                )
                                .background(.ultraThinMaterial)
                                .foregroundColor(isSelected ? .white : .primary)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(isSelected ? Color.brandOrange : Color.white.opacity(0.18), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 2)
            }

            // Tasto Ordina Fisso (Tre Linee Orizzontali / Decrease)
            Menu {
                Picker("Ordinamento", selection: $selectedSortOption) {
                    ForEach(InventorySortOption.allCases) { option in
                        Label(option.rawValue, systemImage: option.iconName)
                            .tag(option)
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(selectedSortOption == .dateDescending ? .primary : .brandOrange)
                    .frame(width: 34, height: 34)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(selectedSortOption == .dateDescending ? Color.white.opacity(0.18) : Color.brandOrange, lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Riga Articolo Inventario con Dimensioni Perfette e Nessuno Sbordamento
    @ViewBuilder
    private func inventoryItemRow(_ item: InventoryItem, status: InventorySaleStatus) -> some View {
        LiquidGlassCard(cornerRadius: 20, padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                // Header: Titolo a sinistra e Badge a destra
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)

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

                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary.opacity(0.5))

                            Text("Qtà: \(item.quantity) pz")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                    }

                    saleStatusBadge(status, item: item)
                        .fixedSize(horizontal: true, vertical: true)
                }

                Divider()
                    .background(Color.white.opacity(0.06))

                // Timeline Ciclo di Vita (solo se ancora presente fisicamente in negozio)
                if status.hasRemainingInShop {
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
                                Text("Tra \(next.days) gg: \(nextStage.rawValue)")
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

                // Dettagli Prezzi (Prezzo Pubblico e Rimborso / Incasso)
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(status.isFullySold ? "Venduto al Pubblico:" : "Prezzo al Pubblico:")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        HStack(spacing: 6) {
                            Text(CurrencyFormatter.format(decimal: item.currentExposedPrice()))
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            if item.currentStage() == .discounted50 && status.hasRemainingInShop {
                                Text(CurrencyFormatter.format(decimal: item.exposedPriceInitial))
                                    .font(.caption2)
                                    .strikethrough()
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        let remaining = status.remainingInShopCount
                        let unitPayout = item.currentClientPayout()

                        if status.isFullySold {
                            Text("Guadagno Netto Realizzato:")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text(CurrencyFormatter.format(decimal: item.totalCurrentClientPayout(for: item.quantity)))
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundColor(.green)
                        } else if status.isPartiallySold {
                            Text("Residuo in Negozio (\(remaining) pz):")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            HStack(spacing: 4) {
                                Text("\(CurrencyFormatter.format(decimal: unitPayout)) cad. •")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Text(CurrencyFormatter.format(decimal: item.totalCurrentClientPayout(for: remaining)))
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                                    .foregroundColor(.brandOrange)
                            }
                        } else {
                            Text(item.quantity > 1 ? "Tuo Rimborso (\(item.quantity) pz):" : "Tuo Rimborso Netto:")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            HStack(spacing: 4) {
                                if item.quantity > 1 {
                                    Text("\(CurrencyFormatter.format(decimal: unitPayout)) cad. •")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Text(CurrencyFormatter.format(decimal: item.totalCurrentClientPayout(for: item.quantity)))
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                                    .foregroundColor(.brandOrange)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func saleStatusBadge(_ status: InventorySaleStatus, item: InventoryItem) -> some View {
        let info = status.badgeInfo(totalItemQuantity: item.quantity)
        let color: Color = info.isSuccess ? .green : (info.isWarning ? .orange : (info.isInfo ? .blue : .primary))

        HStack(spacing: 4) {
            Image(systemName: info.icon)
                .font(.system(size: 9))
            Text(info.text)
                .font(.system(size: 11, weight: .bold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.14))
        .foregroundColor(color)
        .clipShape(Capsule())
    }

    // MARK: - Empty State View con Tutte le Opzioni di Caricamento
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
                        ? "Carica il tuo foglio 'Lista oggetti in carico' per tracciare automaticamente articoli, scadenze sconti e rimborsi nel database locale."
                        : "Nessun articolo corrisponde ai filtri o alla ricerca.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                if inventoryStore.batches(for: activeShopId, userCardCode: activeUserCardCode).isEmpty {
                    VStack(spacing: 10) {
                        // Tasto 1: Fotocamera
                        Button(action: {
                            showingCamera = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                Text("Scatta Foto con Fotocamera")
                            }
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.brandOrange)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }

                        // Tasto 2: Galleria Foto
                        Button(action: {
                            showingPhotoPicker = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("Scegli da Galleria Foto")
                            }
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .foregroundColor(.primary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
                        }

                        // Tasto 3: File / PDF
                        Button(action: {
                            showingFilePicker = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.badge.plus")
                                Text("Importa File PDF o Immagine")
                            }
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .foregroundColor(.primary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Elaborazione AI Vision (Immagini e PDF)
    #if canImport(UIKit)
    private func processCapturedUIImage(_ uiImage: UIImage) {
        guard let jpegData = uiImage.jpegData(compressionQuality: 0.8) else { return }
        executeVisionAnalysis(imageData: jpegData)
    }

    private func processImportedDocumentData(_ data: Data, fileName: String) {
        if fileName.lowercased().hasSuffix(".pdf") {
            if let renderedImage = PDFImageConverter.renderPDFPageToImage(data: data) as? UIImage,
               let jpegData = renderedImage.jpegData(compressionQuality: 0.85) {
                executeVisionAnalysis(imageData: jpegData)
            } else {
                processingStatusMessage = "Impossibile convertire il PDF in immagine"
                HapticFeedback.notification(.error)
            }
        } else if let img = UIImage(data: data), let jpegData = img.jpegData(compressionQuality: 0.8) {
            executeVisionAnalysis(imageData: jpegData)
        }
    }

    private func executeVisionAnalysis(imageData: Data) {
        isProcessingAI = true
        processingStatusMessage = "Analisi visiva del documento con AI..."

        Task {
            do {
                let visionService = settingsStore.makeVisionService()
                let parsedBatch = try await visionService.analyzeInventoryDocument(
                    imageData: imageData,
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
    private func processCapturedUIImage(_ image: Any) {}
    private func processImportedDocumentData(_ data: Data, fileName: String) {}
    #endif
}
