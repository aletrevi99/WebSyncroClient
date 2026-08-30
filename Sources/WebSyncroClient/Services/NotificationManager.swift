import Foundation
#if canImport(UserNotifications)
import UserNotifications
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Modello di un evento di reso (articolo restituito durante il periodo di recesso)
public struct ReturnEvent: Identifiable, Codable, Sendable {
    public let id: String
    public let itemId: String
    public let title: String
    public let amount: Decimal
    public let date: Date
    public let shopId: String

    public init(id: String = UUID().uuidString, itemId: String, title: String, amount: Decimal, date: Date = Date(), shopId: String) {
        self.id = id
        self.itemId = itemId
        self.title = title
        self.amount = amount
        self.date = date
        self.shopId = shopId
    }
}

/// Gestore centrale delle notifiche locali di sistema e del tracciamento resi / scadenze
@MainActor
public final class NotificationManager: ObservableObject {
    public static let shared = NotificationManager()

    @Published public var activeReturnAlert: ReturnEvent?
    @Published public var permissionGranted = false

    private let userDefaults = UserDefaults.standard
    private let returnsStorageKey = "it.websyncro.client.returned_events"

    @Published public private(set) var returnHistory: [ReturnEvent] = []

    public override init() {
        super.init()
        #if canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound, .provisional]) { granted, _ in
            Task { @MainActor in
                self.permissionGranted = granted
            }
        }
        #endif
        loadReturnHistory()
        checkPermission()
    }

    public func checkPermission() {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.permissionGranted = (settings.authorizationStatus == .authorized)
            }
        }
        #endif
    }

    public func requestPermission() async -> Bool {
        #if canImport(UserNotifications)
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .provisional])
            Task { @MainActor in
                self.permissionGranted = granted
                #if canImport(UIKit)
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                #endif
            }
            return granted
        } catch {
            return false
        }
        #else
        return false
        #endif
    }

    // MARK: - Tracciamento Resi (Ritorno in Negozio)

    public func loadReturnHistory() {
        if let data = userDefaults.data(forKey: returnsStorageKey),
           let decoded = try? JSONDecoder().decode([ReturnEvent].self, from: data) {
            self.returnHistory = decoded
        }
    }

    private func saveReturnHistory() {
        if let data = try? JSONEncoder().encode(returnHistory) {
            userDefaults.setValue(data, forKey: returnsStorageKey)
        }
    }

    public func recordReturn(itemId: String, title: String, amount: Decimal, shopId: String) {
        let event = ReturnEvent(itemId: itemId, title: title, amount: amount, date: Date(), shopId: shopId)
        returnHistory.insert(event, at: 0)
        saveReturnHistory()
        self.activeReturnAlert = event

        sendLocalNotification(
            title: "⚠️ Articolo Restituito in Negozio",
            body: "L'acquirente ha reso '\(title)' (€ \(CurrencyFormatter.format(decimal: amount))). Il guadagno è annullato e l'oggetto è tornato in vendita.",
            identifier: "return_\(event.id)"
        )
    }

    public func dismissActiveReturnAlert() {
        self.activeReturnAlert = nil
    }

    // MARK: - Invio Notifiche Locali

    public func sendLocalNotification(title: String, body: String, identifier: String, timeInterval: TimeInterval = 1) {
        #if canImport(UserNotifications)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, timeInterval), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Errore invio notifica: \(error.localizedDescription)")
            }
        }
        #endif
    }

    // MARK: - Controlli & Notifiche Scadenze e Saldi

    public func checkAndNotifyLifecycleEvents(items: [InventoryItem], settings: AppSettingsStore) {
        guard settings.notifyExpiringItems || settings.notifyDiscount50 else { return }

        for item in items {
            let days = item.daysSinceLoad()
            if settings.notifyDiscount50 && days == 57 { // 3 giorni prima del passaggio in saldo al 50%
                sendLocalNotification(
                    title: "🏷️ Saldo -50% tra 3 giorni",
                    body: "'\(item.title)' (#\(item.id)) raggiungerà i 60 giorni di esposizione e verrà scontato del 50%.",
                    identifier: "discount_alert_\(item.id)_\(days)"
                )
            } else if settings.notifyExpiringItems && days == 87 { // 3 giorni prima della scadenza a 90gg
                sendLocalNotification(
                    title: "⏰ Scadenza Mandato tra 3 giorni",
                    body: "'\(item.title)' (#\(item.id)) raggiungerà i 90 giorni di esposizione e passerà a maggior realizzo.",
                    identifier: "expiry_alert_\(item.id)_\(days)"
                )
            }
        }
    }

    // MARK: - Test Demo

    public func sendDemoNotification() {
        sendLocalNotification(
            title: "💰 Nuova Vendita Rilevata (In Recesso)",
            body: "È stato venduto 'Libro 3-4' per un rimborso di € 1,13. L'importo sarà riscuotibile tra 14 giorni.",
            identifier: "demo_sale_\(UUID().uuidString)"
        )
    }

    public func simulateDemoReturn() {
        recordReturn(
            itemId: "1260214",
            title: "Libro 2 (Edizione Vintage)",
            amount: Decimal(1.35),
            shopId: "exnovomercatino"
        )
    }
}

