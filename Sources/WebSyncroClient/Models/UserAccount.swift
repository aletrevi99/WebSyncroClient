import Foundation

/// Profilo account utente per la gestione multi-negozio e multi-utente
public struct UserAccount: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var shopId: String
    public var userId: String
    public var accountAlias: String
    public var lastSyncDate: Date?
    public var lastTotalEarned: Decimal?
    public var lastSnapshotFolder: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        shopId: String,
        userId: String,
        accountAlias: String = "",
        lastSyncDate: Date? = nil,
        lastTotalEarned: Decimal? = nil,
        lastSnapshotFolder: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.shopId = shopId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.userId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.accountAlias = accountAlias.trimmingCharacters(in: .whitespacesAndNewlines)
        self.lastSyncDate = lastSyncDate
        self.lastTotalEarned = lastTotalEarned
        self.lastSnapshotFolder = lastSnapshotFolder
        self.createdAt = createdAt
    }

    /// Nome visualizzato dell'account (alias se presente, altrimenti negozio e utente)
    public var displayName: String {
        if !accountAlias.isEmpty {
            return accountAlias
        }
        return "Negozio \(shopId) • Utente \(userId)"
    }

    /// Sottotitolo per le card e la lista
    public var subtitle: String {
        return "Negozio: \(shopId) | ID Utente: \(userId)"
    }
}

