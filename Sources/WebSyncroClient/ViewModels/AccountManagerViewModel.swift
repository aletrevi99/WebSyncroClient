import Foundation
import Combine

@MainActor
public final class AccountManagerViewModel: ObservableObject {
    @Published public var accounts: [UserAccount] = []
    @Published public var activeAccountId: UUID?
    @Published public var isAddingAccount: Bool = false
    @Published public var editingAccount: UserAccount?

    // Campi form
    @Published public var formShopId: String = "exnovomercatino"
    @Published public var formCardCode: String = ""
    @Published public var formPin: String = ""
    @Published public var formAlias: String = ""
    @Published public var formValidationError: String?

    private let accountStore: AccountStore
    private var cancellables = Set<AnyCancellable>()

    public init(accountStore: AccountStore? = nil) {
        let store = accountStore ?? AccountStore.shared
        self.accountStore = store

        store.$accounts
            .assign(to: \.accounts, on: self)
            .store(in: &cancellables)

        store.$activeAccountId
            .assign(to: \.activeAccountId, on: self)
            .store(in: &cancellables)
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
        isAddingAccount = true
    }

    public func saveAccount() -> Bool {
        let cleanShop = formShopId.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCard = formCardCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPin = formPin.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanAlias = formAlias.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanShop.isEmpty {
            formValidationError = "Inserisci l'ID o nome del negozio (es. exnovomercatino)"
            HapticFeedback.notification(.warning)
            return false
        }

        if cleanCard.isEmpty {
            formValidationError = "Inserisci il Codice Tessera / Username cliente (es. TRE091)"
            HapticFeedback.notification(.warning)
            return false
        }

        if cleanPin.isEmpty {
            formValidationError = "Inserisci il PIN numerico associato (es. 1762)"
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
