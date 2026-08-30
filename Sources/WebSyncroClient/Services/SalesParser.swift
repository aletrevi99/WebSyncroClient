import Foundation

public enum SalesParser {
    
    // Pattern per la testata di un articolo: [ID] [DATA dd/MM/yyyy] [IMPORTO]
    private static let headerRegex = try! NSRegularExpression(
        pattern: #"^\s*([0-9A-Za-z_-]+)\s+(\d{1,2}/\d{1,2}/\d{4})\s+([0-9.,]+.*)$"#
    )

    private static let notificationRegex = try! NSRegularExpression(
        pattern: #"Notifica_\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.txt"#
    )

    /// Esegue il parsing del file maturato.txt o nonmaturato.txt
    public static func parse(
        content: String,
        shopId: String,
        userId: String,
        syncTimestamp: String,
        isNonMatured: Bool = false
    ) -> SalesReport {
        let normalized = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        var listSection = normalized
        var postDelimiterContent: String?

        if let fineRange = listSection.range(of: "<#FINEELENCO>") {
            postDelimiterContent = String(listSection[fineRange.upperBound...])
            listSection = String(listSection[..<fineRange.lowerBound])
        }

        if let inizioRange = listSection.range(of: "<#INIZIOELENCO>") {
            listSection = String(listSection[inizioRange.upperBound...])
        }

        let optionalNotice = extractOptionalNotice(from: normalized, postDelimiter: postDelimiterContent)

        let rawLines = listSection.components(separatedBy: "\n")
        var items: [SaleItem] = []
        var pendingTitle: String? = nil

        var index = 0
        while index < rawLines.count {
            let line = rawLines[index].trimmingCharacters(in: .whitespacesAndNewlines)
            index += 1

            if line.isEmpty || line.hasPrefix("<#") {
                continue
            }

            if let match = matchHeaderLine(line) {
                let date = Date.fromSaleDateString(match.dateString) ?? Date()
                let amount = parseAmount(match.rawAmount) ?? Decimal(0)

                let title: String
                if let pt = pendingTitle, !pt.isEmpty {
                    title = pt
                    pendingTitle = nil
                } else if index < rawLines.count {
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

                let cleanId = match.id.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleanId.isEmpty && amount > 0 {
                    let saleItem = SaleItem(
                        id: cleanId,
                        date: date,
                        dateString: match.dateString,
                        amount: amount,
                        title: title,
                        isNonMatured: isNonMatured
                    )
                    items.append(saleItem)
                }
            } else {
                pendingTitle = line
            }
        }

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

    /// Esegue il parsing di una singola notifica mercatino
    public static func parseNotification(content: String, filename: String) -> ShopNotification {
        let normalized = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        let date = extractTagValue(tag: "<#DATA>", in: normalized) ?? ""
        let sender = extractTagValue(tag: "<#MITTENTE>", in: normalized) ?? "Mercatino"
        let title = extractTagValue(tag: "<#TITOLO>", in: normalized) ?? "Comunicazione"
        let message = extractTagValue(tag: "<#MESSAGGIO>", in: normalized) ?? ""

        return ShopNotification(
            id: filename,
            dateString: date,
            sender: sender,
            title: title,
            message: message,
            rawFilename: filename
        )
    }

    /// Estrae i nomi dei file di notifica dall'HTML del directory listing
    public static func extractNotificationFilenames(from html: String) -> [String] {
        let range = NSRange(location: 0, length: (html as NSString).length)
        let matches = notificationRegex.matches(in: html, options: [], range: range)

        var uniqueFiles = Set<String>()
        let nsString = html as NSString

        for match in matches {
            let matchedText = nsString.substring(with: match.range)
            uniqueFiles.insert(matchedText)
        }

        return uniqueFiles.sorted(by: >)
    }

    /// Esegue il parsing del file ElencoNegozi.txt
    public static func parseShopDirectory(content: String) -> [ShopDetails] {
        let normalized = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        let lines = normalized.components(separatedBy: "\n")
        var shops: [ShopDetails] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            let parts = trimmed.components(separatedBy: "/")
            guard parts.count >= 2 else { continue }

            let name = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let slug = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let address = parts.count > 2 ? parts[2].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            let cityZip = parts.count > 3 ? parts[3].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            let phone = parts.count > 4 ? parts[4].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            let email = parts.count > 6 ? parts[6].trimmingCharacters(in: .whitespacesAndNewlines) : (parts.count > 5 ? parts[5].trimmingCharacters(in: .whitespacesAndNewlines) : "")

            let shop = ShopDetails(
                name: name,
                slug: slug,
                address: address,
                cityZip: cityZip,
                phone: phone,
                email: email
            )
            shops.append(shop)
        }

        return shops
    }

    /// Esegue il parsing della stringa Orario.txt
    public static func parseSchedule(content: String) -> [DaySchedule] {
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

        return scheduleList
    }

    /// Helper per estrarre il testo tra un tag e il successivo tag <# o fine file
    private static func extractTagValue(tag: String, in text: String) -> String? {
        guard let tagRange = text.range(of: tag) else { return nil }
        let afterTag = text[tagRange.upperBound...]
        if let nextTagRange = afterTag.range(of: "<#") {
            let val = String(afterTag[..<nextTagRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            return val
        } else {
            let val = String(afterTag).trimmingCharacters(in: .whitespacesAndNewlines)
            return val
        }
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
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.isEmpty {
            return nil
        }

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
