import SwiftUI

/// Schermata Impostazioni, configurazione modalità EX NOVO e strumenti di Diagnostica/Debug
public struct SettingsView: View {
    @ObservedObject var settingsStore: AppSettingsStore
    @ObservedObject var accountStore: AccountStore
    @ObservedObject var inventoryStore: InventoryStore
    @Environment(\.dismiss) private var dismiss

    @State private var pingStatus: String?
    @State private var isPinging = false
    @State private var showingResetAlert = false

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
                                        Text("Ottimizza l'interfaccia per EX Novo: nasconde la selezione di altri negozi e mostra 'Aggiungi Utente' anziché 'Aggiungi Negozio'.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .tint(Color.brandOrange)
                            }
                        }

                        // Sezione 2: Motore Riconoscimento & OCR
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Motore OCR & Scansione", systemImage: "doc.viewfinder")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Divider()

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Motore Attivo")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Text("Apple Vision 2D Spatial")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.brandOrange)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.brandOrange.opacity(0.12))
                                            .clipShape(Capsule())
                                    }

                                    Text("Riconoscimento su Neural Engine on-device con raggruppamento spaziale 2D delle colonne tabellari (100% offline).")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Divider()

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Chiave API Vision Online / LLM (Opzionale)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)

                                    SecureField("Incolla API key per OCR remoto opzionale", text: $settingsStore.customVisionApiKey)
                                        .font(.system(.body, design: .monospaced))
                                        .padding(10)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }

                        // Sezione 3: Diagnostica e Debug
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Diagnostica & Rete", systemImage: "network")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Divider()

                                detailRow(title: "Endpoint Server", value: "appwebsyncro.it")
                                detailRow(title: "Negozio Attivo", value: accountStore.activeAccount?.shopId ?? "N/D")
                                detailRow(title: "Account Salvati", value: "\(accountStore.accounts.count)")
                                detailRow(title: "Liste di Carico nel DB", value: "\(inventoryStore.batches.count)")
                                detailRow(title: "Articoli in Inventario", value: "\(inventoryStore.allItems.count)")

                                Divider()

                                HStack {
                                    Button(action: {
                                        Task { await testServerConnection() }
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "antenna.radiowaves.left.and.right")
                                            Text("Test Connessione Server")
                                        }
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.brandOrange)
                                    }

                                    Spacer()

                                    if isPinging {
                                        ProgressView().scaleEffect(0.8)
                                    } else if let status = pingStatus {
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
                            Text("WebSyncro Client • EX NOVO Edition")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Text("Versione 1.0.0 (Native Liquid Glass SwiftUI)")
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

    private func testServerConnection() async {
        isPinging = true
        pingStatus = nil
        let start = Date()
        do {
            _ = try await WebSyncroService.shared.fetchShopDirectory()
            let elapsed = Int(Date().timeIntervalSince(start) * 1000)
            pingStatus = "OK (\(elapsed)ms)"
            HapticFeedback.notification(.success)
        } catch {
            pingStatus = "Errore Connessione"
            HapticFeedback.notification(.error)
        }
        isPinging = false
    }
}
