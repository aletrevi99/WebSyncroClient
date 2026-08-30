import Foundation
import Combine

@MainActor
public final class AccountManagerViewModel: ObservableObject {
    @Published public var accounts: [UserAccount] = []
    @Published public var activeAccountId: UUID?
    @Published public var isAddingAccount: Bool = false
    @Published public var editingAccount: UserAccount?
    @Published public var availableShops: [ShopDetails] = []

    // Campi form
    @Published public var formShopId: String = "exnovomercatino"
    @Published public var formCardCode: String = ""
    @Published public var formPin: String = ""
    @Published public var formAlias: String = ""
    @Published public var formValidationError: String?
    @Published public var isShopLocked: Bool = true

    private let accountStore: AccountStore
    private let service: WebSyncroServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    public init(
        accountStore: AccountStore? = nil,
        service: WebSyncroServiceProtocol = WebSyncroService.shared
    ) {
        let store = accountStore ?? AccountStore.shared
        self.accountStore = store
        self.service = service

        store.$accounts
            .assign(to: \.accounts, on: self)
            .store(in: &cancellables)

        store.$activeAccountId
            .assign(to: \.activeAccountId, on: self)
            .store(in: &cancellables)

        Task {
            await loadAvailableShops()
        }
    }

    public func loadAvailableShops() async {
        do {
            let list = try await service.fetchShopDirectory()
            if !list.isEmpty {
                self.availableShops = list
            }
        } catch {
            // Fallback su elenco base
        }
    }

    public func selectKnownShop(_ shop: ShopDetails) {
        formShopId = shop.slug
        isShopLocked = true
        if formAlias.isEmpty || availableShops.contains(where: { $0.name == formAlias }) {
            formAlias = shop.name
        }
        HapticFeedback.selection()
    }

    public func unlockShopSelection() {
        isShopLocked = false
        HapticFeedback.selection()
    }

    public func selectAccount(_ account: UserAccount) {
        accountStore.selectAccount(id: account.id)
        HapticFeedback.selection()
    }

    public func deleteAccount(_ account: UserAccount) {
        accountStore.deleteAccount(id: account.id)
        HapticFeedback.impact(.light)
    }

    public func prepareAddAccount() {
        formShopId = "exnovomercatino"
        formCardCode = ""
        formPin = ""
        formAlias = ""
        formValidationError = nil
        isShopLocked = true
        editingAccount = nil
        isAddingAccount = true
    }

    public func prepareEditAccount(_ account: UserAccount) {
        editingAccount = account
        formShopId = account.shopId
        formCardCode = account.cardCode
        formPin = account.pin
        formAlias = account.accountAlias
        formValidationError = nil
        isShopLocked = availableShops.contains(where: { $0.slug.caseInsensitiveCompare(account.shopId) == .orderedSame })
        isAddingAccount = true
    }

    public func handleScannedQRCode(_ qrString: String) -> Bool {
        guard let scanned = QRCodeParser.parse(qrString: qrString) else {
            formValidationError = "Codice QR non valido per il mercatino"
            HapticFeedback.notification(.error)
            return false
        }

        // Cerca se corrisponde a un negozio noto
        let rawLower = scanned.rawShop.lowercased()
        if let matched = availableShops.first(where: {
            $0.name.lowercased().contains(rawLower) ||
            $0.slug.lowercased().contains(rawLower) ||
            rawLower.contains($0.name.lowercased()) ||
            rawLower.contains($0.slug.lowercased())
        }) {
            formShopId = matched.slug
            formAlias = matched.name
            isShopLocked = true
        } else if rawLower.contains("ex novo") || rawLower.contains("exnovo") {
            formShopId = "exnovomercatino"
            formAlias = "EX Novo"
            isShopLocked = true
        } else {
            formShopId = scanned.rawShop
            formAlias = scanned.rawShop
            isShopLocked = false
        }

        formCardCode = scanned.cardCode
        formPin = scanned.pin
        formValidationError = nil
        HapticFeedback.notification(.success)
        return true
    }

    public func saveAccount() -> Bool {
        let cleanShop = formShopId.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCard = formCardCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPin = formPin.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanAlias = formAlias.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanShop.isEmpty {
            formValidationError = "Seleziona o inserisci il negozio"
            HapticFeedback.notification(.warning)
            return false
        }

        if cleanCard.isEmpty {
            formValidationError = "Inserisci il Codice Tessera cliente"
            HapticFeedback.notification(.warning)
            return false
        }

        if cleanPin.isEmpty {
            formValidationError = "Inserisci il PIN numerico associato"
            HapticFeedback.notification(.warning)
            return false
        }

        formValidationError = nil

        if let existing = editingAccount {
            var updated = existing
            updated.shopId = cleanShop
            updated.cardCode = cleanCard
            updated.pin = cleanPin
            updated.accountAlias = cleanAlias
            accountStore.updateAccount(updated)
        } else {
            _ = accountStore.addAccount(
                shopId: cleanShop,
                cardCode: cleanCard,
                pin: cleanPin,
                alias: cleanAlias
            )
        }

        HapticFeedback.notification(.success)
        isAddingAccount = false
        return true
    }
}
