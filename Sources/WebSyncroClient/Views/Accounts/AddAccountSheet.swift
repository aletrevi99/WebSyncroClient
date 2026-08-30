import SwiftUI

/// Modale per inserire o modificare i parametri di un account WebSyncro
public struct AddAccountSheet: View {
    @ObservedObject var viewModel: AccountManagerViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: AccountManagerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Card informativa
                        LiquidGlassCard(cornerRadius: 20, padding: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "info.circle")
                                    .font(.title3)
                                    .foregroundColor(.accentColor)

                                Text("Inserisci il codice identificativo del negozio WebSyncro e il tuo ID utente personale per accedere al maturato.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Card Campi Form
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 16) {
                                // Alias Facoltativo
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Nome / Alias Negozio (Opzionale)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)

                                    TextField("Es. Mercatino Centro", text: $viewModel.formAlias)
                                        .font(.body)
                                        .padding(10)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }

                                // Shop ID
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("ID Negozio (Shop ID)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)

                                    #if os(iOS)
                                    TextField("Es. 1042", text: $viewModel.formShopId)
                                        .font(.system(.body, design: .monospaced))
                                        .keyboardType(.numberPad)
                                        .padding(10)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    #else
                                    TextField("Es. 1042", text: $viewModel.formShopId)
                                        .font(.system(.body, design: .monospaced))
                                        .padding(10)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    #endif
                                }

                                // User ID
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("ID Utente (User ID)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)

                                    #if os(iOS)
                                    TextField("Es. 852", text: $viewModel.formUserId)
                                        .font(.system(.body, design: .monospaced))
                                        .keyboardType(.numberPad)
                                        .padding(10)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    #else
                                    TextField("Es. 852", text: $viewModel.formUserId)
                                        .font(.system(.body, design: .monospaced))
                                        .padding(10)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    #endif
                                }

                                // Eventuale errore di validazione
                                if let error = viewModel.formValidationError {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(16)
                }
            }
            .navigationTitle(viewModel.editingAccount == nil ? "Nuovo Account" : "Modifica Account")
            .adaptiveInlineTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        if viewModel.saveAccount() {
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

