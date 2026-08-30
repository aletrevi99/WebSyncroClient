import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Schermata Impostazioni completa con Selezione Modelli Vision, Diagnostica Avanzata, File Browser ed Esportazione Dati
public struct SettingsView: View {
    @ObservedObject var settingsStore: AppSettingsStore
    @ObservedObject var accountStore: AccountStore
    @ObservedObject var inventoryStore: InventoryStore
    @Environment(\.dismiss) private var dismiss

    @State private var pingWebSyncroStatus: String?
    @State private var isPingingWebSyncro = false

    @State private var pingOpenRouterStatus: String?
    @State private var isPingingOpenRouter = false

    @State private var showingResetAlert = false
    @State private var showingFileBrowser = false
    @State private var showingBatchesManager = false

    @State private var isCustomModelSelected: Bool = false
    @State private var customModelText: String = ""

    private let recommendedModels = [
        ("google/gemini-2.5-flash", "⚡ Gemini 2.5 Flash (Consigliato, ~1s)"),
        ("google/gemini-2.0-flash-001", "⚡ Gemini 2.0 Flash (Super Economico)"),
        ("openai/gpt-4o-mini", "⚡ GPT-4o Mini (Alta Precisione)"),
        ("qwen/qwen-2.5-vl-72b-instruct", "⚡ Qwen 2.5 VL 72B (Open Source)"),
        ("mistralai/pixtral-12b", "⚡ Pixtral 12B (Leggero Open)")
    ]

    private let overkillModels = [
        ("openai/gpt-4o", "⚠️ GPT-4o (Overkill / Più Lento)"),
        ("anthropic/claude-3.5-sonnet", "⚠️ Claude 3.5 Sonnet (Overkill / Costoso)"),
        ("google/gemini-1.5-pro", "⚠️ Gemini 1.5 Pro (Overkill)")
    ]

    public init(
        settingsStore: AppSettingsStore? = nil,
        accountStore: AccountStore? = nil,
        inventoryStore: InventoryStore? = nil
    ) {
        self.settingsStore = settingsStore ?? AppSettingsStore.shared
        self.accountStore = accountStore ?? AccountStore.shared
        self.inventoryStore = inventoryStore ?? InventoryStore.shared
    }

    private var activeShopId: String {
        accountStore.activeAccount?.shopId ?? "exnovomercatino"
    }

