import SwiftUI

/// Galleria interattiva per visualizzare, testare e sincronizzare i Widget iOS
public struct WidgetsGalleryView: View {
    @ObservedObject var accountStore: AccountStore
    @ObservedObject var inventoryStore: InventoryStore
    @Environment(\.dismiss) private var dismiss

    @State private var snapshot: WebSyncroWidgetSnapshot = WidgetDataProvider.loadSnapshot()
    @State private var showingSyncBanner = false

    public init(
        accountStore: AccountStore? = nil,
        inventoryStore: InventoryStore? = nil
    ) {
        self.accountStore = accountStore ?? AccountStore.shared
        self.inventoryStore = inventoryStore ?? InventoryStore.shared
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(spacing: 22) {
                        // Banner Guida
                        LiquidGlassCard(cornerRadius: 20, padding: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "widget.small")
                                    .font(.title2)
                                    .foregroundColor(.brandOrange)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Widget iOS Personalizzati")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Aggiungi i widget alla schermata Home, Blocco schermo o StandBy per tenere d'occhio vendite, sconti e saldo senza aprire l'app.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        // Widget 1: Saldo Maturato & In Negozio (Medium)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("1. SALDO & INVENTARIO RAPIDO")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Medio / Piccolo")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 4)

                            BalanceOverviewMediumWidgetView(snapshot: snapshot)
                                .frame(height: 155)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }

                        // Widget 2: Saldo Maturato (Small)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("2. CREDITO RISCUOTIBILE (COMPATTO)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Piccolo")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 4)

                            HStack(spacing: 14) {
                                BalanceOverviewSmallWidgetView(snapshot: snapshot)
                                    .frame(width: 155, height: 155)
                                    .clipShape(RoundedRectangle(cornerRadius: 22))
                                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Vista Compatta")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                    Text("Ideale per tenere sempre visibile l'importo da ritirare in contanti in cassa.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(8)
                            }
                        }

                        // Widget 3: Ultime Vendite Feed (Medium)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("3. ULTIME VENDITE E ATTIVITÀ")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Medio")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 4)

                            RecentSalesMediumWidgetView(snapshot: snapshot)
                                .frame(height: 155)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }

                        // Widget 4: Tessera Fornitore Rapida (Medium)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("4. TESSERA DIGITALE & BARCODE RAPIDO")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Medio")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 4)

                            QuickCardMediumWidgetView(snapshot: snapshot)
                                .frame(height: 155)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }

                        // Widget 5: Scadenze & Saldi (Medium)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("5. PREVISIONE SALDI (-50%) & SCADENZE")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Medio")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 4)

                            ExpiringDiscountsMediumWidgetView(snapshot: snapshot)
                                .frame(height: 155)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }

                        // Tasto Sincronizza Snapshot
                        Button(action: {
                            syncSnapshotFromStores()
                            showingSyncBanner = true
                            HapticFeedback.notification(.success)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Sincronizza Dati Widget Adesso")
                            }
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(Color.brandOrange)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                        .padding(.top, 10)

                        if showingSyncBanner {
                            Text("Dati widget aggiornati con successo.")
                                .font(.caption)
                                .foregroundColor(.green)
                                .transition(.opacity)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Widget iOS")
            .adaptiveInlineTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
            .onAppear {
                syncSnapshotFromStores()
            }
        }
    }

    private func syncSnapshotFromStores() {
        let activeShop = accountStore.activeAccount?.shopId ?? "exnovomercatino"
        let activeUser = accountStore.activeAccount?.cardCode ?? "TRE091"
        let activeName = accountStore.activeAccount?.displayName ?? "EX NOVO Mercatino"

        let items = inventoryStore.items(for: activeShop, userCardCode: activeUser)
        let inShopPieces = items.reduce(0) { $0 + $1.quantity }
        let inShopAmount = items.reduce(Decimal.zero) { $0 + $1.totalCurrentClientPayout(for: $1.quantity) }

        WidgetDataProvider.saveSnapshot(
            shopName: activeName,
            shopId: activeShop,
            cardCode: activeUser,
            maturedAmount: Decimal(18.45),
            inRecessoAmount: Decimal(3.50),
            inShopEstimatedAmount: inShopAmount > 0 ? inShopAmount : Decimal(12.15),
            inShopPiecesCount: inShopPieces > 0 ? inShopPieces : 20,
            soldPiecesCount: 15,
            recentSales: WidgetSaleItem.samples,
            expiringItems: WidgetExpiringItem.samples
        )

        self.snapshot = WidgetDataProvider.loadSnapshot()
    }
}

