import SwiftUI

/// Schermata principale con navigazione a Tab in stile Liquid Glass nativo
public struct MainTabView: View {
    @ObservedObject var accountStore: AccountStore
    @State private var selectedTab: Int = 0

    public init(accountStore: AccountStore? = nil) {
        self.accountStore = accountStore ?? AccountStore.shared
    }

    private var activeShopId: String {
        accountStore.activeAccount?.shopId ?? "exnovomercatino"
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Vendite (Maturato / In Recesso)
            DashboardView(accountStore: accountStore)
                .tabItem {
                    Label("Vendite", systemImage: "cart.fill")
                }
                .tag(0)

            // Tab 2: Notizie dal mercatino
            NewsListView(accountStore: accountStore)
                .tabItem {
                    Label("Notizie", systemImage: "megaphone.fill")
                }
                .tag(1)

            // Tab 3: Card Fornitore con Barcode
            UserCardView(accountStore: accountStore)
                .tabItem {
                    Label("Card", systemImage: "barcode.viewfinder")
                }
                .tag(2)

            // Tab 4: Info Negozio & Orari
            NavigationStack {
                ShopInfoView(shopId: activeShopId)
            }
            .tabItem {
                Label("Negozio", systemImage: "storefront.fill")
            }
            .tag(3)
        }
        .tint(Color.accentColor)
    }
}