    private var activeUserCardCode: String {
        accountStore.activeAccount?.cardCode ?? ""
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Sezione 1: Modalità Applicazione
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Modalità Applicazione", systemImage: "slider.horizontal.3")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Divider()

                                Toggle(isOn: $settingsStore.isExNovoOnlyMode) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Client Esclusivo EX NOVO")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("Ottimizza l'interfaccia per EX Novo: nasconde la selezione di altri negozi e mostra 'Aggiungi Utente'.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .tint(Color.brandOrange)
                            }
                        }

                        // Sezione 2: Motore Analisi Documenti Vision AI
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Motore AI Vision (Scansione Fogli)", systemImage: "sparkles")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Divider()

                                Picker("Provider", selection: $settingsStore.visionProvider) {
                                    Text("OpenRouter API (Cloud)").tag("openrouter")
                                    Text("Modello Locale (Ollama / Local)").tag("local_llm")
                                }
                                .pickerStyle(SegmentedPickerStyle())

                                if settingsStore.visionProvider == "openrouter" {
                                    VStack(alignment: .leading, spacing: 14) {
                                        HStack(alignment: .top, spacing: 10) {
                                            Image(systemName: "lightbulb.fill")
                                                .font(.caption)
                                                .foregroundColor(.brandOrange)
                                            Text("Per la lettura di tabelle e ricevute cartacee, i modelli leggeri (Gemini 2.5 Flash, GPT-4o Mini) sono ideali, istantanei (1-2s) e costano frazioni di centesimo. Modelli come GPT-4o o Sonnet sono overkill e rallentano l'analisi.")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .lineSpacing(2)
                                        }
                                        .padding(10)
                                        .background(Color.brandOrange.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))

                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Chiave API OpenRouter")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.secondary)

                                            SecureField("sk-or-v1-...", text: $settingsStore.openRouterApiKey)
                                                .font(.system(.body, design: .monospaced))
                                                .padding(10)
                                                .background(Color.secondary.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }

                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Modello Vision")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.secondary)

                                            Menu {
                                                Section("⚡ Modelli Consigliati & Leggeri") {
                                                    ForEach(recommendedModels, id: \.0) { model in
                                                        Button(action: {
                                                            settingsStore.openRouterModel = model.0
                                                            isCustomModelSelected = false
                                                        }) {
                                                            HStack {
                                                                Text(model.1)
                                                                if settingsStore.openRouterModel == model.0 && !isCustomModelSelected {
                                                                    Image(systemName: "checkmark")
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                Section("⚠️ Modelli Pesanti (Overkill)") {
                                                    ForEach(overkillModels, id: \.0) { model in
                                                        Button(action: {
                                                            settingsStore.openRouterModel = model.0
                                                            isCustomModelSelected = false
                                                        }) {
                                                            HStack {
                                                                Text(model.1)
                                                                if settingsStore.openRouterModel == model.0 && !isCustomModelSelected {
                                                                    Image(systemName: "checkmark")
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                Section("✏️ Personalizzato") {
                                                    Button(action: {
                                                        isCustomModelSelected = true
                                                        customModelText = settingsStore.openRouterModel
                                                    }) {
                                                        HStack {
                                                            Text("Inserisci ID Modello Personalizzato...")
                                                            if isCustomModelSelected {
                                                                Image(systemName: "checkmark")
                                                            }
                                                        }
                                                    }
                                                }
                                            } label: {
                                                HStack {
                                                    Text(isCustomModelSelected ? "Personalizzato (\(settingsStore.openRouterModel))" : displayName(for: settingsStore.openRouterModel))
                                                        .font(.subheadline)
                                                        .foregroundColor(.primary)
                                                    Spacer()
                                                    Image(systemName: "chevron.up.chevron.down")
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                }
                                                .padding(10)
                                                .background(Color.secondary.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                            }

                                            if isCustomModelSelected {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("Inserisci lo slug del modello OpenRouter:")
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)

                                                    TextField("Es. meta-llama/llama-3.2-11b-vision-instruct", text: $customModelText)
                                                        .font(.system(.caption, design: .monospaced))
                                                        .autocorrectionDisabled(true)
                                                        #if os(iOS)
                                                        .textInputAutocapitalization(.never)
                                                        #endif
                                                        .padding(10)
                                                        .background(Color.secondary.opacity(0.1))
                                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                                        .onChange(of: customModelText) { _, newVal in
                                                            settingsStore.openRouterModel = newVal.trimmingCharacters(in: .whitespaces)
                                                        }
                                                }
                                                .padding(.top, 4)
                                            }
                                        }

                                        HStack {
                                            Button(action: {
                                                Task { await testOpenRouterConnection() }
                                            }) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "bolt.fill")
                                                    Text("Test Chiave OpenRouter")
                                                }
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.brandOrange)
                                            }

                                            Spacer()

                                            if isPingingOpenRouter {
                                                ProgressView().scaleEffect(0.8)
                                            } else if let status = pingOpenRouterStatus {
                                                Text(status)
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(status.contains("OK") ? .green : .red)
                                            }
                                        }
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: 12) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Endpoint Server Locale")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.secondary)

                                            TextField("http://localhost:11434", text: $settingsStore.localModelEndpoint)
                                                .font(.system(.body, design: .monospaced))
                                                .autocorrectionDisabled(true)
                                                #if os(iOS)
                                                .textInputAutocapitalization(.never)
                                                #endif
                                                .padding(10)
                                                .background(Color.secondary.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }

                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Nome Modello (es. llava:latest, llama3.2-vision)")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.secondary)

                                            TextField("llava:latest", text: $settingsStore.localModelName)
                                                .font(.system(.body, design: .monospaced))
                                                .autocorrectionDisabled(true)
                                                #if os(iOS)
                                                .textInputAutocapitalization(.never)
                                                #endif
                                                .padding(10)
                                                .background(Color.secondary.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                    }
                                }
                            }
                        }

                        // Sezione 3: Gestione Liste di Carico & Database Locale
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Archivio Liste di Carico", systemImage: "doc.stack.fill")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("Visualizza l'elenco di tutte le liste caricate, con dettaglio per articolo e statistiche.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Divider()

                                Button(action: {
                                    showingBatchesManager = true
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "list.bullet.rectangle.portrait.fill")
                                            .foregroundColor(.brandOrange)
                                        Text("Anteprima Liste Caricate (\(inventoryStore.batches(for: activeShopId, userCardCode: activeUserCardCode).count))")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        // Sezione 4: Esportazione Dati & File Browser
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Esportazione Dati & File Browser", systemImage: "square.and.arrow.up")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Divider()

                                // File Browser dell'App
                                Button(action: {
                                    showingFileBrowser = true
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "folder.badge.gearshape")
                                            .foregroundColor(.blue)
                                        Text("Esplora File e Cartelle dell'App")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())

                                Divider()

                                if let jsonData = inventoryStore.exportJSONData(),
                                   let jsonString = String(data: jsonData, encoding: .utf8) {
                                    ShareLink(item: jsonString, preview: SharePreview("WebSyncro_Inventario.json", image: Image(systemName: "doc.plaintext"))) {
                                        HStack(spacing: 10) {
                                            Image(systemName: "curlybraces")
                                                .foregroundColor(.brandOrange)
                                            Text("Esporta Database Inventario (.json)")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "square.and.arrow.up")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }

                                Divider()

                                let csvString = inventoryStore.exportCSVData(shopId: activeShopId, userCardCode: activeUserCardCode)
                                ShareLink(item: csvString, preview: SharePreview("WebSyncro_Inventario.csv", image: Image(systemName: "tablecells"))) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "tablecells.fill")
                                            .foregroundColor(.green)
                                        Text("Esporta Tabella Excel / Numbers (.csv)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())

                                Divider()

                                let diagnosticText = inventoryStore.exportDiagnosticReport(shopId: activeShopId, userCardCode: activeUserCardCode)
                                ShareLink(item: diagnosticText, preview: SharePreview("WebSyncro_Report_Diagnostico.txt", image: Image(systemName: "doc.text"))) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "doc.text.magnifyingglass")
                                            .foregroundColor(.brandOrange)
                                        Text("Esporta Report Diagnostico Completo (.txt)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        // Sezione 5: Diagnostica Avanzata & Info Sistema
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Diagnostica Avanzata & Sistema", systemImage: "cpu")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Divider()

                                #if os(iOS)
                                detailRow(title: "Dispositivo", value: UIDevice.current.model)
                                detailRow(title: "Sistema Operativo", value: "iOS \(UIDevice.current.systemVersion)")
                                #endif
                                detailRow(title: "Bundle ID", value: Bundle.main.bundleIdentifier ?? "it.websyncro.client")
                                detailRow(title: "Endpoint WebSyncro", value: "appwebsyncro.it")
                                detailRow(title: "Negozio Attivo", value: activeShopId)
                                detailRow(title: "Codice Tessera Attiva", value: activeUserCardCode.isEmpty ? "N/D" : activeUserCardCode)
                                detailRow(title: "Account Registrati", value: "\(accountStore.accounts.count)")
                                detailRow(title: "Liste Caricate (Questo Utente)", value: "\(inventoryStore.batches(for: activeShopId, userCardCode: activeUserCardCode).count)")
                                detailRow(title: "Articoli in Inventario (Questo Utente)", value: "\(inventoryStore.items(for: activeShopId, userCardCode: activeUserCardCode).count)")

                                Divider()

                                HStack {
                                    Button(action: {
                                        Task { await testWebSyncroConnection() }
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "antenna.radiowaves.left.and.right")
                                            Text("Test Server WebSyncro")
                                        }
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.brandOrange)
                                    }

                                    Spacer()

                                    if isPingingWebSyncro {
                                        ProgressView().scaleEffect(0.8)
                                    } else if let status = pingWebSyncroStatus {
                                        Text(status)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(status.contains("OK") ? .green : .red)
                                    }
                                }
                            }
                        }

                        // Sezione 6: Gestione Dati & Reset
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Gestione Dati Locali", systemImage: "trash")
                                    .font(.headline)
                                    .foregroundColor(.red)

                                Divider()

                                Button(role: .destructive, action: {
                                    showingResetAlert = true
                                }) {
                                    Text("Svuota Liste Inventario Locali")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        // Info Versione
                        VStack(spacing: 4) {
                            Text("WebSyncro Client • EX NOVO AI Edition")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Text("Versione 1.0.0 (Build 2026) • OpenRouter Vision & Local LLM")
                                .font(.caption2)
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .padding(.top, 8)

                        Spacer(minLength: 40)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Impostazioni")
            .adaptiveInlineTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chiudi") { dismiss() }
                        .foregroundColor(.brandOrange)
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingFileBrowser) {
                AppFilesBrowserView()
            }
            .sheet(isPresented: $showingBatchesManager) {
                BatchesManagerSheet()
            }
            .onAppear {
                let allPresets = (recommendedModels + overkillModels).map { $0.0 }
                if !allPresets.contains(settingsStore.openRouterModel) {
                    isCustomModelSelected = true
                    customModelText = settingsStore.openRouterModel
                }
            }
            .alert("Svuotare Inventario?", isPresented: $showingResetAlert) {
                Button("Annulla", role: .cancel) {}
                Button("Svuota", role: .destructive) {
                    for batch in inventoryStore.batches {
                        inventoryStore.deleteBatch(id: batch.id)
                    }
                }
            } message: {
                Text("Verranno rimosse tutte le liste di carico scansionate dal database locale.")
            }
        }
    }

    private func displayName(for modelId: String) -> String {
        if let found = (recommendedModels + overkillModels).first(where: { $0.0 == modelId }) {
            return found.1
        }
        return modelId
    }

    @ViewBuilder
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }

    private func testWebSyncroConnection() async {
        isPingingWebSyncro = true
        pingWebSyncroStatus = nil
        let start = Date()
        do {
            _ = try await WebSyncroService.shared.fetchShopDirectory()
            let elapsed = Int(Date().timeIntervalSince(start) * 1000)
            pingWebSyncroStatus = "OK (\(elapsed)ms)"
            HapticFeedback.notification(.success)
        } catch {
            pingWebSyncroStatus = "Errore Connessione"
            HapticFeedback.notification(.error)
        }
        isPingingWebSyncro = false
    }

    private func testOpenRouterConnection() async {
        isPingingOpenRouter = true
        pingOpenRouterStatus = nil
        do {
            guard !settingsStore.openRouterApiKey.isEmpty else {
                pingOpenRouterStatus = "Chiave API mancante"
                isPingingOpenRouter = false
                return
            }
            guard let url = URL(string: "https://openrouter.ai/api/v1/auth/key") else { return }
            var req = URLRequest(url: url)
            req.setValue("Bearer \(settingsStore.openRouterApiKey)", forHTTPHeaderField: "Authorization")
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                pingOpenRouterStatus = "OK (Autenticato)"
                HapticFeedback.notification(.success)
            } else {
                let err = String(data: data, encoding: .utf8) ?? "Errore chiave"
                pingOpenRouterStatus = "Non valida (\(err))"
                HapticFeedback.notification(.error)
            }
        } catch {
            pingOpenRouterStatus = "Errore: \(error.localizedDescription)"
        }
        isPingingOpenRouter = false
    }
}
