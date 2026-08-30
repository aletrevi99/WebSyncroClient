import Foundation
import Combine

/// Gestore della persistenza degli account utente multi-negozio
@MainActor
public final class AccountStore: ObservableObject {
    public static let shared = AccountStore()

    private let userDefaults: UserDefaults
    private let accountsKey = "it.websyncro.client.accounts"
    private let activeAccountIdKey = "it.websyncro.client.active_account_id"

    @Published public private(set) var accounts: [UserAccount] = []
    @Published public private(set) var activeAccountId: UUID?

    public var activeAccount: UserAccount? {
        guard let id = activeAccountId else { return accounts.first }
        return accounts.first(where: { $0.id == id }) ?? accounts.first
    }

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadAccounts()
    }

    /// Carica gli account memorizzati
    public func loadAccounts() {
        if let data = userDefaults.data(forKey: accountsKey),
           let decoded = try? JSONDecoder().decode([UserAccount].self, from: data),
           !decoded.isEmpty {
            self.accounts = decoded
        } else {
            // Account iniziale predefinito
            let defaultAccount = UserAccount(
                shopId: "exnovomercatino",
                cardCode: "",
                pin: "",
                accountAlias: "EX Novo"
            )
            self.accounts = [defaultAccount]
            saveAccounts()
        }

        if let savedActiveIdString = userDefaults.string(forKey: activeAccountIdKey),
           let savedUUID = UUID(uuidString: savedActiveIdString),
           accounts.contains(where: { $0.id == savedUUID }) {
            self.activeAccountId = savedUUID
        } else {
            self.activeAccountId = accounts.first?.id
            if let firstId = accounts.first?.id {
                userDefaults.setValue(firstId.uuidString, forKey: activeAccountIdKey)
            }
        }
    }

    /// Salva la lista account in UserDefaults
    private func saveAccounts() {
        if let data = try? JSONEncoder().encode(accounts) {
            userDefaults.setValue(data, forKey: accountsKey)
        }
    }

    /// Aggiunge un nuovo account e lo rende attivo
    public func addAccount(shopId: String, cardCode: String, pin: String, alias: String) -> UserAccount {
        let newAccount = UserAccount(
            shopId: shopId,
            cardCode: cardCode,
            pin: pin,
            accountAlias: alias
        )
        accounts.append(newAccount)
        activeAccountId = newAccount.id
        userDefaults.setValue(newAccount.id.uuidString, forKey: activeAccountIdKey)
        saveAccounts()
        return newAccount
    }

    /// Aggiorna un account esistente
    public func updateAccount(_ account: UserAccount) {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
            saveAccounts()
        }
    }

    /// Rimuove un account
    public func deleteAccount(id: UUID) {
        accounts.removeAll(where: { $0.id == id })
        if activeAccountId == id {
            activeAccountId = accounts.first?.id
            userDefaults.setValue(activeAccountId?.uuidString, forKey: activeAccountIdKey)
        }
        saveAccounts()
    }

    /// Seleziona l'account attivo
    public func selectAccount(id: UUID) {
        guard accounts.contains(where: { $0.id == id }) else { return }
        self.activeAccountId = id
        userDefaults.setValue(id.uuidString, forKey: activeAccountIdKey)
    }

    /// Aggiorna le statistiche dell'ultima sincronizzazione riuscita
    public func recordSuccessfulSync(
        accountId: UUID,
        totalEarned: Decimal,
        nonMaturedEarned: Decimal? = nil,
        snapshotFolder: String
    ) {
        guard let index = accounts.firstIndex(where: { $0.id == accountId }) else { return }
        var account = accounts[index]
        account.lastSyncDate = Date()
        account.lastTotalEarned = totalEarned
        if let nm = nonMaturedEarned {
            account.lastNonMaturedEarned = nm
        }
        account.lastSnapshotFolder = snapshotFolder
        accounts[index] = account
        saveAccounts()
    }
}
