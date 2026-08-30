import Foundation

/// Protocollo per l'analisi visiva avanzata dei documenti di carico tramite LLM
public protocol VisionLLMServiceProtocol: Sendable {
    func analyzeInventoryDocument(
        imageData: Data,
        shopId: String,
        userCardCode: String
    ) async throws -> InventoryBatch
}

public enum VisionLLMError: LocalizedError {
    case missingApiKey
    case invalidImageData
    case networkError(String)
    case invalidServerResponse(statusCode: Int, message: String)
    case jsonParsingFailed(String)
    case noDataExtracted

    public var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "Chiave API OpenRouter non configurata. Inseriscila nelle Impostazioni (icona ⚙️ nel tab Negozio)."
        case .invalidImageData:
            return "Impossibile elaborare l'immagine scansionata."
        case .networkError(let msg):
            return "Errore di connessione: \(msg)"
        case .invalidServerResponse(let code, let msg):
            return "Errore server (\(code)): \(msg)"
        case .jsonParsingFailed(let details):
            return "Impossibile interpretare i dati estratti dall'AI: \(details)"
        case .noDataExtracted:
            return "L'AI non ha rilevato articoli validi nella foto."
        }
    }
}

// MARK: - OpenRouter Vision Client

public final class OpenRouterVisionService: VisionLLMServiceProtocol {
    private let apiKey: String
    private let model: String
    private let session: URLSession

    public init(
        apiKey: String,
        model: String = "google/gemini-2.5-flash",
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        self.model = model.isEmpty ? "google/gemini-2.5-flash" : model
        self.session = session
    }

    public func analyzeInventoryDocument(
        imageData: Data,
        shopId: String = "exnovomercatino",
        userCardCode: String = ""
    ) async throws -> InventoryBatch {
        guard !apiKey.isEmpty else {
            throw VisionLLMError.missingApiKey
        }

        let base64Image = imageData.base64EncodedString()
        let prompt = """
        Sei un esperto contabile OCR. Analizza attentamente questa foto del documento 'Lista oggetti in carico' rilasciato da un mercatino dell'usato (WebSyncro / EX NOVO).

        Estrai tutti i dati con la massima precisione:
        1. Intestazione:
           - list_number: numero della lista (es. "2026/009938")
           - load_date: data del carico in formato "dd/MM/yyyy" (es. "11/06/2026")
           - total_pieces: totale pezzi (numero intero)
           - total_agreed_value: valore totale merce concordato (numero decimale con punto)
           - total_exposed_value: valore della merce esposto al pubblico (numero decimale con punto)
        2. Tabella Articoli (per OGNI singola riga della tabella):
           - code: codice articolo completo (es. "1.260.214")
           - title: descrizione COMPLETA dell'articolo. IMPORTANTE: includi SEMPRE numeri, volumi, edizioni e autori (es. "Libro 2", "Libro 3-4", "Happy Feet la storia del film", "La ragazza con l'orecchino di perla. Ediz. speciale Chevalier Tracy"). Non troncare MAI il titolo a solo "Libro" se nella riga sono presenti numeri o altre parole!
           - category: sigla categoria merceologica (es. "LI")
           - quantity: quantità pezzi indicata nella colonna Qtà (numero intero, es. 6, 14, 1)
           - agreed_price: prezzo concordato (numero decimale con punto, es. 2.70)
           - client_payout: rimborso cliente unitario (numero decimale con punto, es. 1.35)
           - exposed_price: prezzo esposto al pubblico unitario (numero decimale con punto, es. 3.00)

        IMPORTANTE: Rispondi ESCLUSIVAMENTE con un JSON valido strutturato come segue, senza commenti o testo extra:
        {
          "list_number": "2026/009938",
          "load_date": "11/06/2026",
          "total_pieces": 35,
          "total_agreed_value": 84.15,
          "total_exposed_value": 93.50,
          "items": [
            {
              "code": "1.260.214",
              "title": "Libro 2",
              "category": "LI",
              "quantity": 6,
              "agreed_price": 2.70,
              "client_payout": 1.35,
              "exposed_price": 3.00
            },
            {
              "code": "1.260.215",
              "title": "Libro 3-4",
              "category": "LI",
              "quantity": 14,
              "agreed_price": 2.25,
              "client_payout": 1.13,
              "exposed_price": 2.50
            }
          ]
        }
        """

        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
            throw VisionLLMError.networkError("URL non valido")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://websyncro.it", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("WebSyncro Mercatini Client", forHTTPHeaderField: "X-Title")
        request.timeoutInterval = 60

        let payload: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "temperature": 0.1
        ]

        let httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.httpBody = httpBody

