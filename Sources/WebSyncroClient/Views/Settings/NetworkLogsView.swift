import SwiftUI

/// Vista per consultare in tempo reale lo storico delle chiamate di rete HTTPS
public struct NetworkLogsView: View {
    @ObservedObject private var logStore = NetworkLogStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLog: NetworkCallLog?

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                if logStore.logs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "network.slash")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("Nessuna Chiamata HTTPS Registrata")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Effettua una sincronizzazione o una scansione per visualizzare il traffico di rete.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(logStore.logs) { log in
                                logCard(log)
                            }
                            Spacer(minLength: 30)
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Log Chiamate HTTPS (\(logStore.logs.count))")
            .adaptiveInlineTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    ShareLink(
                        item: logStore.exportLogsAsText(),
                        preview: SharePreview("WebSyncro_HTTPS_Logs.txt", image: Image(systemName: "network"))
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                    }

                    Button(role: .destructive, action: {
                        withAnimation { logStore.clear() }
                        HapticFeedback.notification(.warning)
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func logCard(_ log: NetworkCallLog) -> some View {
        LiquidGlassCard(cornerRadius: 16, padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    // Badge Metodo HTTP
                    Text(log.method)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(log.method == "POST" ? Color.purple.opacity(0.15) : Color.blue.opacity(0.15))
                        .foregroundColor(log.method == "POST" ? .purple : .blue)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    // Badge Status Code
                    if let code = log.statusCode {
                        Text("\(code)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(log.isSuccess ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                            .foregroundColor(log.isSuccess ? .green : .red)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Text("ERR")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    Spacer()

                    // Durata
                    Text("\(log.durationMs) ms")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)

                    // Orario
                    Text(log.formattedTime)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.7))
                }

                // URL Completo
                Text(log.urlString)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                // Snippet o Errore
                if let err = log.errorDescription {
                    Text("Errore: \(err)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.red)
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else if let snippet = log.responseSnippet, !snippet.isEmpty {
                    Text(snippet.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
}
