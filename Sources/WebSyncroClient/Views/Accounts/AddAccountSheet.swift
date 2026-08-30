import SwiftUI

/// Modale per inserire o modificare i parametri di un account negozio, anche tramite scansione QR
public struct AddAccountSheet: View {
    @ObservedObject var viewModel: AccountManagerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingQRScanner = false

    public init(viewModel: AccountManagerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        // Pulsante Scansione Codice QR
                        Button(action: {
                            HapticFeedback.selection()
                            showingQRScanner = true
                        }) {
                            LiquidGlassCard(cornerRadius: 20, padding: 16) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.brandOrange.opacity(0.15))
                                            .frame(width: 44, height: 44)

                                        Image(systemName: "qrcode.viewfinder")
                                            .font(.system(size: 22, weight: .semibold))
                                            .foregroundColor(.brandOrange)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Scansiona Codice QR")
                                            .font(.system(.headline, design: .rounded))
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)

                                        Text("Inquadra il QR della tessera per compilare i dati in 1 secondo")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary.opacity(0.6))
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Divisore O Inserimento Manuale
                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.15))
                                .frame(height: 1)
                            Text("OPPURE INSERISCI MANUALMENTE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(0.5)
                            Rectangle()
                                .fill(Color.secondary.opacity(0.15))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 2)

                        // Selezione rapida negozi noti
                        if !viewModel.availableShops.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Seleziona Negozio")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    if viewModel.isShopLocked {
                                        Button("Altro...") {
                                            viewModel.unlockShopSelection()
                                        }
                                        .font(.caption)
                                        .foregroundColor(.brandOrange)
                                    }
                                }
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
                                                .background(isSelected ? Color.brandOrange : Color.secondary.opacity(0.12))
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
                                // Alias Personalizzato
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

                                // Identificativo Negozio (Hardcoded / Bloccato se selezionato dai preset)
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Identificativo Negozio")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)

                                        if viewModel.isShopLocked {
                                            Spacer()
                                            Text("Preimpostato")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.brandOrange)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.brandOrange.opacity(0.12))
                                                .clipShape(Capsule())
                                        }
                                    }

                                    TextField("Identificativo negozio", text: $viewModel.formShopId)
                                        .font(.system(.body, design: .monospaced))
                                        .autocorrectionDisabled(true)
                                        .disabled(viewModel.isShopLocked)
                                        .opacity(viewModel.isShopLocked ? 0.75 : 1.0)
                                        #if os(iOS)
                                        .textInputAutocapitalization(.never)
                                        #endif
                                        .padding(10)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }

                                // Codice Tessera / Username
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Codice Tessera Cliente")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)

                                    TextField("Es. Codice alfanumerico", text: $viewModel.formCardCode)
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
                                    Text("PIN Tessera")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)

                                    #if os(iOS)
                                    TextField("PIN numerico", text: $viewModel.formPin)
                                        .font(.system(.body, design: .monospaced))
                                        .keyboardType(.numberPad)
                                        .padding(10)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    #else
                                    TextField("PIN numerico", text: $viewModel.formPin)
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
                    .foregroundColor(.brandOrange)
                }
            }
            .sheet(isPresented: $showingQRScanner) {
                NavigationStack {
                    ZStack {
                        QRCodeScannerView { code in
                            _ = viewModel.handleScannedQRCode(code)
                        }

                        // Mirino grafico overlay per scansione
                        VStack {
                            Text("Inquadra il codice QR della tua tessera")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .padding(.top, 24)

                            Spacer()
                        }
                    }
                    .navigationTitle("Scansiona QR")
                    .adaptiveInlineTitle()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Chiudi") {
                                showingQRScanner = false
                            }
                            .foregroundColor(.white)
                        }
                    }
                }
            }
        }
    }
}
