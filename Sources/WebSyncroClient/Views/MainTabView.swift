import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Schermata principale con navigazione a Tab in stile Liquid Glass nativo
public struct MainTabView: View {
    @ObservedObject var accountStore: AccountStore
    @StateObject private var inventoryStore = InventoryStore.shared
    @State private var selectedTab: Int = 0

    public init(accountStore: AccountStore? = nil) {
        self.accountStore = accountStore ?? AccountStore.shared
        #if canImport(UIKit)
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        #endif
    }

    private var activeShopId: String {
        accountStore.activeAccount?.shopId ?? "exnovomercatino"
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Vendite (Maturato / In Recesso online)
            DashboardView(accountStore: accountStore)
                .tabItem {
                    Label("Vendite", systemImage: "cart.fill")
                }
                .tag(0)

            // Tab 2: Inventario (Oggetti in Carico, Sconti 50% e Riconciliazione)
            InventoryListView(inventoryStore: inventoryStore, accountStore: accountStore)
                .tabItem {
                    Label("Inventario", systemImage: "tray.full.fill")
                }
                .tag(1)

            // Tab 3: Notizie dal mercatino
            NewsListView(accountStore: accountStore)
                .tabItem {
                    Label("Notizie", systemImage: "megaphone.fill")
                }
                .tag(2)

            // Tab 4: Card Fornitore con Barcode
            UserCardView(accountStore: accountStore)
                .tabItem {
                    Label("Card", systemImage: "barcode.viewfinder")
                }
                .tag(3)

            // Tab 5: Info Negozio, Orari & Mandato
            ShopInfoView(shopId: activeShopId)
                .tabItem {
                    Label("Negozio", systemImage: "storefront.fill")
                }
                .tag(4)
        }
        .tint(Color.brandOrange)
    }
}
