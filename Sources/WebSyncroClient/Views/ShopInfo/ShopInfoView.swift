import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Vista informativa di alto livello con identità visiva del mercatino, orari live, bio e recapiti
public struct ShopInfoView: View {
    let shopId: String
    @State private var shopDetails: ShopDetails?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingMandateSheet: Bool = false
    @State private var showingSettingsSheet: Bool = false
    @State private var showingMapsDialog: Bool = false
    @Environment(\.openURL) private var openURL

    private let service: WebSyncroServiceProtocol

    public init(
        shopId: String,
        service: WebSyncroServiceProtocol = WebSyncroService.shared
    ) {
        self.shopId = shopId
        self.service = service
    }

    private var isExNovoShop: Bool {
        shopId.lowercased().contains("exnovo") ||
        (shopDetails?.name.lowercased().contains("ex novo") ?? false)
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                LiquidGlassBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        // Spaziatore per far iniziare il contenuto sotto l'header fisso
                        Color.clear.frame(height: 50)

                        // Card Principale: Identità Visiva, Bio e Tasti Azione Rapida
                        shopHeroCard

                        // Card Stato Apertura Oggi in Tempo Reale
                        if let shop = shopDetails {
                            liveStatusCard(shop: shop)
                        }

                        // Card Orari della Settimana
                        weeklyScheduleCard

                        // Card Dati Negozio & Sede Completa (in basso sotto gli orari)
                        if let shop = shopDetails {
                            shopDetailsBottomCard(shop: shop)
                        }

                        // Card Espandibile: Come Funziona il Conto Vendita & Regolamento Recesso
                        howItWorksCard

                        // Spaziatore per evitare sovrapposizione con la TabBar fluttuante
                        Spacer(minLength: 90)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                }

