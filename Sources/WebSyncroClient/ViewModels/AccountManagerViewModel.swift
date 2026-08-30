import Foundation
import Combine

@MainActor
public final class AccountManagerViewModel: ObservableObject {
    @Published public var accounts: [UserAccount] = []
    @Published public var activeAccountId: UUID?
    @Published public var isAddingAccount: Bool = false
    @Published public var editingAccount: UserAccount?

    // Campi form
    @Published public var formShopId: String = ""
    @Published public var formUserId: String = ""
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
        formShopId = ""
        formUserId = ""
        formAlias = ""
        formValidationError = nil
        editingAccount = nil
        isAddingAccount = true
    }

    public func prepareEditAccount(_ account: UserAccount) {
        editingAccount = account
        formShopId = account.shopId
        formUserId = account.userId
        formAlias = account.accountAlias
        formValidationError = nil
        isAddingAccount = true
    }

    public func saveAccount() -> Bool {
        let cleanShop = formShopId.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUser = formUserId.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanAlias = formAlias.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanShop.isEmpty {
            formValidationError = "Inserisci l'ID del negozio (es. 1042)"
            HapticFeedback.notification(.warning)
            return false
        }

        if cleanUser.isEmpty {
            formValidationError = "Inserisci l'ID utente (es. 852)"
            HapticFeedback.notification(.warning)
            return false
        }

        formValidationError = nil

        if let existing = editingAccount {
            var updated = existing
            updated.shopId = cleanShop
            updated.userId = cleanUser
            updated.accountAlias = cleanAlias
            accountStore.updateAccount(updated)
        } else {
            _ = accountStore.addAccount(
                shopId: cleanShop,
                userId: cleanUser,
                alias: cleanAlias
            )
        }

        HapticFeedback.notification(.success)
        isAddingAccount = false
        return true
    }
}

