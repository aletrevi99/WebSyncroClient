import Foundation

public extension Date {
    /// Formattatore standard italiano per date vendite "dd/MM/yyyy"
    private static let saleDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.timeZone = TimeZone(identifier: "Europe/Rome") ?? TimeZone.current
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    /// Converte una stringa "dd/MM/yyyy" in Date
    static func fromSaleDateString(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return saleDateFormatter.date(from: trimmed)
    }

    /// Ritorna la stringa "dd/MM/yyyy"
    var toSaleDateString: String {
        return Self.saleDateFormatter.string(from: self)
    }

    /// Ritorna una formattazione leggibile relativa (es. "Oggi", "Ieri", o mese/anno)
    var relativeDayString: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return "Oggi"
        } else if calendar.isDateInYesterday(self) {
            return "Ieri"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "it_IT")
            formatter.dateFormat = "d MMMM yyyy"
            return formatter.string(from: self)
        }
    }

    /// Sezione mese/anno per raggruppare le vendite (es. "Agosto 2026")
    var monthYearSection: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "LLLL yyyy"
        let raw = formatter.string(from: self)
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }
}

