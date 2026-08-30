import SwiftUI

/// Schermata Impostazioni, configurazione modalità EX NOVO, LLM Vision (OpenRouter & Locale) e Diagnostica
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

    private let popularOpenRouterModels = [
        ("google/gemini-2.5-flash", "Gemini 2.5 Flash (Consigliato, Veloce)"),
        ("openai/gpt-4o-mini", "GPT-4o Mini (Alta Precisione)"),
        ("anthropic/claude-3.5-haiku", "Claude 3.5 Haiku"),
        ("qwen/qwen-2.5-vl-72b-instruct", "Qwen 2.5 VL 72B (Open-Source)")
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

                                // Scelta Provider
                                Picker("Provider", selection: $settingsStore.visionProvider) {
                                    Text("OpenRouter API (Cloud)").tag("openrouter")
                                    Text("Modello Locale (Ollama / Local)").tag("local_llm")
                                }
                                .pickerStyle(SegmentedPickerStyle())

                                if settingsStore.visionProvider == "openrouter" {
                                    // Configurazione OpenRouter
                                    VStack(alignment: .leading, spacing: 12) {
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

                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Modello Vision Selezionato")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.secondary)

                                            Picker("Modello", selection: $settingsStore.openRouterModel) {
                                                ForEach(popularOpenRouterModels, id: \.0) { model in
                                                    Text(model.1).tag(model.0)
                                                }
                                            }
                                            .pickerStyle(MenuPickerStyle())
                                            .padding(6)
                                            .background(Color.secondary.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
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
                                    // Configurazione Modello Locale (Ollama)
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
                                            Text("Nome Modello (es. llava:latest o llama3.2-vision)")
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

                        // Sezione 3: Diagnostica e Rete
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Diagnostica & Rete", systemImage: "network")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Divider()

                                detailRow(title: "Endpoint WebSyncro", value: "appwebsyncro.it")
                                detailRow(title: "Negozio Attivo", value: accountStore.activeAccount?.shopId ?? "N/D")
                                detailRow(title: "Account Salvati", value: "\(accountStore.accounts.count)")
                                detailRow(title: "Liste di Carico nel DB", value: "\(inventoryStore.batches.count)")
                                detailRow(title: "Articoli Totali in Inventario", value: "\(inventoryStore.allItems.count)")

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

                        // Sezione 4: Gestione Dati & Reset
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
                            Text("Versione 1.0.0 • OpenRouter Vision & Local LLM")
                                .font(.caption2)
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .padding(.top, 8)

                        Spacer(minLength: 20)
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
                pingOpenRouterStatus = "Connesso con Successo!"
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
