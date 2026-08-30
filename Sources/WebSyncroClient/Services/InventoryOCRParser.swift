import Foundation

/// Parser avanzato per estrarre dati strutturati dal testo OCR del documento "Lista oggetti in carico"
public struct InventoryOCRParser {

    public struct ParsedInventoryResult: Sendable {
        public let listNumber: String
        public let loadDate: Date
        public let totalPieces: Int
        public let totalAgreedValue: Decimal
        public let totalExposedValue: Decimal
        public let items: [InventoryItem]
    }

    /// Analizza il testo raw estratto da Vision OCR
    public static func parse(ocrText: String, shopId: String = "exnovomercatino") -> ParsedInventoryResult {
        let lines = ocrText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var listNumber = ""
        var loadDate = Date()
        var totalPieces = 0
        var totalAgreedValue: Decimal = 0
        var totalExposedValue: Decimal = 0
        var extractedItems: [InventoryItem] = []

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "it_IT")
        dateFormatter.dateFormat = "dd/MM/yyyy"

        // 1. Estrazione Metadati Intestazione
        for line in lines {
            // Estrazione Numero Lista (es. "Lista Numero: 2026/009938" o "2026/009938")
            if line.localizedCaseInsensitiveContains("Lista Numero:") || line.localizedCaseInsensitiveContains("Lista:") {
                let parts = line.components(separatedBy: ":")
                if parts.count >= 2 {
                    let numCandidate = parts[1].trimmingCharacters(in: .whitespaces).components(separatedBy: " ").first ?? ""
                    if numCandidate.contains("/") {
                        listNumber = numCandidate
                    }
                }
            } else if listNumber.isEmpty && line.range(of: #"\b20\d{2}/\d{5,7}\b"#, options: .regularExpression) != nil {
                if let match = line.range(of: #"\b20\d{2}/\d{5,7}\b"#, options: .regularExpression) {
                    listNumber = String(line[match])
                }
            }

            // Estrazione Data di Carico (es. "Del: 11/06/2026" o "11/06/2026")
            if line.localizedCaseInsensitiveContains("Del:") {
                let parts = line.components(separatedBy: ":")
                if parts.count >= 2 {
                    let dateStr = parts[1].trimmingCharacters(in: .whitespaces).components(separatedBy: " ").first ?? ""
                    if let parsedDate = dateFormatter.date(from: dateStr) {
                        loadDate = parsedDate
                    }
                }
            } else if let match = line.range(of: #"\b\d{2}/\d{2}/20\d{2}\b"#, options: .regularExpression) {
                let dateStr = String(line[match])
                if let parsedDate = dateFormatter.date(from: dateStr) {
                    loadDate = parsedDate
                }
            }

            // Estrazione Totali a piè di pagina
            if line.localizedCaseInsensitiveContains("Valore totale della merce concordato") || line.localizedCaseInsensitiveContains("merce concordato") {
                if let amount = extractDecimal(from: line) {
                    totalAgreedValue = amount
                }
            }
            if line.localizedCaseInsensitiveContains("Valore della merce esposto") || line.localizedCaseInsensitiveContains("merce esposto") {
                if let amount = extractDecimal(from: line) {
                    totalExposedValue = amount
                }
            }
        }

        // 2. Estrazione Righe Tabella Articoli
        let codePattern = #"^(?:[vV]?\s*)?(1\s*[\.\s]?\s*\d{3}\s*[\.\s]?\s*\d{3})\b"#

        for line in lines {
            guard let regex = try? NSRegularExpression(pattern: codePattern, options: .caseInsensitive) else { continue }
            let range = NSRange(location: 0, length: line.utf16.count)
            guard let match = regex.firstMatch(in: line, options: [], range: range) else { continue }

            if let codeRange = Range(match.range(at: 1), in: line) {
                let rawCode = String(line[codeRange]).replacingOccurrences(of: " ", with: "")
                let cleanId = rawCode.replacingOccurrences(of: ".", with: "")

                var restOfLine = line.replacingOccurrences(of: String(line[Range(match.range(at: 0), in: line)!]), with: "").trimmingCharacters(in: .whitespaces)

                let (title, quantity, agreed, clientPayout, exposed) = parseLineContent(restOfLine)

                let item = InventoryItem(
                    id: cleanId,
                    rawCode: rawCode,
                    listNumber: listNumber,
                    loadDate: loadDate,
                    title: title.isEmpty ? "Articolo #\(cleanId)" : title,
                    category: "LI",
                    quantity: quantity,
                    agreedPrice: agreed,
                    clientPayoutInitial: clientPayout,
                    exposedPriceInitial: exposed,
                    shopId: shopId
                )

                extractedItems.append(item)
            }
        }

