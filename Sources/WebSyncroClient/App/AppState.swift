import SwiftUI
import Combine

/// Coordinatore dello stato globale dell'applicazione
@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()

    @Published public var selectedTab: Int = 0
    public let accountStore: AccountStore
    public let service: WebSyncroServiceProtocol

    public init(
        accountStore: AccountStore? = nil,
        service: WebSyncroServiceProtocol = WebSyncroService.shared
    ) {
        self.accountStore = accountStore ?? AccountStore.shared
        self.service = service
    }
}

