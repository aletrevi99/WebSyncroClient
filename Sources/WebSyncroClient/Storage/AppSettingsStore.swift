import Foundation
import Combine

/// Gestore delle preferenze globali dell'applicazione, modalità EX NOVO, LLM Vision e diagnostica
@MainActor
public final class AppSettingsStore: ObservableObject {
    public static let shared = AppSettingsStore()

    private let userDefaults: UserDefaults
    private let exNovoOnlyKey = "it.websyncro.client.exnovo_only_mode"
    private let visionProviderKey = "it.websyncro.client.vision_provider"
    private let openRouterApiKeyKey = "it.websyncro.client.openrouter_api_key"
    private let openRouterModelKey = "it.websyncro.client.openrouter_model"
    private let localModelEndpointKey = "it.websyncro.client.local_model_endpoint"
    private let localModelNameKey = "it.websyncro.client.local_model_name"

    /// Se attivo, l'app si comporta come client esclusivo EX NOVO (nascondendo la scelta di altri mercatini)
    @Published public var isExNovoOnlyMode: Bool {
        didSet {
            userDefaults.setValue(isExNovoOnlyMode, forKey: exNovoOnlyKey)
        }
    }

    /// Provider Vision attivo: "openrouter" | "local_llm" | "spatial_vision"
    @Published public var visionProvider: String {
        didSet {
            userDefaults.setValue(visionProvider, forKey: visionProviderKey)
        }
    }

    /// Chiave API OpenRouter
    @Published public var openRouterApiKey: String {
        didSet {
            userDefaults.setValue(openRouterApiKey, forKey: openRouterApiKeyKey)
        }
    }

    /// Modello OpenRouter (es. "google/gemini-2.5-flash", "openai/gpt-4o-mini", "anthropic/claude-3.5-haiku", "qwen/qwen-2.5-vl-72b-instruct")
    @Published public var openRouterModel: String {
        didSet {
            userDefaults.setValue(openRouterModel, forKey: openRouterModelKey)
        }
    }

    /// Endpoint server locale per LLM Vision (es. "http://localhost:11434" per Ollama)
    @Published public var localModelEndpoint: String {
        didSet {
            userDefaults.setValue(localModelEndpoint, forKey: localModelEndpointKey)
        }
    }

    /// Nome modello locale per Ollama
    @Published public var localModelName: String {
        didSet {
            userDefaults.setValue(localModelName, forKey: localModelNameKey)
        }
    }

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if userDefaults.object(forKey: exNovoOnlyKey) != nil {
            self.isExNovoOnlyMode = userDefaults.bool(forKey: exNovoOnlyKey)
        } else {
            self.isExNovoOnlyMode = true
        }

        self.visionProvider = userDefaults.string(forKey: visionProviderKey) ?? "openrouter"
        self.openRouterApiKey = userDefaults.string(forKey: openRouterApiKeyKey) ?? ""
        self.openRouterModel = userDefaults.string(forKey: openRouterModelKey) ?? "google/gemini-2.5-flash"
        self.localModelEndpoint = userDefaults.string(forKey: localModelEndpointKey) ?? "http://localhost:11434"
        self.localModelName = userDefaults.string(forKey: localModelNameKey) ?? "llava:latest"
    }

    public func makeVisionService() -> VisionLLMServiceProtocol {
        if visionProvider == "local_llm" {
            return LocalVisionLLMService(endpointURL: localModelEndpoint, modelName: localModelName)
        } else {
            return OpenRouterVisionService(apiKey: openRouterApiKey, model: openRouterModel)
        }
    }
}
