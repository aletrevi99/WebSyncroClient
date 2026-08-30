import SwiftUI

/// Vista Impostazioni, Diagnostica di Rete e Opzioni di Sviluppo
public struct SettingsView: View {
    @Binding var isDemoMode: Bool
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    public init(isDemoMode: Binding<Bool>, viewModel: SettingsViewModel? = nil) {
        self._isDemoMode = isDemoMode
        _viewModel = StateObject(wrappedValue: viewModel ?? SettingsViewModel())
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Modalità Demo / Dati Simulati
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $isDemoMode) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Modalità Simulazione (Demo)")
                                            .font(.headline)
                                        Text("Utilizza dati locali senza effettuare chiamate di rete ai server WebSyncro")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .tint(.accentColor)
                            }
                        }

                        // Diagnostica di Rete WebSyncro
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Parametri di Rete WebSyncro", systemImage: "network")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Divider()

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("User-Agent Richiesto:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(WebSyncroService.defaultUserAgent)
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(.primary)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Endpoint Base:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(WebSyncroService.baseHost)
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(.primary)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Politica Cache:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("reloadIgnoringLocalAndRemoteCacheData")
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(.primary)
                                }
                            }
                        }

                        // Elenco Snapshot Cartelle SM_... (Test Rete)
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Snapshot Cartelle Negozio")
                                            .font(.headline)
                                        Text("Verifica cartelle SM_... disponibili sul server")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Button(action: {
                                        Task {
                                            await viewModel.fetchAvailableSnapshots()
                                        }
                                    }) {
                                        if viewModel.isLoadingSnapshots {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "arrow.clockwise")
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                    }
                                }

                                if let error = viewModel.snapshotErrorMessage {
                                    Text("Errore: \(error)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }

                                if !viewModel.availableSnapshots.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        ForEach(viewModel.availableSnapshots.prefix(5), id: \.self) { snap in
                                            HStack {
                                                Image(systemName: "folder.fill")
                                                    .foregroundColor(.accentColor)
                                                    .font(.caption)
                                                Text(snap)
                                                    .font(.system(.caption, design: .monospaced))
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }

                        // Info App
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(spacing: 8) {
                                Text("WebSyncro Mercatini Client")
                                    .font(.headline)
                                Text("Versione 1.0.0 (Native Liquid Glass SwiftUI)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        Spacer()
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Impostazioni")
            .adaptiveInlineTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
    }
}

