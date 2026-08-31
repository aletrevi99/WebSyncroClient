import SwiftUI

/// Barra di ricerca con effetto Liquid Glass Apple
public struct SearchBarView: View {
    @Binding var text: String
    var placeholder: String = "Cerca per descrizione o ID..."

    public init(text: Binding<String>, placeholder: String = "Cerca per descrizione o ID...") {
        self._text = text
        self.placeholder = placeholder
    }

    public var body: some View {
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
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(in: .rect(cornerRadius: 14))
    }
}
