import SwiftUI

/// Vista informativa di alto livello con identità visiva del mercatino, orari live, bio e recapiti
public struct ShopInfoView: View {
    let shopId: String
    @State private var shopDetails: ShopDetails?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isPolicyExpanded: Bool = false
    @State private var showingMandateSheet: Bool = false
    @State private var showingSettingsSheet: Bool = false

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
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Card Principale: Identità Visiva, Bio, Sede e Contatti
                        shopHeroCard

                        // Card Stato Apertura Oggi in Tempo Reale
                        if let shop = shopDetails {
                            liveStatusCard(shop: shop)
                        }

                        // Card Orari della Settimana
                        weeklyScheduleCard

                        // Card Espandibile: Come Funziona il Conto Vendita & Regolamento Recesso
                        howItWorksCard

                        // Spaziatore per evitare sovrapposizione con la TabBar fluttuante
                        Spacer(minLength: 90)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Negozio")
            .adaptiveLargeTitle()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        HapticFeedback.selection()
                        showingSettingsSheet = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.brandOrange)
                    }
                }
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

    // MARK: - Hero Card Principale
    @ViewBuilder
    private var shopHeroCard: some View {
        LiquidGlassCard(cornerRadius: 24, padding: 22) {
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

                // Indirizzo e Sede (con tap rapido per aprire Apple Maps)
                if let shop = shopDetails, !shop.fullAddress.isEmpty {
                    if let encodedAddr = shop.fullAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                       let mapURL = URL(string: "http://maps.apple.com/?q=\(encodedAddr)") {
                        Link(destination: mapURL) {
                            HStack(alignment: .center, spacing: 8) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.subheadline)
                                    .foregroundColor(.brandOrange)

                                Text(shop.fullAddress)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.secondary.opacity(0.6))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

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

                        if !shop.fullAddress.isEmpty,
                           let encodedAddr = shop.fullAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                           let mapURL = URL(string: "http://maps.apple.com/?q=\(encodedAddr)") {
                            Link(destination: mapURL) {
                                contactButton(icon: "map.fill", text: "Mappa", color: .purple)
                            }
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
