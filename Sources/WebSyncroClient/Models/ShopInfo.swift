import Foundation

/// Orario di apertura per un singolo giorno della settimana
public struct DaySchedule: Identifiable, Hashable, Sendable, Codable {
    public let id: Int // 0: Lunedì, 1: Martedì, ..., 6: Domenica
    public let dayName: String
    public let isClosed: Bool
    public let morningHours: String?
    public let afternoonHours: String?

    public init(
        id: Int,
        dayName: String,
        isClosed: Bool,
        morningHours: String?,
        afternoonHours: String?
    ) {
        self.id = id
        self.dayName = dayName
        self.isClosed = isClosed
        self.morningHours = morningHours
        self.afternoonHours = afternoonHours
    }

    /// Stringa leggibile degli orari del giorno
    public var formattedHours: String {
        if isClosed {
            return "Chiuso"
        }
        var parts: [String] = []
        if let m = morningHours, !m.isEmpty {
            parts.append(m)
        }
        if let a = afternoonHours, !a.isEmpty {
            parts.append(a)
        }
        return parts.isEmpty ? "Chiuso" : parts.joined(separator: "  •  ")
    }
}

/// Dettagli anagrafici e recapiti completi del negozio
public struct ShopDetails: Identifiable, Hashable, Sendable, Codable {
    public var id: String { slug }
    public let name: String          // Es. "EX Novo"
    public let slug: String          // Es. "exnovomercatino"
    public let address: String       // Es. "Via Vicenza 23"
    public let cityZip: String       // Es. "31050 Vedelago (TV)"
    public let phone: String         // Es. "042 3700120"
    public let email: String         // Es. "info@exnovomercatino.it"
    public let website: String       // Es. "https://www.exnovomercatino.it"
    public var schedule: [DaySchedule]

    public init(
        name: String,
        slug: String,
        address: String,
        cityZip: String,
        phone: String,
        email: String,
        website: String = "",
        schedule: [DaySchedule] = []
    ) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.slug = slug.trimmingCharacters(in: .whitespacesAndNewlines)
        self.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        self.cityZip = cityZip.trimmingCharacters(in: .whitespacesAndNewlines)
        self.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        self.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let trimmedWeb = website.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedWeb.isEmpty {
            self.website = trimmedWeb
        } else if slug.caseInsensitiveCompare("exnovomercatino") == .orderedSame {
            self.website = "https://www.exnovomercatino.it"
        } else {
            self.website = ""
        }

        self.schedule = schedule
    }

    /// Indirizzo completo formattato
    public var fullAddress: String {
        [address, cityZip].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    /// Ritorna l'orario di oggi
    public var todaySchedule: DaySchedule? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        // In Calendar: 1 = Domenica, 2 = Lunedì, ..., 7 = Sabato
        let dayIndex = (weekday == 1) ? 6 : (weekday - 2)
        return schedule.first(where: { $0.id == dayIndex })
    }

    /// Telefono pulito per URL scheme tel:
    public var cleanPhoneNumber: String {
        phone.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "/", with: "")
    }

    /// Calcola lo stato di apertura in tempo reale (Aperto adesso, Pausa pranzo, Chiuso)
    public var currentOpenStatus: (isOpen: Bool, statusText: String, detailText: String) {
        guard let today = todaySchedule, !today.isClosed else {
            return (false, "CHIUSO OGGI", "Oggi il mercatino è chiuso per turno.")
        }

        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotalMinutes = currentHour * 60 + currentMinute

        func parseRange(_ rangeString: String?) -> (start: Int, end: Int)? {
            guard let range = rangeString else { return nil }
            let parts = range.components(separatedBy: "-")
            guard parts.count == 2 else { return nil }
            
            let sParts = parts[0].trimmingCharacters(in: .whitespaces).components(separatedBy: ":")
            let eParts = parts[1].trimmingCharacters(in: .whitespaces).components(separatedBy: ":")
            guard sParts.count == 2, eParts.count == 2,
                  let sH = Int(sParts[0]), let sM = Int(sParts[1]),
                  let eH = Int(eParts[0]), let eM = Int(eParts[1]) else { return nil }

            return (sH * 60 + sM, eH * 60 + eM)
        }

        let morning = parseRange(today.morningHours)
        let afternoon = parseRange(today.afternoonHours)

        // Controllo mattina
        if let m = morning {
            if currentTotalMinutes >= m.start && currentTotalMinutes < m.end {
                let closeTime = today.morningHours?.components(separatedBy: "-").last?.trimmingCharacters(in: .whitespaces) ?? ""
                return (true, "APERTO ADESSO", "Aperto fino alle \(closeTime)")
            } else if currentTotalMinutes < m.start {
                let openTime = today.morningHours?.components(separatedBy: "-").first?.trimmingCharacters(in: .whitespaces) ?? ""
                return (false, "CHIUSO ORA", "Apre stamattina alle \(openTime)")
            }
        }

        // Controllo pausa pranzo
        if let m = morning, let a = afternoon {
            if currentTotalMinutes >= m.end && currentTotalMinutes < a.start {
                let openTime = today.afternoonHours?.components(separatedBy: "-").first?.trimmingCharacters(in: .whitespaces) ?? ""
                return (false, "PAUSA PRANZO", "Riapre oggi pomeriggio alle \(openTime)")
            }
        }

        // Controllo pomeriggio
        if let a = afternoon {
            if currentTotalMinutes >= a.start && currentTotalMinutes < a.end {
                let closeTime = today.afternoonHours?.components(separatedBy: "-").last?.trimmingCharacters(in: .whitespaces) ?? ""
                return (true, "APERTO ADESSO", "Aperto fino alle \(closeTime)")
            } else if currentTotalMinutes >= a.end {
                return (false, "CHIUSO", "Chiuso per fine giornata lavorativa.")
            }
        }

        return (false, "CHIUSO", "Attualmente fuori orario di apertura.")
    }
}
