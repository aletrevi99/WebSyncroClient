import SwiftUI

/// Vista informativa sul negozio, orari di apertura settimanali e regolamento recesso
public struct ShopInfoView: View {
    let shopId: String
    @State private var shopInfo: ShopInfo?
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
                            VStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.15))
                                        .frame(width: 56, height: 56)

                                    Image(systemName: "storefront.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(.accentColor)
                                }

                                Text(shopId.capitalized)
                                    .font(.system(.title2, design: .rounded))
                                    .fontWeight(.bold)

                                Text("Piattaforma Mercatino WebSyncro")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
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
                                } else if let info = shopInfo {
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

                                                // Badge Aperto/Chiuso
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
                                    Text("Caricamento orari in corso...")
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

                                Text("Gli articoli venduti sono soggetti a un periodo di diritto di recesso a tutela dell'acquirente. Durante questo intervallo di tempo compaiono nella sezione 'Non Maturati'. Trascorso il termine previsto dal mercatino, l'importo passa automaticamente in 'Maturato' e diventa disponibile per il ritiro in cassa.")
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
                await loadSchedule()
            }
        }
    }

    private func loadSchedule() async {
        isLoading = true
        errorMessage = nil
        do {
            self.shopInfo = try await service.fetchShopInfo(shopId: shopId)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