        let startTime = CFAbsoluteTimeGetCurrent()
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            let durationMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)
            await MainActor.run {
                NetworkLogStore.shared.addLog(
                    NetworkCallLog(
                        method: "POST",
                        urlString: url.absoluteString,
                        statusCode: nil,
                        durationMs: durationMs,
                        errorDescription: error.localizedDescription
                    )
                )
            }
            throw VisionLLMError.networkError(error.localizedDescription)
        }

        let durationMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)

        guard let httpResp = response as? HTTPURLResponse else {
            throw VisionLLMError.networkError("Risposta non HTTP")
        }

        let snippet = String(data: data.prefix(300), encoding: .utf8) ?? "\(data.count) bytes"
        await MainActor.run {
            NetworkLogStore.shared.addLog(
                NetworkCallLog(
                    method: "POST",
                    urlString: url.absoluteString,
                    statusCode: httpResp.statusCode,
                    durationMs: durationMs,
                    responseSnippet: snippet
                )
            )
        }

        guard (200...299).contains(httpResp.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Errore sconosciuto"
            throw VisionLLMError.invalidServerResponse(statusCode: httpResp.statusCode, message: errorText)
        }

        return try Self.parseLLMResponse(data: data, shopId: shopId, userCardCode: userCardCode)
    }

    /// Estrae il payload JSON dalla risposta di completamento OpenRouter
    public static func parseLLMResponse(
        data: Data,
        shopId: String,
        userCardCode: String
    ) throws -> InventoryBatch {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let rawContent = message["content"] as? String else {
            throw VisionLLMError.jsonParsingFailed("Struttura risposta OpenRouter non valida")
        }

        let cleanJSON = extractJSONBlock(from: rawContent)
        guard let jsonData = cleanJSON.data(using: .utf8) else {
            throw VisionLLMError.jsonParsingFailed("Impossibile convertire il JSON in dati")
        }

        return try parseBatchJSON(data: jsonData, shopId: shopId, userCardCode: userCardCode)
    }

    /// Rimuove eventuali blocchi markdown ```json ... ``` dal testo
    public static func extractJSONBlock(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if let startRange = trimmed.range(of: "```json"),
           let endRange = trimmed.range(of: "```", range: startRange.upperBound..<trimmed.endIndex) {
            return String(trimmed[startRange.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let startRange = trimmed.range(of: "```"),
           let endRange = trimmed.range(of: "```", range: startRange.upperBound..<trimmed.endIndex) {
            return String(trimmed[startRange.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let firstBrace = trimmed.firstIndex(of: "{"),
           let lastBrace = trimmed.lastIndex(of: "}") {
            return String(trimmed[firstBrace...lastBrace])
        }

        return trimmed
    }

    /// Struttura DTO interna per decodificare il JSON restituito dall'LLM
    private struct BatchJSONDTO: Codable {
        let list_number: String?
        let load_date: String?
        let total_pieces: Int?
        let total_agreed_value: Decimal?
        let total_exposed_value: Decimal?
        let items: [ItemJSONDTO]?
    }

    private struct ItemJSONDTO: Codable {
        let code: String?
        let title: String?
        let category: String?
        let quantity: Int?
        let agreed_price: Decimal?
        let client_payout: Decimal?
        let exposed_price: Decimal?
    }

    /// Converte il DTO decodificato nel modello di dominio `InventoryBatch`
    public static func parseBatchJSON(
        data: Data,
        shopId: String,
        userCardCode: String
    ) throws -> InventoryBatch {
        let decoder = JSONDecoder()
        guard let dto = try? decoder.decode(BatchJSONDTO.self, from: data) else {
            throw VisionLLMError.jsonParsingFailed("Decodifica JSON DTO fallita")
        }

        let listNumber = dto.list_number?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "LISTA-\(UUID().uuidString.prefix(6))"

        let loadDate: Date
        if let dateStr = dto.load_date {
            loadDate = DateExtensions.parseDate(dateStr) ?? Date()
        } else {
            loadDate = Date()
        }

        var parsedItems: [InventoryItem] = []
        for itemDTO in (dto.items ?? []) {
            let rawCode = itemDTO.code?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let cleanId = rawCode.replacingOccurrences(of: ".", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleanId.isEmpty else { continue }

            let agreed = itemDTO.agreed_price ?? Decimal(0)
            let clientPayout = itemDTO.client_payout ?? (agreed * Decimal(0.5))
            let exposed = itemDTO.exposed_price ?? (agreed * Decimal(1.1))

            let item = InventoryItem(
                id: cleanId,
                rawCode: rawCode,
                listNumber: listNumber,
                loadDate: loadDate,
                title: itemDTO.title ?? "Articolo #\(cleanId)",
                category: itemDTO.category ?? "LI",
                quantity: max(1, itemDTO.quantity ?? 1),
                agreedPrice: agreed,
                clientPayoutInitial: clientPayout,
                exposedPriceInitial: exposed,
                shopId: shopId,
                userCardCode: userCardCode
            )
            parsedItems.append(item)
        }

        guard !parsedItems.isEmpty else {
            throw VisionLLMError.noDataExtracted
        }

        let totalPieces = dto.total_pieces ?? parsedItems.reduce(0) { $0 + $1.quantity }
        let totalAgreed = dto.total_agreed_value ?? parsedItems.reduce(Decimal.zero) { $0 + $1.agreedPrice }
        let totalExposed = dto.total_exposed_value ?? parsedItems.reduce(Decimal.zero) { $0 + ($1.exposedPriceInitial * Decimal($1.quantity)) }

        return InventoryBatch(
            listNumber: listNumber,
            loadDate: loadDate,
            shopId: shopId,
            userCardCode: userCardCode,
            totalPieces: totalPieces,
            totalAgreedValue: totalAgreed,
            totalExposedValue: totalExposed,
            items: parsedItems
        )
    }
}
