import Foundation

public enum CurrencyFormatter {
    private static let euroFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "it_IT")
        formatter.currencySymbol = "€"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static let compactEuroFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "it_IT")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    /// Formatta un valore Decimal in stringa valuta italiana (es. "€ 1.234,56")
    public static func format(decimal: Decimal) -> String {
        let nsDecimal = NSDecimalNumber(decimal: decimal)
        return euroFormatter.string(from: nsDecimal) ?? "\(decimal) €"
    }

    /// Formatta solo il valore numerico con decimali italiani (es. "1.234,56")
    public static func formatPlain(decimal: Decimal) -> String {
        let nsDecimal = NSDecimalNumber(decimal: decimal)
        return compactEuroFormatter.string(from: nsDecimal) ?? "\(decimal)"
    }
}

