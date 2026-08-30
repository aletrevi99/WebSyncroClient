import SwiftUI

/// Vista informativa sul negozio, recapiti, orari di apertura settimanali e regolamento recesso
public struct ShopInfoView: View {
    let shopId: String
    @State private var shopDetails: ShopDetails?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let service: WebSyncroServiceProtocol
    @Environment(\.dismiss) private var dismiss

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
                                        .fill(Color.accentColor.opacity(0.15))
                                        .frame(width: 60, height: 60)

                                    Image(systemName: "storefront.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.accentColor)
                                }

                                VStack(spacing: 4) {
                                    Text(shopDetails?.name ?? shopId.capitalized)
                                        .font(.system(.title2, design: .rounded))
                                        .fontWeight(.bold)
                                        .multilineTextAlignment(.center)

                                    Text("Mercatino Partner WebSyncro")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                // Pulsanti di contatto rapido
                                if let shop = shopDetails {
                                    HStack(spacing: 12) {
                                        if !shop.phone.isEmpty, let telURL = URL(string: "tel:\(shop.cleanPhoneNumber)") {
                                            Link(destination: telURL) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "phone.fill")
                                                    Text("Chiama")
                                                }
                                                .font(.system(.caption, design: .rounded))
                                                .fontWeight(.semibold)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(Color.green.opacity(0.15))
                                                .foregroundColor(.green)
                                                .clipShape(Capsule())
                                            }
                                        }

                                        if !shop.email.isEmpty, let mailURL = URL(string: "mailto:\(shop.email)") {
                                            Link(destination: mailURL) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "envelope.fill")
                                                    Text("Email")
                                                }
                                                .font(.system(.caption, design: .rounded))
                                                .fontWeight(.semibold)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(Color.blue.opacity(0.15))
                                                .foregroundColor(.blue)
                                                .clipShape(Capsule())
                                            }
                                        }

                                        if !shop.fullAddress.isEmpty,
                                           let encodedAddr = shop.fullAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                                           let mapURL = URL(string: "http://maps.apple.com/?q=\(encodedAddr)") {
                                            Link(destination: mapURL) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "map.fill")
                                                    Text("Mappa")
                                                }
                                                .font(.system(.caption, design: .rounded))
                                                .fontWeight(.semibold)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(Color.purple.opacity(0.15))
                                                .foregroundColor(.purple)
                                                .clipShape(Capsule())
                                            }
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }

                        // Card Recapiti e Indirizzo
                        if let shop = shopDetails, !shop.fullAddress.isEmpty || !shop.phone.isEmpty || !shop.email.isEmpty {
                            LiquidGlassCard(cornerRadius: 22, padding: 18) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("Recapiti & Sede", systemImage: "mappin.circle.fill")
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Divider()

                                    if !shop.fullAddress.isEmpty {
                                        HStack(alignment: .top, spacing: 10) {
                                            Image(systemName: "location.fill")
                                                .font(.caption)
                                                .foregroundColor(.accentColor)
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

                        // Card Orari di Apertura Settimanali
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Label("Orari di Apertura", systemImage: "clock.fill")
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
                                                            .foregroundColor(isToday ? .accentColor : .primary)

                                                        if isToday {
                                                            Text("OGGI")
                                                                .font(.system(size: 9, weight: .bold))
                                                                .padding(.horizontal, 6)
                                                                .padding(.vertical, 2)
                                                                .background(Color.accentColor.opacity(0.15))
                                                                .foregroundColor(.accentColor)
                                                                .clipShape(Capsule())
                                                        }
                                                    }

                                                    Text(day.formattedHours)
                                                        .font(.caption)
                                                        .foregroundColor(day.isClosed ? .secondary : .primary)
                                                }

                                                Spacer()

                                                Text(day.isClosed ? "Chiuso" : "Aperto")
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(day.isClosed ? Color.secondary.opacity(0.12) : Color.green.opacity(0.15))
                                                    .foregroundColor(day.isClosed ? .secondary : .green)
                                                    .clipShape(Capsule())
                                            }
                                            .padding(.vertical, 4)

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

                        // Card Informativa: Diritto di Recesso
                        LiquidGlassCard(cornerRadius: 22, padding: 18) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.uturn.backward.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.orange)

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
            .navigationTitle("Info Mercatino")
            .adaptiveInlineTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadShopDetails()
            }
        }
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
