import SwiftUI

/// Riga per la visualizzazione del singolo articolo venduto/maturato
public struct SaleItemRowView: View {
    let item: SaleItem
    let onTap: (() -> Void)?

    public init(item: SaleItem, onTap: (() -> Void)? = nil) {
        self.item = item
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: {
            HapticFeedback.selection()
            onTap?()
        }) {
            LiquidGlassCard(cornerRadius: 18, padding: 14) {
                HStack(alignment: .center, spacing: 14) {
                    // Icona / Badge tipo articolo
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: "tag.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.accentColor)
                    }

                    // Descrizione e metadati
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.displayTitle)
                            .font(.system(.body, design: .default))
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 8) {
                            Label(item.dateString, systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.6))

                            Text("#\(item.id)")
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.12))
                                .clipShape(Capsule())
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer(minLength: 8)

                    // Importo maturato
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(CurrencyFormatter.format(decimal: item.amount))
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .foregroundColor(.green)

                        Text("Maturato")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

