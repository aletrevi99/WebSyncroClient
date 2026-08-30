import Foundation

public enum SalesParser {
    
    // Pattern per la testata di un articolo: [ID] [DATA dd/MM/yyyy] [IMPORTO]
    private static let headerRegex = try! NSRegularExpression(
        pattern: #"^\s*([0-9A-Za-z_-]+)\s+(\d{1,2}/\d{1,2}/\d{4})\s+([0-9.,]+.*)$"#
    )

    /// Esegue il parsing del file maturato.txt o nonmaturato.txt
    public static func parse(
        content: String,
        shopId: String,
        userId: String,
        syncTimestamp: String,
        isNonMatured: Bool = false
    ) -> SalesReport {
        // Normalizza i ritorni a capo
        let normalized = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        // Separa la sezione dell'elenco
        var listSection = normalized
        var postDelimiterContent: String?

        if let fineRange = listSection.range(of: "<#FINEELENCO>") {
            postDelimiterContent = String(listSection[fineRange.upperBound...])
            listSection = String(listSection[..<fineRange.lowerBound])
        }

        if let inizioRange = listSection.range(of: "<#INIZIOELENCO>") {
            listSection = String(listSection[inizioRange.upperBound...])
        }

        // Estrai l'eventuale avviso opzionale
        let optionalNotice = extractOptionalNotice(from: normalized, postDelimiter: postDelimiterContent)

        // Parsing delle righe
        let rawLines = listSection.components(separatedBy: "\n")
        var items: [SaleItem] = []
        var pendingTitle: String? = nil

        var index = 0
        while index < rawLines.count {
            let line = rawLines[index].trimmingCharacters(in: .whitespacesAndNewlines)
            index += 1

            // Salta righe vuote o tag speciali
            if line.isEmpty || line.hasPrefix("<#") {
                continue
            }

            if let match = matchHeaderLine(line) {
                // Abbiamo trovato la riga ID DATA IMPORTO
                let date = Date.fromSaleDateString(match.dateString) ?? Date()
                let amount = parseAmount(match.rawAmount) ?? Decimal(0)

                // Verifica se il titolo era nella riga precedente (es. WebSyncro standard)
                let title: String
                if let pt = pendingTitle, !pt.isEmpty {
                    title = pt
                    pendingTitle = nil
                } else if index < rawLines.count {
                    // Altrimenti controlla se è nella riga successiva
                    let nextCandidate = rawLines[index].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !isHeaderLine(nextCandidate) && !nextCandidate.hasPrefix("<#") && !nextCandidate.isEmpty {
                        title = nextCandidate
                        index += 1
                    } else {
                        title = ""
                    }
                } else {
                    title = ""
                }

                let saleItem = SaleItem(
                    id: match.id,
                    date: date,
                    dateString: match.dateString,
                    amount: amount,
                    title: title,
                    isNonMatured: isNonMatured
                )
                items.append(saleItem)
            } else {
                // Non è una testata: è una riga di descrizione/titolo
                pendingTitle = line
            }
        }

        // Calcola il totale
        let totalEarned = items.reduce(Decimal(0)) { $0 + $1.amount }

        return SalesReport(
            shopId: shopId,
            userId: userId,
            syncTimestamp: syncTimestamp,
            totalEarned: totalEarned,
            itemsCount: items.count,
            items: items,
            optionalNotice: optionalNotice,
            isNonMatured: isNonMatured
        )
    }

    /// Esegue il parsing della stringa Orario.txt
    public static func parseSchedule(content: String, shopId: String) -> ShopInfo {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let dayTokens = trimmed.components(separatedBy: "|")
        let dayNames = ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica"]

        var scheduleList: [DaySchedule] = []

        for (index, dayName) in dayNames.enumerated() {
            guard index < dayTokens.count else {
                scheduleList.append(DaySchedule(id: index, dayName: dayName, isClosed: true, morningHours: nil, afternoonHours: nil))
                continue
            }

            let token = dayTokens[index]
            let parts = token.components(separatedBy: "-")

            // Formato standard: isClosed-openMattina-closeMattina-openPomeriggio-closePomeriggio
            // Es: 0-09:30-12:30-15:00-19:30
            let isClosedFlag = parts.first == "1"

            var morning: String? = nil
            if parts.count >= 3 {
                let start = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let end = parts[2].trimmingCharacters(in: .whitespacesAndNewlines)
                if !start.isEmpty && !end.isEmpty && start != "00:00" {
                    morning = "\(start) - \(end)"
                }
            }

            var afternoon: String? = nil
            if parts.count >= 5 {
                let start = parts[3].trimmingCharacters(in: .whitespacesAndNewlines)
                let end = parts[4].trimmingCharacters(in: .whitespacesAndNewlines)
                if !start.isEmpty && !end.isEmpty && start != "00:00" {
                    afternoon = "\(start) - \(end)"
                }
            }

            let isActuallyClosed = isClosedFlag || (morning == nil && afternoon == nil)

            let daySchedule = DaySchedule(
                id: index,
                dayName: dayName,
                isClosed: isActuallyClosed,
                morningHours: morning,
                afternoonHours: afternoon
            )
            scheduleList.append(daySchedule)
        }

        return ShopInfo(shopId: shopId, schedule: scheduleList, rawSchedule: trimmed)
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
    public static func isHeaderLine(_ line: String) -> Bool {
        return matchHeaderLine(line) != nil
    }

    public struct HeaderMatch {
        public let id: String
        public let dateString: String
        public let rawAmount: String
    }

    public static func matchHeaderLine(_ line: String) -> HeaderMatch? {
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
                cleaned = cleaned.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            } else {
                cleaned = cleaned.replacingOccurrences(of: ",", with: "")
            }
        } else if cleaned.contains(",") {
            cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
        }

        return Decimal(string: cleaned, locale: Locale(identifier: "en_US"))
    }
}