        // Calcolo totali se non presenti nell'OCR
        if totalPieces == 0 {
            totalPieces = extractedItems.reduce(0) { $0 + $1.quantity }
        }
        if totalAgreedValue == 0 {
            totalAgreedValue = extractedItems.reduce(Decimal.zero) { $0 + $1.agreedPrice }
        }
        if totalExposedValue == 0 {
            totalExposedValue = extractedItems.reduce(Decimal.zero) { $0 + ($1.exposedPriceInitial * Decimal($1.quantity)) }
        }

        return ParsedInventoryResult(
            listNumber: listNumber,
            loadDate: loadDate,
            totalPieces: totalPieces,
            totalAgreedValue: totalAgreedValue,
            totalExposedValue: totalExposedValue,
            items: extractedItems
        )
    }

    // MARK: - Helper Parsing Riga

    private static func parseLineContent(_ text: String) -> (title: String, quantity: Int, agreed: Decimal, clientPayout: Decimal, exposed: Decimal) {
        var clean = text

        // Rimuovi eventuale data a fine riga (es. "11/06/2026")
        if let match = clean.range(of: #"\d{2}/\d{2}/20\d{2}"#, options: .regularExpression) {
            clean = String(clean[..<match.lowerBound]).trimmingCharacters(in: .whitespaces)
        }

        var titlePart = clean
        var numbersPart = clean

        // Cerca colonna Categoria (es. " LI ", " AB ", " OG ")
        if let catMatch = clean.range(of: #"\s+(LI|AB|OG|AR|EL|MO|[A-Z]{2})\s+"#, options: .regularExpression) {
            titlePart = String(clean[..<catMatch.lowerBound]).trimmingCharacters(in: .whitespaces)
            numbersPart = String(clean[catMatch.upperBound...]).trimmingCharacters(in: .whitespaces)
        }

        let tokens = numbersPart.components(separatedBy: " ").filter { !$0.isEmpty }

        var numbers: [Decimal] = []
        for token in tokens {
            let normalized = token.replacingOccurrences(of: "€", with: "")
                .replacingOccurrences(of: "%", with: "")
                .replacingOccurrences(of: ",", with: ".")
                .trimmingCharacters(in: .whitespaces)

            if let val = Decimal(string: normalized) {
                // Salta la percentuale 50.00 se presente
                if val == Decimal(50) && numbers.count >= 2 {
                    continue
                }
                numbers.append(val)
            }
        }

        var quantity = 1
        var agreed: Decimal = 0
        var clientPayout: Decimal = 0
        var exposed: Decimal = 0

        // Colonne: Qtà, Prezzo Concordato, [50%], Provv, Rimborso Cliente, IVA, Prezzo Esposto
        if numbers.count >= 2 {
            // Primo numero dopo LI è la Quantità (es. 6, 14, 1)
            if let first = numbers.first, first == Decimal(Int(truncating: first as NSNumber)) {
                quantity = Int(truncating: first as NSNumber)
                numbers.removeFirst()
            }
            if !numbers.isEmpty {
                agreed = numbers[0]
            }
            if numbers.count >= 4 {
                clientPayout = numbers.count >= 3 ? numbers[2] : (numbers[0] * Decimal(0.5))
                exposed = numbers.last ?? numbers[0]
            } else if numbers.count >= 2 {
                clientPayout = numbers.count >= 2 ? numbers[1] : (numbers[0] * Decimal(0.5))
                exposed = numbers.last ?? numbers[0]
            } else if let single = numbers.first {
                clientPayout = single * Decimal(0.5)
                exposed = single
            }
        } else if let single = numbers.first {
            agreed = single
            clientPayout = single * Decimal(0.5)
            exposed = single
        }

        return (titlePart, quantity, agreed, clientPayout, exposed)
    }

    private static func extractDecimal(from text: String) -> Decimal? {
        let pattern = #"\b\d+[\.,]\d{2}\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(location: 0, length: text.utf16.count)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let matchRange = Range(match.range, in: text) else { return nil }

        let raw = String(text[matchRange]).replacingOccurrences(of: ",", with: ".")
        return Decimal(string: raw)
    }
}
