#if canImport(WidgetKit)
import WidgetKit
import SwiftUI

// MARK: - Timeline Provider per i Widget WebSyncro
struct WebSyncroTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WebSyncroWidgetEntry {
        WebSyncroWidgetEntry(date: Date(), snapshot: WebSyncroWidgetSnapshot())
    }

    func getSnapshot(in context: Context, completion: @escaping (WebSyncroWidgetEntry) -> Void) {
        let snapshot = WidgetDataProvider.loadSnapshot()
        completion(WebSyncroWidgetEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WebSyncroWidgetEntry>) -> Void) {
        let snapshot = WidgetDataProvider.loadSnapshot()
        let entry = WebSyncroWidgetEntry(date: Date(), snapshot: snapshot)

        // Aggiorna ogni 30 minuti
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct WebSyncroWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WebSyncroWidgetSnapshot
}

// MARK: - Widget 1: Saldo Maturato & In Negozio
public struct BalanceOverviewWidget: Widget {
    public let kind: String = "BalanceOverviewWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WebSyncroTimelineProvider()) { entry in
            BalanceOverviewWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Saldo & Negozio")
        .description("Controlla il saldo maturato da ritirare in cassa e il valore residuo esposto.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct BalanceOverviewWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WebSyncroWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            BalanceOverviewSmallWidgetView(snapshot: entry.snapshot)
        default:
            BalanceOverviewMediumWidgetView(snapshot: entry.snapshot)
        }
    }
}

// MARK: - Widget 2: Ultime Vendite Feed
public struct RecentSalesWidget: Widget {
    public let kind: String = "RecentSalesWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WebSyncroTimelineProvider()) { entry in
            RecentSalesMediumWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Ultime Vendite")
        .description("Visualizza gli ultimi articoli venduti e il guadagno netto.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Widget 3: Saldi in Arrivo & Scadenze
public struct ExpiringDiscountsWidget: Widget {
    public let kind: String = "ExpiringDiscountsWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WebSyncroTimelineProvider()) { entry in
            ExpiringDiscountsMediumWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Saldi & Scadenze")
        .description("Monitora il passaggio a saldo al 50% e le scadenze del mandato.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Widget 4: Tessera Fornitore Rapida
public struct QuickCardWidget: Widget {
    public let kind: String = "QuickCardWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WebSyncroTimelineProvider()) { entry in
            QuickCardMediumWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Tessera Rapida")
        .description("Codice cliente e tessera digitale per il ritiro e controllo in cassa.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Widget Bundle Principale
@main
struct WebSyncroWidgetBundle: WidgetBundle {
    var body: some Widget {
        BalanceOverviewWidget()
        RecentSalesWidget()
        ExpiringDiscountsWidget()
        QuickCardWidget()
    }
}
#endif
