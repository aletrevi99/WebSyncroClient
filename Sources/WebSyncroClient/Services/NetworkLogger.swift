import Foundation
import Combine

/// Record di una singola chiamata di rete HTTPS
public struct NetworkCallLog: Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let method: String
    public let urlString: String
    public let statusCode: Int?
    public let durationMs: Int
    public let requestHeaders: [String: String]?
    public let responseSnippet: String?
    public let errorDescription: String?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        method: String,
        urlString: String,
        statusCode: Int?,
        durationMs: Int,
        requestHeaders: [String: String]? = nil,
        responseSnippet: String? = nil,
        errorDescription: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.method = method
        self.urlString = urlString
        self.statusCode = statusCode
        self.durationMs = durationMs
        self.requestHeaders = requestHeaders
        self.responseSnippet = responseSnippet
        self.errorDescription = errorDescription
    }

    public var isSuccess: Bool {
        if let code = statusCode {
            return (200...299).contains(code)
        }
        return errorDescription == nil
    }

    public var formattedTime: String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss.SSS"
        return df.string(from: timestamp)
    }
}

/// Registro condiviso in memoria per tutte le chiamate HTTPS dell'applicazione
@MainActor
public final class NetworkLogStore: ObservableObject {
    public static let shared = NetworkLogStore()

    @Published public private(set) var logs: [NetworkCallLog] = []
    private let maxLogs = 100

    public init() {}

    public func addLog(_ log: NetworkCallLog) {
        logs.insert(log, at: 0)
        if logs.count > maxLogs {
            logs = Array(logs.prefix(maxLogs))
        }
    }

    public func clear() {
        logs.removeAll()
    }

    public func exportLogsAsText() -> String {
        guard !logs.isEmpty else { return "Nessuna chiamata HTTPS registrata nella sessione corrente." }
        return logs.map { log in
            """
            [\(log.formattedTime)] \(log.method) \(log.urlString)
            Status: \(log.statusCode.map { String($0) } ?? "Errore/Timeout") (\(log.durationMs)ms)
            \(log.errorDescription.map { "Error: \($0)\n" } ?? "")\(log.responseSnippet.map { "Snippet: \($0)\n" } ?? "")
            --------------------------------------------------
            """
        }.joined(separator: "\n")
    }
}
