import Foundation

/// Stato del processo di sincronizzazione e diagnostica di rete
public enum SyncStatus: Equatable, Sendable {
    case idle
    case scrapingDirectory(shopId: String)
    case downloadingReport(shopId: String, snapshot: String, userId: String)
    case success(lastSyncDate: Date)
    case failure(reason: String)

    public var isSyncing: Bool {
        switch self {
        case .scrapingDirectory, .downloadingReport:
            return true
        default:
            return false
        }
    }

    public var statusDescription: String {
        switch self {
        case .idle:
            return "Pronto"
        case .scrapingDirectory(let shopId):
            return "Scansione snapshot negozio #\(shopId)..."
        case .downloadingReport(_, let snapshot, let userId):
            return "Download maturato utente #\(userId) (\(snapshot))..."
        case .success(let date):
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "it_IT")
            formatter.dateStyle = .short
            formatter.timeStyle = .medium
            return "Sincronizzato: \(formatter.string(from: date))"
        case .failure(let reason):
            return "Errore: \(reason)"
        }
    }
}

