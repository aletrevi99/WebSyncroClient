import SwiftUI

/// Schermata della Tessera / Card Fornitore con codice a barre ad alta risoluzione
public struct UserCardView: View {
    @ObservedObject var accountStore: AccountStore

    public init(accountStore: AccountStore? = nil) {
        self.accountStore = accountStore ?? AccountStore.shared
    }

    private var activeAccount: UserAccount? {
        accountStore.activeAccount
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Card Fornitore in stile Liquid Glass
                    cardWidget

                    // Informazioni di utilizzo
                    LiquidGlassCard(cornerRadius: 20, padding: 16) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.title2)
                                .foregroundColor(.brandOrange)
                                .padding(.top, 2)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Riconoscimento in Cassa")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("Mostra questo codice a barre all'operatore di cassa del mercatino per caricare nuovi oggetti in conto vendita o ritirare i tuoi guadagni maturati.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Dettagli Account Attivo
                    if let account = activeAccount {
                        LiquidGlassCard(cornerRadius: 20, padding: 16) {
                            VStack(spacing: 12) {
                                HStack {
                                    Label("Dettagli Tessera", systemImage: "person.crop.circle.fill")
                                        .font(.headline)
                                    Spacer()
                                }

                                Divider()

                                detailRow(title: "Codice Tessera", value: account.cardCode.isEmpty ? (account.userId.isEmpty ? "N/D" : account.userId) : account.cardCode)
                                detailRow(title: "Negozio Associato", value: account.shopId)
                                if !account.pin.isEmpty {
                                    detailRow(title: "PIN Configurato", value: "••••")
                                }
                                if let lastSync = account.lastSyncDate {
                                    detailRow(title: "Ultima Sincronizzazione", value: formattedDate(lastSync))
                                }
                            }
                        }
                    }

                    // Spaziatore per evitare sovrapposizione con la TabBar fluttuante
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(LiquidGlassBackground())
            .navigationTitle("Card")
        }
    }

    // MARK: - Widget Grafico della Tessera
    @ViewBuilder
    private var cardWidget: some View {
        let shopName = (activeAccount?.accountAlias.isEmpty == false) ? (activeAccount?.accountAlias ?? "MERCATINO") : (activeAccount?.shopId.uppercased() ?? "MERCATINO")
        let code = (activeAccount?.cardCode.isEmpty == false) ? (activeAccount?.cardCode ?? "000000") : (activeAccount?.userId.isEmpty == false ? (activeAccount?.userId ?? "000000") : "000000")

        VStack(spacing: 0) {
            // Testata arancione ufficiale del brand
            VStack(spacing: 4) {
                Text("CARD FORNITORE")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1.5)

                Text(shopName.uppercased())
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.brandOrangeGradientStart, Color.brandOrangeGradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Corpo bianco con Codice a Barre ad alta nitidezza
            VStack(spacing: 12) {
                if let barcodeImage = BarcodeGenerator.generateCode128(from: code) {
                    barcodeImage
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(height: 110)
                        .padding(.horizontal, 12)
                        .padding(.top, 16)
                } else {
                    Image(systemName: "barcode")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .padding(.top, 16)
                }

                // Codice alfanumerico in evidenza
                Text(code)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .tracking(3)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
