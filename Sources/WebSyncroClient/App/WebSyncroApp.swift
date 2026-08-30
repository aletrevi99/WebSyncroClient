import SwiftUI

/// Entry point per l'applicazione iOS WebSyncro Mercatini
#if os(iOS)
@main
#endif
public struct WebSyncroApp: App {
    @StateObject private var appState = AppState.shared

    public init() {}

    public var body: some Scene {
        WindowGroup {
            MainTabView(accountStore: appState.accountStore)
                .environmentObject(appState)
        }
    }
}
