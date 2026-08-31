import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

// MARK: - Sfondo Comune Widget Nativo
public struct WidgetGlassBackgroundView: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .glassEffect()
    }
}

// MARK: - Widget 1: Saldo Small
public struct BalanceOverviewSmallWidgetView: View {
    public let snapshot: WebSyncroWidgetSnapshot

    public init(snapshot: WebSyncroWidgetSnapshot) {
        self.snapshot = snapshot
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
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .glassEffect(in: .capsule)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Widget 2: Saldo Medium
public struct BalanceOverviewMediumWidgetView: View {
    public let snapshot: WebSyncroWidgetSnapshot

    public init(snapshot: WebSyncroWidgetSnapshot) {
        self.snapshot = snapshot
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
                    .glassEffect(in: .capsule)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Divisore
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
                .glassEffect(in: .capsule)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Widget 3: Ultime Vendite Medium
public struct RecentSalesMediumWidgetView: View {
    public let snapshot: WebSyncroWidgetSnapshot

    public init(snapshot: WebSyncroWidgetSnapshot) {
        self.snapshot = snapshot
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
                    .glassEffect(in: .capsule)
            }

            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 1)

            // Lista Vendite
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
                        .glassEffect(in: .rect(cornerRadius: 8))
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
    public let snapshot: WebSyncroWidgetSnapshot

    public init(snapshot: WebSyncroWidgetSnapshot) {
        self.snapshot = snapshot
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
                                .glassEffect(in: .capsule)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .glassEffect(in: .rect(cornerRadius: 8))
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
