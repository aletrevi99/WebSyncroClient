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
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "person.badge.key.fill")
                                    .font(.title3)
                                    .foregroundColor(.accentColor)
                                    .padding(.top, 2)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Credenziali WebSyncro")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Seleziona o digita il negozio del mercatino, inserisci il codice alfanumerico della tua tessera cliente (es. TRE091) e il tuo PIN numerico (es. 1762).")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        // Selezione rapida negozi noti
                        if !viewModel.availableShops.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Negozi Riconosciuti WebSyncro")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(viewModel.availableShops) { shop in
                                            let isSelected = viewModel.formShopId.caseInsensitiveCompare(shop.slug) == .orderedSame

                                            Button(action: {
                                                viewModel.selectKnownShop(shop)
                                            }) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "storefront.fill")
                                                        .font(.caption2)
                                                    Text(shop.name)
                                                        .font(.system(.caption, design: .rounded))
                                                        .fontWeight(.semibold)
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
                                                .foregroundColor(isSelected ? .white : .primary)
                                                .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Card Campi Form
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 16) {
                                // Alias Facoltativo
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Nome / Alias Personalizzato (Opzionale)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)

                                    TextField("Es. EX Novo Mercatino", text: $viewModel.formAlias)
                                        .font(.body)
                                        .padding(10)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }

                                // Shop ID / Slug
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Identificativo Negozio (Shop ID)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)

                                    TextField("Es. exnovomercatino", text: $viewModel.formShopId)
                                        .font(.system(.body, design: .monospaced))
                                        .autocorrectionDisabled(true)
                                        #if os(iOS)
                                        .textInputAutocapitalization(.never)
                                        #endif
                                        .padding(10)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }

                                // Codice Tessera / Username
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Codice Tessera Cliente (Username)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)

                                    TextField("Es. TRE091", text: $viewModel.formCardCode)
                                        .font(.system(.body, design: .monospaced))
                                        .autocorrectionDisabled(true)
                                        #if os(iOS)
                                        .textInputAutocapitalization(.characters)
                                        #endif
                                        .padding(10)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }

                                // PIN
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("PIN Tessera (Numerico)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)

                                    #if os(iOS)
                                    TextField("Es. 1762", text: $viewModel.formPin)
                                        .font(.system(.body, design: .monospaced))
                                        .keyboardType(.numberPad)
                                        .padding(10)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    #else
                                    TextField("Es. 1762", text: $viewModel.formPin)
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