                // Pinned Header Bar
                pinnedShopHeaderBar
            }
            #if canImport(UIKit)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .confirmationDialog("Scegli applicazione Mappe", isPresented: $showingMapsDialog, titleVisibility: .visible) {
                if let address = shopDetails?.fullAddress,
                   let encodedAddr = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {

                    Button("Apple Maps") {
                        if let appleURL = URL(string: "http://maps.apple.com/?q=\(encodedAddr)") {
                            openURL(appleURL)
                        }
                    }

                    Button("Google Maps") {
                        #if canImport(UIKit)
                        if let googleURL = URL(string: "comgooglemaps://?q=\(encodedAddr)"),
                           UIApplication.shared.canOpenURL(googleURL) {
                            openURL(googleURL)
                            return
                        }
                        #endif
                        if let webGoogle = URL(string: "https://maps.google.com/?q=\(encodedAddr)") {
                            openURL(webGoogle)
                        }
                    }
                }
                Button("Annulla", role: .cancel) {}
            }
            .sheet(isPresented: $showingMandateSheet) {
                MandateClausesView()
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView()
            }
            .task {
                await loadShopDetails()
            }
        }
    }

    // MARK: - Header Pinned Liquid Glass
    @ViewBuilder
    private var pinnedShopHeaderBar: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text("Negozio")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                Button(action: {
                    HapticFeedback.selection()
                    showingSettingsSheet = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.brandOrange)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.brandOrange.opacity(0.4), lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 10)
            .background(
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                    Rectangle()
                        .fill(Color.primary.opacity(0.02))
                }
                .ignoresSafeArea(edges: .top)
            )
            .overlay(
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 0.8),
                alignment: .bottom
            )
        }
    }

    // MARK: - Hero Card Principale
    @ViewBuilder
    private var shopHeroCard: some View {
        LiquidGlassCard(cornerRadius: 24, padding: 20) {
            VStack(spacing: 16) {
                // Logo o Icona Negozio
                if isExNovoShop {
                    VStack(spacing: 8) {
                        #if canImport(UIKit)
                        if let uiImage = UIImage(named: "exnovo_logo") {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 38)
                                .padding(.vertical, 4)
                        } else {
                            fallbackLogoView
                        }
                        #else
                        fallbackLogoView
                        #endif

                        Text("SECONDA MANO • PRIMO AMORE")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.brandOrange)
                            .tracking(1.8)
                    }
                } else {
                    fallbackLogoView
                }

                // Bio / Descrizione del Mercatino
                Text("Mercatino dell'usato selezionato. Dai una seconda vita ai tuoi oggetti: esponi i tuoi articoli in conto vendita e scopri abbigliamento, libri, oggettistica e arredamento a prezzi vantaggiosi.")
                    .font(.system(.subheadline, design: .default))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 4)

                Divider()
                    .background(Color.white.opacity(0.1))

                // Pulsanti Azioni Rapide (Chiama, Email, Sito Web, Mappa)
                if let shop = shopDetails {
                    HStack(spacing: 8) {
                        if !shop.phone.isEmpty, let telURL = URL(string: "tel:\(shop.cleanPhoneNumber)") {
                            Link(destination: telURL) {
                                contactButton(icon: "phone.fill", text: "Chiama", color: .green)
                            }
                        }

                        if !shop.email.isEmpty, let mailURL = URL(string: "mailto:\(shop.email)") {
                            Link(destination: mailURL) {
                                contactButton(icon: "envelope.fill", text: "Email", color: .blue)
                            }
                        }

                        if !shop.website.isEmpty, let webURL = URL(string: shop.website) {
                            Link(destination: webURL) {
                                contactButton(icon: "globe", text: "Sito Web", color: .brandOrange)
                            }
                        }

                        if !shop.fullAddress.isEmpty {
                            Button(action: {
                                showingMapsDialog = true
                            }) {
                                contactButton(icon: "map.fill", text: "Mappa", color: .purple)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var fallbackLogoView: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.brandOrange.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "storefront.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.brandOrange)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(shopDetails?.name ?? shopId.capitalized)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Mercatino dell'Usato")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func liveStatusCard(shop: ShopDetails) -> some View {
        let status = shop.currentOpenStatus
        LiquidGlassCard(cornerRadius: 20, padding: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(status.isOpen ? Color.green.opacity(0.15) : (status.statusText.contains("PAUSA") ? Color.orange.opacity(0.15) : Color.secondary.opacity(0.15)))
                        .frame(width: 44, height: 44)

                    Image(systemName: status.isOpen ? "clock.badge.checkmark.fill" : "clock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(status.isOpen ? .green : (status.statusText.contains("PAUSA") ? .orange : .secondary))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(status.statusText)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(status.isOpen ? .green : (status.statusText.contains("PAUSA") ? .orange : .primary))

                    Text(status.detailText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var weeklyScheduleCard: some View {
        LiquidGlassCard(cornerRadius: 22, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Orari di Apertura", systemImage: "calendar")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }

                Divider()

                if let error = errorMessage {
                    Text("Impossibile caricare gli orari: \(error)")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else if let info = shopDetails, !info.schedule.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(info.schedule) { day in
                            let isToday = info.todaySchedule?.id == day.id

                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(day.dayName)
                                            .font(.subheadline)
                                            .fontWeight(isToday ? .bold : .medium)
                                            .foregroundColor(isToday ? .brandOrange : .primary)

                                        if isToday {
                                            Text("OGGI")
                                                .font(.system(size: 9, weight: .bold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.brandOrange.opacity(0.15))
                                                .foregroundColor(.brandOrange)
                                                .clipShape(Capsule())
                                        }
                                    }

                                    Text(day.formattedHours)
                                        .font(.caption)
                                        .foregroundColor(day.isClosed ? .secondary : .primary)
                                }

                                Spacer()

                                if isToday {
                                    let openNow = info.currentOpenStatus.isOpen
                                    Text(openNow ? "Aperto Adesso" : (day.isClosed ? "Chiuso" : "Chiuso Ora"))
                                        .font(.system(size: 11, weight: .bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(openNow ? Color.green.opacity(0.15) : Color.secondary.opacity(0.12))
                                        .foregroundColor(openNow ? .green : .secondary)
                                        .clipShape(Capsule())
                                } else if day.isClosed {
                                    Text("Chiuso")
                                        .font(.system(size: 11, weight: .semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.secondary.opacity(0.12))
                                        .foregroundColor(.secondary)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.vertical, isToday ? 6 : 2)
                            .padding(.horizontal, isToday ? 8 : 0)
                            .background(isToday ? Color.brandOrange.opacity(0.06) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            if day.id < 6 {
                                Divider()
                                    .background(Color.white.opacity(0.06))
                            }
                        }
                    }
                } else {
                    Text("Orari non disponibili al momento.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Box Info & Sede Negozio (Sotto gli orari)
    @ViewBuilder
    private func shopDetailsBottomCard(shop: ShopDetails) -> some View {
        LiquidGlassCard(cornerRadius: 22, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                Label("Sede & Informazioni Negozio", systemImage: "info.circle.fill")
                    .font(.headline)
                    .foregroundColor(.primary)

                Divider()

                if !shop.fullAddress.isEmpty {
                    infoRow(icon: "mappin.and.ellipse", title: "Indirizzo", value: shop.fullAddress)
                }

                if !shop.phone.isEmpty {
                    infoRow(icon: "phone.fill", title: "Telefono", value: shop.phone)
                }

                if !shop.email.isEmpty {
                    infoRow(icon: "envelope.fill", title: "Email", value: shop.email)
                }

                if !shop.website.isEmpty {
                    infoRow(icon: "globe", title: "Sito Web", value: shop.website)
                }
            }
        }
    }

    @ViewBuilder
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.brandOrange)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
    }

    @ViewBuilder
    private var howItWorksCard: some View {
        LiquidGlassCard(cornerRadius: 22, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(.brandOrange)
                    Text("Come Funziona il Conto Vendita & Recesso")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    policyItem(
                        icon: "tag.fill",
                        title: "1. Esposizione a Prezzo Pieno (0-60 gg)",
                        desc: "I tuoi oggetti rimangono esposti al prezzo concordato per i primi 60 giorni dalla presa in carico."
                    )

                    policyItem(
                        icon: "percent",
                        title: "2. Sconto in Saldo -50% (61-90 gg)",
                        desc: "Trascorsi 60 giorni, la merce invenduta viene scontata del 50% sul prezzo al pubblico. Anche il rimborso spettante viene proporzionalmente dimezzato."
                    )

                    policyItem(
                        icon: "clock.arrow.circlepath",
                        title: "3. Diritto di Recesso (14 giorni)",
                        desc: "Chi acquista ha diritto di ripensamento entro 14 giorni. Durante questo periodo l'importo è 'In Recesso'; terminati i 14 giorni diventa 'Maturato' e riscuotibile in cassa."
                    )

                    policyItem(
                        icon: "exclamationmark.triangle.fill",
                        title: "4. Scadenza Mandato (>90 gg)",
                        desc: "Oltre i 90 giorni la merce passa a maggior realizzo o donazione secondo le clausole contrattuali."
                    )

                    NavigationLink(destination: MandateClausesView()) {
                        HStack {
                            Text("Leggi Tutte le Clausole Contrattuali")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.brandOrange)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.brandOrange)
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func policyItem(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.brandOrange)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(desc)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func contactButton(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(text)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .clipShape(Capsule())
    }

    private func loadShopDetails() async {
        isLoading = true
        errorMessage = nil
        do {
            self.shopDetails = try await service.fetchShopDetails(shopId: shopId)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
