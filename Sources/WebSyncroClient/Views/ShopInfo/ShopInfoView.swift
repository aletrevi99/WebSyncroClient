import SwiftUI

/// Vista informativa sul negozio, recapiti, orari di apertura settimanali e regolamento recesso
public struct ShopInfoView: View {
    let shopId: String
    @State private var shopDetails: ShopDetails?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let service: WebSyncroServiceProtocol

    public init(
        shopId: String,
        service: WebSyncroServiceProtocol = WebSyncroService.shared
    ) {
        self.shopId = shopId
        self.service = service
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Card Intestazione Negozio
                        LiquidGlassCard(cornerRadius: 24, padding: 20) {
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.brandOrange.opacity(0.15))
                                        .frame(width: 60, height: 60)

                                    Image(systemName: "storefront.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.brandOrange)
                                }

                                VStack(spacing: 4) {
                                    Text(shopDetails?.name ?? shopId.capitalized)
                                        .font(.system(.title2, design: .rounded))
                                        .fontWeight(.bold)
                                        .multilineTextAlignment(.center)

                                    if let shop = shopDetails, !shop.cityZip.isEmpty {
                                        Text(shop.cityZip)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                // Pulsanti di contatto rapido (Chiama, Email, Sito Web, Mappa)
                                if let shop = shopDetails {
                                    HStack(spacing: 8) {
                                        if !shop.phone.isEmpty, let telURL = URL(string: "tel:\(shop.cleanPhoneNumber)") {
                                            Link(destination: telURL) {
                                                contactButtonLabel(icon: "phone.fill", text: "Chiama", color: .green)
                                            }
                                        }

                                        if !shop.email.isEmpty, let mailURL = URL(string: "mailto:\(shop.email)") {
                                            Link(destination: mailURL) {
                                                contactButtonLabel(icon: "envelope.fill", text: "Email", color: .blue)
                                            }
                                        }

                                        if !shop.website.isEmpty, let webURL = URL(string: shop.website) {
                                            Link(destination: webURL) {
                                                contactButtonLabel(icon: "globe", text: "Sito Web", color: .brandOrange)
                                            }
                                        }

                                        if !shop.fullAddress.isEmpty,
                                           let encodedAddr = shop.fullAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                                           let mapURL = URL(string: "http://maps.apple.com/?q=\(encodedAddr)") {
                                            Link(destination: mapURL) {
                                                contactButtonLabel(icon: "map.fill", text: "Mappa", color: .purple)
                                            }
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }

                        // Hero Card: Stato Apertura Oggi in Tempo Reale
                        if let shop = shopDetails {
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

                        // Card Orari di Apertura Settimanali
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Label("Orari della Settimana", systemImage: "calendar")
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

                                                // Tag dinamico: Se è oggi mostra se è Aperto ora / Pausa / Chiuso, altrimenti solo Aperto/Chiuso generale
                                                if isToday {
                                                    let openNow = info.currentOpenStatus.isOpen
                                                    Text(openNow ? "Aperto Adesso" : (day.isClosed ? "Chiuso" : "Chiuso Ora"))
                                                        .font(.system(size: 11, weight: .semibold))
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .background(openNow ? Color.green.opacity(0.15) : Color.secondary.opacity(0.12))
                                                        .foregroundColor(openNow ? .green : .secondary)
                                                        .clipShape(Capsule())
                                                } else {
                                                    Text(day.isClosed ? "Chiuso" : "Orario Regolare")
                                                        .font(.system(size: 11, weight: .semibold))
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .background(day.isClosed ? Color.secondary.opacity(0.12) : Color.primary.opacity(0.06))
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

                        // Card Recapiti e Indirizzo
                        if let shop = shopDetails, !shop.fullAddress.isEmpty || !shop.phone.isEmpty || !shop.email.isEmpty {
                            LiquidGlassCard(cornerRadius: 22, padding: 18) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("Sede & Contatti", systemImage: "mappin.circle.fill")
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Divider()

                                    if !shop.fullAddress.isEmpty {
                                        HStack(alignment: .top, spacing: 10) {
                                            Image(systemName: "location.fill")
                                                .font(.caption)
                                                .foregroundColor(.brandOrange)
                                                .padding(.top, 2)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Indirizzo")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Text(shop.fullAddress)
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                    }

                                    if !shop.phone.isEmpty {
                                        HStack(alignment: .top, spacing: 10) {
                                            Image(systemName: "phone.fill")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                                .padding(.top, 2)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Telefono")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Text(shop.phone)
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                    }

                                    if !shop.email.isEmpty {
                                        HStack(alignment: .top, spacing: 10) {
                                            Image(systemName: "envelope.fill")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                                .padding(.top, 2)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Email")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Text(shop.email)
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Card Informativa: Diritto di Recesso
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.uturn.backward.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.brandOrange)

                                    Text("Diritto di Recesso e Maturazione")
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.semibold)
                                }

                                Text("Gli articoli venduti sono soggetti a un periodo di diritto di recesso a tutela dell'acquirente. Durante questo intervallo di tempo compaiono nella sezione 'In Recesso'. Trascorso il termine previsto dal mercatino, l'importo passa automaticamente in 'Maturato' e diventa disponibile per il ritiro in cassa.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        Spacer()
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Negozio")
            .adaptiveLargeTitle()
            .task {
                await loadShopDetails()
            }
        }
    }

    @ViewBuilder
    private func contactButtonLabel(icon: String, text: String, color: Color) -> some View {
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
