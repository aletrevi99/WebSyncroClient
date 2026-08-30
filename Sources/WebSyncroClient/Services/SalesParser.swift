import Foundation

public enum SalesParser {
    
    private static let headerRegex = try! NSRegularExpression(
        pattern: #"^\s*([0-9A-Za-z_-]+)\s+(\d{1,2}/\d{1,2}/\d{4})\s+(.+)$"#
    )

    /// Esegue il parsing completo del file maturato.txt
    public static func parse(
        content: String,
        shopId: String,
        userId: String,
        syncTimestamp: String
    ) -> SalesReport {
        // Normalizza i ritorni a capo
        let normalized = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        // Separa la sezione principale dei record da eventuali metadati di coda
        let mainContent: String
        let postDelimiterContent: String?

        if let delimiterRange = normalized.range(of: "<#FINEELENCO>") {
            mainContent = String(normalized[..<delimiterRange.lowerBound])
            postDelimiterContent = String(normalized[delimiterRange.upperBound...])
        } else {
            mainContent = normalized
            postDelimiterContent = nil
        }

        // Estrai l'eventuale avviso opzionale
        let optionalNotice = extractOptionalNotice(from: normalized, postDelimiter: postDelimiterContent)

        // Splitta in righe
        let rawLines = mainContent.components(separatedBy: "\n")
        var items: [SaleItem] = []

        var index = 0
        while index < rawLines.count {
            let line = rawLines[index].trimmingCharacters(in: .whitespacesAndNewlines)
            index += 1

            // Salta righe vuote o tag speciali
            if line.isEmpty || line.hasPrefix("<#") {
                continue
            }

            // Verifica se è una riga di testata record (ID DATA IMPORTO)
            if let match = matchHeaderLine(line) {
                let id = match.id
                let dateString = match.dateString
                let rawAmount = match.rawAmount

                let date = Date.fromSaleDateString(dateString) ?? Date()
                let amount = parseAmount(rawAmount) ?? Decimal(0)

                // Cerca la descrizione nella riga successiva
                var title = ""
                if index < rawLines.count {
                    let nextCandidate = rawLines[index].trimmingCharacters(in: .whitespacesAndNewlines)
                    // Se la riga successiva è un'altra testata o un tag terminatore, non è la descrizione
                    if isHeaderLine(nextCandidate) || nextCandidate.hasPrefix("<#") {
                        // Descrizione vuota, la riga successiva verrà elaborata alla prossima iterazione
                    } else {
                        title = nextCandidate
                        index += 1
                    }
                }

                let saleItem = SaleItem(
                    id: id,
                    date: date,
                    dateString: dateString,
                    amount: amount,
                    title: title
                )
                items.append(saleItem)
            }
        }

        // Calcola il totale complessivo
        let totalEarned = items.reduce(Decimal(0)) { $0 + $1.amount }

        return SalesReport(
            shopId: shopId,
            userId: userId,
            syncTimestamp: syncTimestamp,
            totalEarned: totalEarned,
            itemsCount: items.count,
            items: items,
            optionalNotice: optionalNotice
        )
    }

    /// Estrae l'avviso opzionale da <#FRASEOPZIONALE>
    private static func extractOptionalNotice(from fullContent: String, postDelimiter: String?) -> String? {
        let searchContext = postDelimiter ?? fullContent
        guard let startRange = searchContext.range(of: "<#FRASEOPZIONALE>") else {
            return nil
        }

        let afterTag = searchContext[startRange.upperBound...]
        if let endRange = afterTag.range(of: "<#") {
            let notice = String(afterTag[..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            return notice.isEmpty ? nil : notice
        } else {
            let notice = String(afterTag).trimmingCharacters(in: .whitespacesAndNewlines)
            return notice.isEmpty ? nil : notice
        }
    }

    /// Verifica se una riga corrisponde al pattern testata record
    private static func isHeaderLine(_ line: String) -> Bool {
        return matchHeaderLine(line) != nil
    }

    private struct HeaderMatch {
        let id: String
        let dateString: String
        let rawAmount: String
    }

    private static func matchHeaderLine(_ line: String) -> HeaderMatch? {
        let range = NSRange(location: 0, length: (line as NSString).length)
        guard let match = headerRegex.firstMatch(in: line, options: [], range: range),
              match.numberOfRanges == 4 else {
            return nil
        }

        let nsString = line as NSString
        let id = nsString.substring(with: match.range(at: 1))
        let dateString = nsString.substring(with: match.range(at: 2))
        let rawAmount = nsString.substring(with: match.range(at: 3))

        return HeaderMatch(id: id, dateString: dateString, rawAmount: rawAmount)
    }

    /// Parsing robusto dell'importo con sanitizzazione caratteri di codifica
    public static func parseAmount(_ raw: String) -> Decimal? {
        var cleaned = raw
            .replacingOccurrences(of: "â¬", with: "")
            .replacingOccurrences(of: "\u{00E2}\u{00AC}", with: "")
            .replacingOccurrences(of: "\u{00E2}", with: "")
            .replacingOccurrences(of: "\u{00AC}", with: "")
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "EUR", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "eur", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "&euro;", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "\u{00A0}", with: "") // Non-breaking space
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.isEmpty {
            return nil
        }

        // Se contiene sia punto che virgola (es. 1.234,56 o 1,234.56)
        if cleaned.contains(".") && cleaned.contains(",") {
            if let dotIndex = cleaned.firstIndex(of: "."),
               let commaIndex = cleaned.firstIndex(of: ","),
               dotIndex < commaIndex {
                // Formato europeo: 1.234,56 -> 1234.56
                cleaned = cleaned.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            } else {
                // Formato US: 1,234.56 -> 1234.56
                cleaned = cleaned.replacingOccurrences(of: ",", with: "")
            }
        } else if cleaned.contains(",") {
            // Formato standard italiano: 0,45 -> 0.45
            cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
        }

        return Decimal(string: cleaned, locale: Locale(identifier: "en_US"))
    }
}

