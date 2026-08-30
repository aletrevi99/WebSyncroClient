import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

// MARK: - Sfondo Comune Widget con Liquid Glass Adattivo (Light / Dark)
public struct WidgetGlassBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    private var isDark: Bool {
        colorScheme == .dark
    }

    private var baseColor: Color {
        if isDark {
            return Color(red: 0.08, green: 0.09, blue: 0.12)
        } else {
            return Color(red: 0.95, green: 0.96, blue: 0.98)
        }
    }

    private var orangeGradientColors: [Color] {
        if isDark {
            return [Color.brandOrange.opacity(0.32), Color.brandOrange.opacity(0.10), Color.clear]
        } else {
            return [Color.brandOrange.opacity(0.20), Color.brandOrange.opacity(0.05), Color.clear]
        }
    }

    private var blueGradientColors: [Color] {
        if isDark {
            return [Color.blue.opacity(0.24), Color.indigo.opacity(0.08), Color.clear]
        } else {
            return [Color.blue.opacity(0.14), Color.indigo.opacity(0.04), Color.clear]
        }
    }

    private var borderGradientColors: [Color] {
        if isDark {
            return [
                Color.white.opacity(0.25),
                Color.white.opacity(0.05),
                Color.brandOrange.opacity(0.18),
                Color.white.opacity(0.10)
            ]
        } else {
            return [
                Color.white.opacity(0.90),
                Color.white.opacity(0.35),
                Color.brandOrange.opacity(0.20),
                Color.white.opacity(0.60)
            ]
        }
    }

    public var body: some View {
        ZStack {
            baseColor

            // Sfera luminosa superiore Arancio Brand
            Circle()
                .fill(RadialGradient(colors: orangeGradientColors, center: .center, startRadius: 10, endRadius: 130))
                .frame(width: 240, height: 240)
                .offset(x: -50, y: -70)
                .blur(radius: 28)

            // Sfera luminosa inferiore Zaffiro / Indaco
            Circle()
                .fill(RadialGradient(colors: blueGradientColors, center: .center, startRadius: 15, endRadius: 140))
                .frame(width: 260, height: 260)
                .offset(x: 70, y: 70)
                .blur(radius: 32)

            // Finitura satinata Ultra-Thin Material
            Rectangle()
                .fill(.ultraThinMaterial.opacity(isDark ? 0.45 : 0.30))

            // Bordo speculare cristallo
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: borderGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

// MARK: - Widget 1: Saldo Small
public struct BalanceOverviewSmallWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    public let snapshot: WebSyncroWidgetSnapshot

    public init(snapshot: WebSyncroWidgetSnapshot) {
        self.snapshot = snapshot
    }

    private var pillBackground: Color {
        colorScheme == .dark ? Color.primary.opacity(0.06) : Color.primary.opacity(0.04)
    }

    private var pillStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color.white.opacity(0.60)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header Negozio
            HStack(spacing: 5) {
                Image(systemName: "storefront.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.brandOrange)

                Text(snapshot.shopName.replacingOccurrences(of: " Mercatino", with: ""))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()
            }

            Spacer(minLength: 2)

            // Saldo Maturato
            VStack(alignment: .leading, spacing: 2) {
                Text("MATURATO")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)

                Text(CurrencyFormatter.format(decimal: snapshot.maturedAmount))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)
            }

            Spacer(minLength: 2)

            // Card In Negozio
            HStack(spacing: 4) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.brandOrange)
                Text("\(CurrencyFormatter.format(decimal: snapshot.inShopEstimatedAmount)) (\(snapshot.inShopPiecesCount) pz)")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                ZStack {
                    Capsule().fill(.ultraThinMaterial)
                    Capsule().fill(pillBackground)
                }
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(pillStroke, lineWidth: 0.8)
            )
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Widget 2: Saldo Medium
public struct BalanceOverviewMediumWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    public let snapshot: WebSyncroWidgetSnapshot

    public init(snapshot: WebSyncroWidgetSnapshot) {
        self.snapshot = snapshot
    }

    private var pillBackground: Color {
        colorScheme == .dark ? Color.primary.opacity(0.06) : Color.primary.opacity(0.04)
    }

    private var pillStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color.white.opacity(0.60)
    }

    public var body: some View {
        HStack(spacing: 14) {
            // Sezione Sinistra: Guadagni Maturati e In Recesso
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.brandOrange)
                    Text(snapshot.shopName)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                Spacer(minLength: 2)

                VStack(alignment: .leading, spacing: 1) {
                    Text("MATURATO (RISCUOTIBILE)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(0.3)

                    Text(CurrencyFormatter.format(decimal: snapshot.maturedAmount))
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                        .lineLimit(1)
                }

                Spacer(minLength: 2)

                if snapshot.inRecessoAmount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 8))
                            .foregroundColor(.orange)
                        Text("+ \(CurrencyFormatter.format(decimal: snapshot.inRecessoAmount)) in recesso")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Divisore in vetro
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: 1)
                .padding(.vertical, 4)

            // Sezione Destra: Merce Esposta in Negozio
            VStack(alignment: .leading, spacing: 4) {
                Text("IN NEGOZIO")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(0.3)

                Text(CurrencyFormatter.format(decimal: snapshot.inShopEstimatedAmount))
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("Valore residuo stima")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)

                Spacer(minLength: 2)

                HStack(spacing: 6) {
                    Label("\(snapshot.inShopPiecesCount) pz", systemImage: "storefront.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.brandOrange)

                    Text("•")
                        .foregroundColor(.secondary)

                    Label("\(snapshot.soldPiecesCount) venduti", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    ZStack {
                        Capsule().fill(.ultraThinMaterial)
                        Capsule().fill(pillBackground)
                    }
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(pillStroke, lineWidth: 0.8)
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Widget 3: Ultime Vendite Medium
public struct RecentSalesMediumWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    public let snapshot: WebSyncroWidgetSnapshot

    public init(snapshot: WebSyncroWidgetSnapshot) {
        self.snapshot = snapshot
    }

    private var rowBackground: Color {
        colorScheme == .dark ? Color.primary.opacity(0.05) : Color.primary.opacity(0.03)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.brandOrange)
                    Text("Ultime Vendite")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }

                Spacer()

                Text("Tot. \(CurrencyFormatter.format(decimal: snapshot.maturedAmount))")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
            }

            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 1)

            // Lista Vendite con capsule Liquid Glass
            if snapshot.recentSales.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("Nessuna vendita registrata di recente")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                Spacer()
            } else {
                VStack(spacing: 4) {
                    ForEach(snapshot.recentSales.prefix(3)) { item in
                        HStack(spacing: 7) {
                            Circle()
                                .fill(item.isMatured ? Color.green : Color.orange)
                                .frame(width: 6, height: 6)

                            Text(item.title)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Spacer()

                            Text(item.dateFormatted)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)

                            Text(CurrencyFormatter.format(decimal: item.amount))
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(item.isMatured ? .green : .orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(rowBackground)
                        )
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Widget 4: Saldi & Scadenze Medium
public struct ExpiringDiscountsMediumWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    public let snapshot: WebSyncroWidgetSnapshot

    public init(snapshot: WebSyncroWidgetSnapshot) {
        self.snapshot = snapshot
    }

    private var rowBackground: Color {
        colorScheme == .dark ? Color.primary.opacity(0.05) : Color.primary.opacity(0.03)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "clock.badge.exclamationmark.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.orange)
                    Text("Saldi & Scadenze")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }

                Spacer()

                Text("\(snapshot.inShopPiecesCount) pz in negozio")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 1)

            if snapshot.expiringItems.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("Nessun articolo in scadenza a breve")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                Spacer()
            } else {
                VStack(spacing: 4) {
                    ForEach(snapshot.expiringItems.prefix(3)) { item in
                        HStack(spacing: 7) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.brandOrange)

                            Text(item.title)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Spacer()

                            Text("Tra \(item.daysRemaining) gg")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(rowBackground)
                        )
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Widget 5: Tessera Rapida Medium
public struct QuickCardMediumWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    public let snapshot: WebSyncroWidgetSnapshot

    public init(snapshot: WebSyncroWidgetSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: "person.text.rectangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.brandOrange)
                    Text("Tessera Fornitore")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }

                Text(snapshot.shopName)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer(minLength: 2)

                Text(snapshot.cardCode)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.brandOrange)

                Text("Saldo: \(CurrencyFormatter.format(decimal: snapshot.maturedAmount))")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Barcode
            VStack(spacing: 3) {
                HStack(spacing: 2) {
                    ForEach(0..<22, id: \.self) { i in
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: (i % 3 == 0 ? 3 : (i % 2 == 0 ? 2 : 1.2)), height: 44)
                    }
                }
                .padding(6)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)

                Text("Mostra in cassa")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
