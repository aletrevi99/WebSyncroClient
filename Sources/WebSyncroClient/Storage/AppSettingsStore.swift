import Foundation
import Combine

/// Gestore delle preferenze globali dell'applicazione, modalità EX NOVO e diagnostica
@MainActor
public final class AppSettingsStore: ObservableObject {
    public static let shared = AppSettingsStore()

    private let userDefaults: UserDefaults
    private let exNovoOnlyKey = "it.websyncro.client.exnovo_only_mode"
    private let ocrEngineKey = "it.websyncro.client.ocr_engine"
    private let customApiKey = "it.websyncro.client.custom_api_key"

    /// Se attivo, l'app si comporta come client esclusivo EX NOVO (nascondendo la scelta di altri mercatini)
    @Published public var isExNovoOnlyMode: Bool {
        didSet {
            userDefaults.setValue(isExNovoOnlyMode, forKey: exNovoOnlyKey)
        }
    }

    /// Motore OCR preferito (2D Spatial Vision nativo o LLM Cloud)
    @Published public var ocrEngine: String {
        didSet {
            userDefaults.setValue(ocrEngine, forKey: ocrEngineKey)
        }
    }

    @Published public var customVisionApiKey: String {
        didSet {
            userDefaults.setValue(customVisionApiKey, forKey: customApiKey)
        }
    }

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        // Default a true per l'esperienza dedicata EX NOVO
        if userDefaults.object(forKey: exNovoOnlyKey) != nil {
            self.isExNovoOnlyMode = userDefaults.bool(forKey: exNovoOnlyKey)
        } else {
            self.isExNovoOnlyMode = true
        }

        self.ocrEngine = userDefaults.string(forKey: ocrEngineKey) ?? "spatial_vision"
        self.customVisionApiKey = userDefaults.string(forKey: customApiKey) ?? ""
    }
}
