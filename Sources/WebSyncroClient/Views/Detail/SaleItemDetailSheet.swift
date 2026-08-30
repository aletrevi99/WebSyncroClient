import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Modale di dettaglio per un singolo articolo venduto con condivisione ed esportazione
public struct SaleItemDetailSheet: View {
    let item: SaleItem
    @Environment(\.dismiss) private var dismiss
    @State private var isCopied = false

    public init(item: SaleItem) {
        self.item = item
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Card Importo Principale
                        LiquidGlassCard(cornerRadius: 24, padding: 24) {
                            VStack(spacing: 8) {
                                Text(item.isNonMatured ? "VENDUTO IN RECESSO" : "IMPORTO MATURATO")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(item.isNonMatured ? .brandOrange : .secondary)
                                    .tracking(1)

                                Text(CurrencyFormatter.format(decimal: item.amount))
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundColor(item.isNonMatured ? .brandOrange : .green)

                                Text(item.isNonMatured ? "Importo in attesa del termine del diritto di recesso" : "Credito disponibile per il ritiro in cassa")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        // Card Dettagli Articolo
                        LiquidGlassCard(cornerRadius: 22, padding: 20) {
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Descrizione Articolo")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)

                                    Text(item.displayTitle)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Divider()

                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("ID Articolo")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("#\(item.id)")
                                            .font(.system(.body, design: .monospaced))
                                            .fontWeight(.bold)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Data Vendita")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(item.dateString)
                                            .font(.body)
                                            .fontWeight(.medium)
                                    }
                                }
                            }
                        }

                        // Azioni Rapide
                        HStack(spacing: 14) {
                            // Copia info negli appunti
                            Button(action: {
                                copyToClipboard()
                            }) {
                                LiquidGlassCard(cornerRadius: 18, padding: 14) {
                                    HStack {
                                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                        Text(isCopied ? "Copiato!" : "Copia Dettagli")
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.brandOrange)
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                            // Condividi
                            ShareLink(
                                item: "Vendita: \(item.displayTitle) (#\(item.id)) - Importo: \(CurrencyFormatter.format(decimal: item.amount)) (\(item.isNonMatured ? "In Recesso" : "Maturato")) in data \(item.dateString)"
                            ) {
                                LiquidGlassCard(cornerRadius: 18, padding: 14) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Condividi")
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        Spacer()
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Dettaglio Vendita")
            .adaptiveInlineTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chiudi") {
                        dismiss()
                    }
                    .foregroundColor(.brandOrange)
                }
            }
        }
    }

    private func copyToClipboard() {
        let status = item.isNonMatured ? "In Recesso" : "Maturato"
        let content = "\(item.displayTitle)\nID: #\(item.id)\nData: \(item.dateString)\nStato: \(status)\nImporto: \(CurrencyFormatter.format(decimal: item.amount))"
        #if os(iOS)
        UIPasteboard.general.string = content
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        #endif
        HapticFeedback.notification(.success)
        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isCopied = false
        }
    }
}
