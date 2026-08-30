import Foundation
import Combine

@MainActor
public final class SettingsViewModel: ObservableObject {
    @Published public var isDemoMode: Bool = false
    @Published public var availableSnapshots: [String] = []
    @Published public var isLoadingSnapshots: Bool = false
    @Published public var snapshotErrorMessage: String?

    private let service: WebSyncroServiceProtocol
    private let accountStore: AccountStore

    public init(
        service: WebSyncroServiceProtocol = WebSyncroService.shared,
        accountStore: AccountStore? = nil
    ) {
        self.service = service
        self.accountStore = accountStore ?? AccountStore.shared
    }

    public var currentAccount: UserAccount? {
        accountStore.activeAccount
    }

    public func fetchAvailableSnapshots() async {
        guard let account = currentAccount, !account.shopId.isEmpty else { return }

        isLoadingSnapshots = true
        snapshotErrorMessage = nil

        do {
            let snapshots = try await service.fetchAvailableSnapshots(shopId: account.shopId)
            self.availableSnapshots = snapshots
        } catch {
            self.snapshotErrorMessage = error.localizedDescription
        }

        isLoadingSnapshots = false
    }
}

