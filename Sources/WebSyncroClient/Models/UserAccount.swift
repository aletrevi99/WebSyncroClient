import Foundation

/// Profilo account utente per la gestione multi-negozio e multi-utente
public struct UserAccount: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var shopId: String
    public var cardCode: String     // Codice alfanumerico tessera cliente (es. "TRE091")
    public var pin: String          // PIN numerico (es. "1762")
    public var accountAlias: String
    public var lastSyncDate: Date?
    public var lastTotalEarned: Decimal?
    public var lastNonMaturedEarned: Decimal?
    public var lastSnapshotFolder: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        shopId: String = "exnovomercatino",
        cardCode: String = "",
        pin: String = "",
        accountAlias: String = "",
        lastSyncDate: Date? = nil,
        lastTotalEarned: Decimal? = nil,
        lastNonMaturedEarned: Decimal? = nil,
        lastSnapshotFolder: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.shopId = shopId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.cardCode = cardCode.trimmingCharacters(in: .whitespacesAndNewlines)
        self.pin = pin.trimmingCharacters(in: .whitespacesAndNewlines)
        self.accountAlias = accountAlias.trimmingCharacters(in: .whitespacesAndNewlines)
        self.lastSyncDate = lastSyncDate
        self.lastTotalEarned = lastTotalEarned
        self.lastNonMaturedEarned = lastNonMaturedEarned
        self.lastSnapshotFolder = lastSnapshotFolder
        self.createdAt = createdAt
    }

    /// ID Utente combinato nel formato richiesto dal server: username_pin (es. "TRE091_1762")
    public var userId: String {
        let c = cardCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = pin.trimmingCharacters(in: .whitespacesAndNewlines)
        if !p.isEmpty {
            return "\(c)_\(p)"
        }
        return c
    }

    /// Nome visualizzato dell'account (alias se presente, altrimenti negozio e tessera)
    public var displayName: String {
        if !accountAlias.isEmpty {
            return accountAlias
        }
        return "\(shopId) • Tessera \(cardCode)"
    }

    /// Sottotitolo per le card e la lista
    public var subtitle: String {
        return "Negozio: \(shopId) | Tessera: \(cardCode)"
    }

    // MARK: - Backward Compatibility CodingKeys
    enum CodingKeys: String, CodingKey {
        case id, shopId, cardCode, pin, userId, accountAlias, lastSyncDate, lastTotalEarned, lastNonMaturedEarned, lastSnapshotFolder, createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.shopId = try container.decodeIfPresent(String.self, forKey: .shopId) ?? "exnovomercatino"
        self.accountAlias = try container.decodeIfPresent(String.self, forKey: .accountAlias) ?? ""
        self.lastSyncDate = try container.decodeIfPresent(Date.self, forKey: .lastSyncDate)
        self.lastTotalEarned = try container.decodeIfPresent(Decimal.self, forKey: .lastTotalEarned)
        self.lastNonMaturedEarned = try container.decodeIfPresent(Decimal.self, forKey: .lastNonMaturedEarned)
        self.lastSnapshotFolder = try container.decodeIfPresent(String.self, forKey: .lastSnapshotFolder)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()

        let decodedCardCode = try container.decodeIfPresent(String.self, forKey: .cardCode)
        let decodedPin = try container.decodeIfPresent(String.self, forKey: .pin)

        if let c = decodedCardCode, let p = decodedPin {
            self.cardCode = c
            self.pin = p
        } else if let legacyUserId = try container.decodeIfPresent(String.self, forKey: .userId) {
            // Se presente il vecchio formato userId con underscore
            let parts = legacyUserId.components(separatedBy: "_")
            if parts.count >= 2 {
                self.cardCode = parts[0]
                self.pin = parts.dropFirst().joined(separator: "_")
            } else {
                self.cardCode = legacyUserId
                self.pin = ""
            }
        } else {
            self.cardCode = ""
            self.pin = ""
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(shopId, forKey: .shopId)
        try container.encode(cardCode, forKey: .cardCode)
        try container.encode(pin, forKey: .pin)
        try container.encode(userId, forKey: .userId)
        try container.encode(accountAlias, forKey: .accountAlias)
        try container.encodeIfPresent(lastSyncDate, forKey: .lastSyncDate)
        try container.encodeIfPresent(lastTotalEarned, forKey: .lastTotalEarned)
        try container.encodeIfPresent(lastNonMaturedEarned, forKey: .lastNonMaturedEarned)
        try container.encodeIfPresent(lastSnapshotFolder, forKey: .lastSnapshotFolder)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
