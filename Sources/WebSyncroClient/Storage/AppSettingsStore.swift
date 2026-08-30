import Foundation
import Combine

/// Gestore delle preferenze globali dell'applicazione: modalità EX NOVO, Motore AI Vision e Notifiche
@MainActor
public final class AppSettingsStore: ObservableObject {
    public static let shared = AppSettingsStore()

    private let userDefaults: UserDefaults
    private let exNovoOnlyKey = "it.websyncro.client.exnovo_only_mode"
    private let openRouterApiKeyKey = "it.websyncro.client.openrouter_api_key"
    private let openRouterModelKey = "it.websyncro.client.openrouter_model"

    // Notifiche
    private let notifyNewSalesKey = "it.websyncro.client.notify_new_sales"
    private let notifyMaturedCreditsKey = "it.websyncro.client.notify_matured_credits"
    private let notifyDiscount50Key = "it.websyncro.client.notify_discount_50"
    private let notifyExpiringItemsKey = "it.websyncro.client.notify_expiring_items"
    private let notifyReturnsKey = "it.websyncro.client.notify_returns"
    private let bgRefreshIntervalKey = "it.websyncro.client.bg_refresh_interval"

    /// Se attivo, l'app si comporta come client esclusivo EX NOVO
    @Published public var isExNovoOnlyMode: Bool {
        didSet { userDefaults.setValue(isExNovoOnlyMode, forKey: exNovoOnlyKey) }
    }

    /// Chiave API OpenRouter
    @Published public var openRouterApiKey: String {
        didSet { userDefaults.setValue(openRouterApiKey, forKey: openRouterApiKeyKey) }
    }

    /// Modello OpenRouter
    @Published public var openRouterModel: String {
        didSet { userDefaults.setValue(openRouterModel, forKey: openRouterModelKey) }
    }

    // Preferenze Notifiche
    @Published public var notifyNewSales: Bool {
        didSet { userDefaults.setValue(notifyNewSales, forKey: notifyNewSalesKey) }
    }

    @Published public var notifyMaturedCredits: Bool {
        didSet { userDefaults.setValue(notifyMaturedCredits, forKey: notifyMaturedCreditsKey) }
    }

    @Published public var notifyDiscount50: Bool {
        didSet { userDefaults.setValue(notifyDiscount50, forKey: notifyDiscount50Key) }
    }

    @Published public var notifyExpiringItems: Bool {
        didSet { userDefaults.setValue(notifyExpiringItems, forKey: notifyExpiringItemsKey) }
    }

    @Published public var notifyReturns: Bool {
        didSet { userDefaults.setValue(notifyReturns, forKey: notifyReturnsKey) }
    }

    @Published public var backgroundRefreshIntervalMinutes: Int {
        didSet { userDefaults.setValue(backgroundRefreshIntervalMinutes, forKey: bgRefreshIntervalKey) }
    }

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if userDefaults.object(forKey: exNovoOnlyKey) != nil {
            self.isExNovoOnlyMode = userDefaults.bool(forKey: exNovoOnlyKey)
        } else {
            self.isExNovoOnlyMode = true
        }

        self.openRouterApiKey = userDefaults.string(forKey: openRouterApiKeyKey) ?? ""
        self.openRouterModel = userDefaults.string(forKey: openRouterModelKey) ?? "google/gemini-2.5-flash"

        // Defaults Notifiche (tutti attivi per la migliore UX)
        self.notifyNewSales = userDefaults.object(forKey: notifyNewSalesKey) != nil ? userDefaults.bool(forKey: notifyNewSalesKey) : true
        self.notifyMaturedCredits = userDefaults.object(forKey: notifyMaturedCreditsKey) != nil ? userDefaults.bool(forKey: notifyMaturedCreditsKey) : true
        self.notifyDiscount50 = userDefaults.object(forKey: notifyDiscount50Key) != nil ? userDefaults.bool(forKey: notifyDiscount50Key) : true
        self.notifyExpiringItems = userDefaults.object(forKey: notifyExpiringItemsKey) != nil ? userDefaults.bool(forKey: notifyExpiringItemsKey) : true
        self.notifyReturns = userDefaults.object(forKey: notifyReturnsKey) != nil ? userDefaults.bool(forKey: notifyReturnsKey) : true
        self.backgroundRefreshIntervalMinutes = userDefaults.object(forKey: bgRefreshIntervalKey) != nil ? userDefaults.integer(forKey: bgRefreshIntervalKey) : 30
    }

    public func makeVisionService() -> VisionLLMServiceProtocol {
        OpenRouterVisionService(apiKey: openRouterApiKey, model: openRouterModel)
    }
}
