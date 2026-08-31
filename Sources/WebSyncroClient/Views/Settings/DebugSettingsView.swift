import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Sottomenu dedicato a Debug, Suite di Test, Diagnostica Avanzata, Log HTTPS ed Esportazione Dati
public struct DebugSettingsView: View {
    @ObservedObject var settingsStore: AppSettingsStore
    @ObservedObject var accountStore: AccountStore
    @ObservedObject var inventoryStore: InventoryStore
    @ObservedObject private var networkLogStore = NetworkLogStore.shared

    @State private var pingWebSyncroStatus: String?
    @State private var isPingingWebSyncro = false

    @State private var pingOpenRouterStatus: String?
    @State private var isPingingOpenRouter = false

    @State private var showingFileBrowser = false
    @State private var showingNetworkLogs = false
    @State private var showingResetAlert = false
    @State private var resetConfirmationMessage: String?

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
        ZStack {
            LiquidGlassBackground()

            ScrollView {
                LazyVStack(spacing: 16) {
                    // Feedback Reset o Azioni
                    if let msg = resetConfirmationMessage {
                        LiquidGlassCard(cornerRadius: 16, padding: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(msg)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Spacer()
                                Button(action: {
                                    withAnimation { resetConfirmationMessage = nil }
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    // Sezione 1: Suite di Test & Connessioni
                    LiquidGlassCard(cornerRadius: 22, padding: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Suite Test & Diagnostica", systemImage: "bolt.badge.clock.fill")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Divider()

                            // Test Server WebSyncro
                            HStack {
                                Button(action: {
                                    Task { await testWebSyncroConnection() }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "antenna.radiowaves.left.and.right")
                                            .foregroundColor(.brandOrange)
                                        Text("Test Connessione WebSyncro")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())

                                Spacer()

                                if isPingingWebSyncro {
                                    ProgressView().scaleEffect(0.8)
                                } else if let status = pingWebSyncroStatus {
                                    Text(status)
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(status.contains("OK") ? .green : .red)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .glassEffect(in: .capsule)
                                }
                            }

                            Divider()

                            // Test OpenRouter API
                            HStack {
                                Button(action: {
                                    Task { await testOpenRouterConnection() }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "sparkles")
                                            .foregroundColor(.purple)
                                        Text("Test Autenticazione OpenRouter")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())

                                Spacer()

                                if isPingingOpenRouter {
                                    ProgressView().scaleEffect(0.8)
                                } else if let status = pingOpenRouterStatus {
                                    Text(status)
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(status.contains("OK") ? .green : .red)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .glassEffect(in: .capsule)
                                }
                            }

                            Divider()

                            // Test Notifica Locale Vendita
                            Button(action: {
                                NotificationManager.shared.sendDemoNotification()
                                HapticFeedback.notification(.success)
                                withAnimation {
                                    resetConfirmationMessage = "Notifica di prova inviata con successo!"
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "bell.and.waveform.fill")
                                        .foregroundColor(.brandOrange)
                                    Text("Test Notifica Vendita Demo")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "paperplane.fill")
                                        .font(.caption2)
                                        .foregroundColor(.brandOrange)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                            Divider()

                            // Test Notifica Reso Articolo
                            Button(action: {
                                NotificationManager.shared.simulateDemoReturn()
                                HapticFeedback.notification(.warning)
                                withAnimation {
                                    resetConfirmationMessage = "Simulazione reso attivata (controlla banner in Dashboard)!"
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.arrow.trianglehead.counterclockwise.rotate.90")
                                        .foregroundColor(.red)
                                    Text("Simula Notifica & Allerta Reso")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.red)
                                    Spacer()
                                    Image(systemName: "play.circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                            Divider()

                            // Test Motore Aptico
                            Button(action: {
                                HapticFeedback.impact(.heavy)
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "iphone.radiowaves.left.and.right")
                                        .foregroundColor(.blue)
                                    Text("Test Risposta Aptica (Haptic Engine)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "hand.tap.fill")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    // Sezione 2: Log HTTPS & Traffico di Rete
                    LiquidGlassCard(cornerRadius: 22, padding: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Traffico di Rete & Log", systemImage: "network")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Divider()

                            Button(action: {
                                showingNetworkLogs = true
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "point.3.connected.trianglepath.dotted")
                                        .foregroundColor(.blue)
                                    Text("Log Chiamate HTTPS")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(networkLogStore.logs.count)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.12), in: Capsule())
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    // Sezione 3: Esportazione Dati & File System
                    LiquidGlassCard(cornerRadius: 22, padding: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("File & Esportazione Dati", systemImage: "folder.fill")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Divider()

                            Button(action: {
                                showingFileBrowser = true
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "folder.badge.gearshape")
                                        .foregroundColor(.blue)
                                    Text("Esplora File e Cartelle Sandbox")
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
                                        Text("Esporta Backup Database (.json)")
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

                    // Sezione 4: Dati Runtime & Sistema
                    LiquidGlassCard(cornerRadius: 22, padding: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Informazioni di Sistema", systemImage: "cpu")
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
                            detailRow(title: "Codice Tessera", value: activeUserCardCode.isEmpty ? "N/D" : activeUserCardCode)
                            detailRow(title: "Account Registrati", value: "\(accountStore.accounts.count)")
                            detailRow(title: "Liste Caricate", value: "\(inventoryStore.batches(for: activeShopId, userCardCode: activeUserCardCode).count)")
                            detailRow(title: "Articoli DB", value: "\(inventoryStore.items(for: activeShopId, userCardCode: activeUserCardCode).count)")
                        }
                    }

                    // Sezione 5: Gestione Database & Manutenzione
                    LiquidGlassCard(cornerRadius: 22, padding: 18) {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Zona Manutenzione", systemImage: "trash.fill")
                                .font(.headline)
                                .foregroundColor(.red)

                            Divider()

                            Button(role: .destructive, action: {
                                showingResetAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Svuota Liste Inventario Locali")
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(16)
            }
        }
        .navigationTitle("Debug & Diagnostica")
        .sheet(isPresented: $showingFileBrowser) {
            AppFilesBrowserView()
        }
        .sheet(isPresented: $showingNetworkLogs) {
            NetworkLogsView()
        }
        .alert("Svuotare Inventario?", isPresented: $showingResetAlert) {
            Button("Annulla", role: .cancel) {}
            Button("Svuota", role: .destructive) {
                for batch in inventoryStore.batches {
                    inventoryStore.deleteBatch(id: batch.id)
                }
                withAnimation {
                    resetConfirmationMessage = "Inventario locale svuotato con successo."
                }
                HapticFeedback.notification(.success)
            }
        } message: {
            Text("Verranno rimosse tutte le liste di carico scansionate dal database locale.")
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
            req.httpMethod = "GET"
            req.setValue("Bearer \(settingsStore.openRouterApiKey)", forHTTPHeaderField: "Authorization")
            req.setValue(WebSyncroService.defaultUserAgent, forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                pingOpenRouterStatus = "OK (Autenticato)"
                HapticFeedback.notification(.success)
            } else {
                let err = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String ?? "Errore HTTP"
                pingOpenRouterStatus = "Non valida (\(err))"
                HapticFeedback.notification(.error)
            }
        } catch {
            pingOpenRouterStatus = "Errore: \(error.localizedDescription)"
            HapticFeedback.notification(.error)
        }
        isPingingOpenRouter = false
    }
}
