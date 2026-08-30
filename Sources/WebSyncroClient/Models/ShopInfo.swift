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

/// Dettagli anagrafici e recapiti completi del negozio (da ElencoNegozi.txt)
public struct ShopDetails: Identifiable, Hashable, Sendable, Codable {
    public var id: String { slug }
    public let name: String          // Es. "EX Novo"
    public let slug: String          // Es. "exnovomercatino"
    public let address: String       // Es. "Via Vicenza 23"
    public let cityZip: String       // Es. "31050 Vedelago (TV)"
    public let phone: String         // Es. "042 3700120"
    public let email: String         // Es. "info@exnovomercatino.it"
    public var schedule: [DaySchedule]

    public init(
        name: String,
        slug: String,
        address: String,
        cityZip: String,
        phone: String,
        email: String,
        schedule: [DaySchedule] = []
    ) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.slug = slug.trimmingCharacters(in: .whitespacesAndNewlines)
        self.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        self.cityZip = cityZip.trimmingCharacters(in: .whitespacesAndNewlines)
        self.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        self.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
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
}
