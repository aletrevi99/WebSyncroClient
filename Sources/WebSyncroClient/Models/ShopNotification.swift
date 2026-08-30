import Foundation

/// Modello che rappresenta una notizia o comunicazione pubblicata dal mercatino
public struct ShopNotification: Identifiable, Hashable, Sendable, Codable {
    public let id: String
    public let dateString: String
    public let sender: String
    public let title: String
    public let message: String
    public let rawFilename: String

    public init(
        id: String,
        dateString: String,
        sender: String,
        title: String,
        message: String,
        rawFilename: String
    ) {
        self.id = id
        self.dateString = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
        self.sender = sender.trimmingCharacters(in: .whitespacesAndNewlines)
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        self.rawFilename = rawFilename
    }

    /// Data formattata leggibile
    public var displayDate: String {
        return dateString.isEmpty ? "Data non disponibile" : dateString
    }
}
