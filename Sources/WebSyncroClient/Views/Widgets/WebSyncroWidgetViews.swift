import SwiftUI

/// Collezione di viste SwiftUI native Liquid Glass per i Widget iOS (Home Screen, Lock Screen e StandBy)
public struct BalanceOverviewSmallWidgetView: View {
    public let snapshot: WebSyncroWidgetSnapshot

    public init(snapshot: WebSyncroWidgetSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        ZStack {
            widgetBackgroundGradient

            VStack(alignment: .leading, spacing: 6) {
                // Header Negozio
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.brandOrange)
                        .frame(width: 7, height: 7)
                    Text(snapshot.shopName.replacingOccurrences(of: " Mercatino", with: ""))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                }

                Spacer(minLength: 2)

                // Saldo Maturato
                VStack(alignment: .leading, spacing: 1) {
                    Text("MATURATO")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(0.5)

                    Text(CurrencyFormatter.format(decimal: snapshot.maturedAmount))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }

                Spacer(minLength: 2)

                // Pill In Negozio
                HStack(spacing: 4) {
                    Image(systemName: "storefront.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.brandOrange)
                    Text("\(CurrencyFormatter.format(decimal: snapshot.inShopEstimatedAmount)) (\(snapshot.inShopPiecesCount) pz)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
            .padding(12)
        }
    }
}

public struct BalanceOverviewMediumWidgetView: View {
    public let snapshot: WebSyncroWidgetSnapshot

    public init(snapshot: WebSyncroWidgetSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        ZStack {
            widgetBackgroundGradient

            HStack(spacing: 12) {
                // Sezione Sinistra: Guadagni Maturati e In Recesso
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.brandOrange)
                            .frame(width: 8, height: 8)
                        Text(snapshot.shopName)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 1) {
                        Text("MATURATO (RISCUOTIBILE)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(0.3)

                        Text(CurrencyFormatter.format(decimal: snapshot.maturedAmount))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                            .lineLimit(1)
                    }

                    if snapshot.inRecessoAmount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "hourglass")
                                .font(.system(size: 8))
                                .foregroundColor(.orange)
                            Text("+ \(CurrencyFormatter.format(decimal: snapshot.inRecessoAmount)) in recesso")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .background(Color.white.opacity(0.12))

                // Sezione Destra: Merce Esposta in Negozio
                VStack(alignment: .leading, spacing: 6) {
                    Text("IN NEGOZIO")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(0.3)

                    Text(CurrencyFormatter.format(decimal: snapshot.inShopEstimatedAmount))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("Valore residuo stimato")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)

                    Spacer()

                    HStack(spacing: 8) {
                        Label("\(snapshot.inShopPiecesCount) pz", systemImage: "storefront.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.brandOrange)

                        Label("\(snapshot.soldPiecesCount) venduti", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
        }
    }
}

public struct RecentSalesMediumWidgetView: View {
    public let snapshot: WebSyncroWidgetSnapshot

    public init(snapshot: WebSyncroWidgetSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        ZStack {
            widgetBackgroundGradient

            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Label("Ultime Vendite", systemImage: "cart.fill")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.brandOrange)

                    Spacer()

                    Text(CurrencyFormatter.format(decimal: snapshot.maturedAmount))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                // Lista Vendite
                VStack(spacing: 6) {
                    ForEach(snapshot.recentSales.prefix(3)) { item in
                        HStack(spacing: 8) {
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
                    }
                }
            }
            .padding(14)
        }
    }
}

public struct QuickCardMediumWidgetView: View {
    public let snapshot: WebSyncroWidgetSnapshot

    public init(snapshot: WebSyncroWidgetSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        ZStack {
            widgetBackgroundGradient

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.text.rectangle.fill")
                            .foregroundColor(.brandOrange)
                        Text("Tessera Fornitore")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }

                    Text(snapshot.shopName)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(snapshot.cardCode)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.brandOrange)

                    Text("Saldo: \(CurrencyFormatter.format(decimal: snapshot.maturedAmount))")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Mock Barcode
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        ForEach(0..<20, id: \.self) { i in
                            Rectangle()
                                .fill(Color.primary)
                                .frame(width: (i % 3 == 0 ? 3 : (i % 2 == 0 ? 2 : 1)), height: 46)
                        }
                    }
                    .padding(6)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text("Mostra in cassa")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(14)
        }
    }
}

public struct ExpiringDiscountsMediumWidgetView: View {
    public let snapshot: WebSyncroWidgetSnapshot

    public init(snapshot: WebSyncroWidgetSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        ZStack {
            widgetBackgroundGradient

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Saldi & Scadenze", systemImage: "clock.badge.exclamationmark.fill")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)

                    Spacer()

                    Text("\(snapshot.inShopPiecesCount) pz esposti")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                VStack(spacing: 6) {
                    ForEach(snapshot.expiringItems.prefix(3)) { item in
                        HStack(spacing: 8) {
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
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(14)
        }
    }
}

// MARK: - Sfondo Comune Widget
private var widgetBackgroundGradient: some View {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.13, blue: 0.16),
                Color(red: 0.08, green: 0.09, blue: 0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        Circle()
            .fill(Color.brandOrange.opacity(0.12))
            .blur(radius: 25)
            .offset(x: 40, y: -40)

        Circle()
            .fill(Color.green.opacity(0.08))
            .blur(radius: 30)
            .offset(x: -50, y: 50)
    }
}

