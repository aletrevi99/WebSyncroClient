import SwiftUI

/// Barra di ricerca in stile Liquid Glass con campo di testo traslucido
public struct SearchBarView: View {
    @Binding var text: String
    var placeholder: String = "Cerca per descrizione o ID..."

    public init(text: Binding<String>, placeholder: String = "Cerca per descrizione o ID...") {
        self._text = text
        self.placeholder = placeholder
    }

    public var body: some View {
        LiquidGlassCard(cornerRadius: 16, padding: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 15, weight: .medium))

                TextField(placeholder, text: $text)
                    .font(.subheadline)
                    .textFieldStyle(PlainTextFieldStyle())

                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        HapticFeedback.selection()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 15))
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
        }
    }
}

