import SwiftUI

/// Entry point per l'applicazione iOS WebSyncro Mercatini
@main
public struct WebSyncroApp: App {
    @StateObject private var appState = AppState.shared

    public init() {}

    public var body: some Scene {
        WindowGroup {
            DashboardView(accountStore: appState.accountStore)
                .environmentObject(appState)
        }
    }
}
