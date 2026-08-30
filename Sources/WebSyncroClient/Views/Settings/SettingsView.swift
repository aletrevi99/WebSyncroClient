import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Schermata Impostazioni snella, nativa e pulita in stile Apple Liquid Glass
public struct SettingsView: View {
    @ObservedObject var settingsStore: AppSettingsStore
    @ObservedObject var accountStore: AccountStore
    @ObservedObject var inventoryStore: InventoryStore
    @ObservedObject private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var pingOpenRouterStatus: String?
    @State private var isPingingOpenRouter = false

    @State private var isCustomModelSelected: Bool = false
    @State private var customModelText: String = ""

    private let availableModels = [
        ("google/gemini-2.5-flash", "Gemini 2.5 Flash"),
        ("google/gemini-2.0-flash-001", "Gemini 2.0 Flash"),
        ("openai/gpt-4o-mini", "GPT-4o Mini"),
        ("qwen/qwen-2.5-vl-72b-instruct", "Qwen 2.5 VL 72B"),
        ("mistralai/pixtral-12b", "Pixtral 12B")
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
                    VStack(spacing: 16) {
                        // Sezione 1: Modalità Applicazione
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Modalità Negozio", systemImage: "slider.horizontal.3")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Divider()

                                Toggle(isOn: $settingsStore.isExNovoOnlyMode) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Client Esclusivo EX NOVO")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("Ottimizza l'interfaccia nascondendo la selezione di altri negozi.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .tint(Color.brandOrange)
                            }
                        }

                        // Sezione 2: Motore AI Vision
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Motore AI Vision (OpenRouter)", systemImage: "sparkles")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Divider()

                                VStack(alignment: .leading, spacing: 14) {
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
                                            ForEach(availableModels, id: \.0) { model in
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

                                            Divider()

                                            Button(action: {
                                                isCustomModelSelected = true
                                                customModelText = settingsStore.openRouterModel
                                            }) {
                                                HStack {
                                                    Text("Modello personalizzato...")
                                                    if isCustomModelSelected {
                                                        Image(systemName: "checkmark")
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
                            }
                        }

                        // Sezione 3: Preferenze Notifiche & Aggiornamenti
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Notifiche & Background Refresh", systemImage: "bell.badge.fill")
                                    .font(.headline)
                                    .foregroundColor(.brandOrange)

                                if !notificationManager.permissionGranted {
                                    HStack(spacing: 8) {
                                        Image(systemName: "bell.slash.fill")
                                            .foregroundColor(.orange)
                                        Text("Notifiche non ancora consentite nelle impostazioni iOS.")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Button("Consenti") {
                                            Task {
                                                let granted = await notificationManager.requestPermission()
                                                if !granted {
                                                    #if canImport(UIKit)
                                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                                        await UIApplication.shared.open(url)
                                                    }
                                                    #endif
                                                }
                                            }
                                        }
                                        .font(.caption.bold())
                                        .foregroundColor(.brandOrange)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.brandOrange.opacity(0.12))
                                        .clipShape(Capsule())
                                    }
                                    .padding(8)
                                    .background(Color.orange.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }

                                Divider()

                                Toggle("Nuove Vendite in Negozio", isOn: $settingsStore.notifyNewSales)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Toggle("Maturazione Crediti (Pronti al Ritiro)", isOn: $settingsStore.notifyMaturedCredits)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Toggle("Avviso Saldo -50% (Traguardo 60 gg)", isOn: $settingsStore.notifyDiscount50)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Toggle("Scadenza Mandato & Maggior Realizzo (>90 gg)", isOn: $settingsStore.notifyExpiringItems)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Toggle("Avviso Articolo Restituito (Reso)", isOn: $settingsStore.notifyReturns)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Divider()

                                // Frequenza Sincronizzazione in Background
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Controllo in Background")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Text("Frequenza aggiornamento automatico")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Picker("", selection: $settingsStore.backgroundRefreshIntervalMinutes) {
                                        Text("15 min").tag(15)
                                        Text("30 min").tag(30)
                                        Text("1 ora").tag(60)
                                        Text("3 ore").tag(180)
                                        Text("6 ore").tag(360)
                                    }
                                    .pickerStyle(.menu)
                                }
                            }
                        }

                        // Sezione 4: Collegamento Sottomenu Debug & Diagnostica
                        NavigationLink {
                            DebugSettingsView(
                                settingsStore: settingsStore,
                                accountStore: accountStore,
                                inventoryStore: inventoryStore
                            )
                        } label: {
                            LiquidGlassCard(cornerRadius: 20, padding: 16) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.brandOrange.opacity(0.12))
                                            .frame(width: 38, height: 38)
                                        Image(systemName: "wrench.and.screwdriver.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.brandOrange)
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Debug & Diagnostica")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Text("Suite di test, esportazione dati, file browser e reset")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary.opacity(0.7))
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Info Versione
                        VStack(spacing: 4) {
                            Text("WebSyncro Client • EX NOVO AI Edition")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Text("Versione 1.0.0 (Build 2026)")
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
            .onAppear {
                let allPresets = availableModels.map { $0.0 }
                if !allPresets.contains(settingsStore.openRouterModel) {
                    isCustomModelSelected = true
                    customModelText = settingsStore.openRouterModel
                }
            }
        }
    }

    private func displayName(for modelId: String) -> String {
        if let found = availableModels.first(where: { $0.0 == modelId }) {
            return found.1
        }
        return modelId
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
