import Foundation

public enum WebSyncroError: LocalizedError, Sendable {
    case invalidURL(String)
    case networkError(String)
    case httpError(statusCode: Int, message: String)
    case shopNotFound(shopId: String)
    case noSnapshotsFound(shopId: String)
    case userReportNotFound(shopId: String, userId: String, snapshot: String)
    case emptyResponse
    case decodingError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "URL non valido: \(url)"
        case .networkError(let message):
            return "Errore di connessione: \(message)"
        case .httpError(let code, let msg):
            return "Errore HTTP (\(code)): \(msg)"
        case .shopNotFound(let shopId):
            return "Negozio non trovato (ID: \(shopId))"
        case .noSnapshotsFound(let shopId):
            return "Nessuna sincronizzazione (cartella SM_...) trovata per il negozio #\(shopId)"
        case .userReportNotFound(let shopId, let userId, let snapshot):
            return "Nessun report per l'utente #\(userId) nel negozio #\(shopId) (snapshot: \(snapshot))"
        case .emptyResponse:
            return "Risposta vuota ricevuta dal server"
        case .decodingError(let details):
            return "Errore di decodifica dei dati: \(details)"
        }
    }
}

public protocol WebSyncroServiceProtocol: Sendable {
    /// Esegue il recupero del report maturato o non maturato
    func fetchSalesReport(
        shopId: String,
        userId: String,
        isNonMatured: Bool,
        onProgress: (@Sendable (SyncStatus) -> Void)?
    ) async throws -> SalesReport

    /// Recupera sia il report maturato che quello non maturato (in recesso)
    func fetchBothReports(
        shopId: String,
        userId: String,
        onProgress: (@Sendable (SyncStatus) -> Void)?
    ) async throws -> (matured: SalesReport, nonMatured: SalesReport)

    /// Recupera i dettagli anagrafici e orari del negozio
    func fetchShopDetails(shopId: String) async throws -> ShopDetails

    /// Recupera l'elenco di tutti i negozi WebSyncro da ElencoNegozi.txt
    func fetchShopDirectory() async throws -> [ShopDetails]

    /// Recupera l'elenco di tutte le cartelle snapshot disponibili per il negozio
    func fetchAvailableSnapshots(shopId: String) async throws -> [String]
}

public extension WebSyncroServiceProtocol {
    func fetchSalesReport(shopId: String, userId: String) async throws -> SalesReport {
        return try await fetchSalesReport(shopId: shopId, userId: userId, isNonMatured: false, onProgress: nil)
    }

    func fetchBothReports(shopId: String, userId: String) async throws -> (matured: SalesReport, nonMatured: SalesReport) {
        return try await fetchBothReports(shopId: shopId, userId: userId, onProgress: nil)
    }
}
