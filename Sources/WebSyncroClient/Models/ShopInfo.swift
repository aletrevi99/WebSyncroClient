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

/// Modello informativo del negozio con orari settimanali
public struct ShopInfo: Hashable, Sendable, Codable {
    public let shopId: String
    public let schedule: [DaySchedule]
    public let rawSchedule: String

    public init(shopId: String, schedule: [DaySchedule], rawSchedule: String) {
        self.shopId = shopId
        self.schedule = schedule
        self.rawSchedule = rawSchedule
    }

    /// Ritorna l'orario di oggi
    public var todaySchedule: DaySchedule? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        // In Calendar: 1 = Domenica, 2 = Lunedì, ..., 7 = Sabato
        let dayIndex = (weekday == 1) ? 6 : (weekday - 2)
        return schedule.first(where: { $0.id == dayIndex })
    }
}
