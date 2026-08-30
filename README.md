# WebSyncro Mercatini — Client iOS Nativo (SwiftUI)

Client nativo per iOS 17+ sviluppato in Swift e SwiftUI con architettura modulare **MVVM**, progettato per monitorare le vendite e gli importi maturati dal sistema di gestione mercatini dell'usato **WebSyncro**.

---

## 💎 Caratteristiche Principali

### 1. Native Liquid Glass Design System
- **Materiali di Sistema Apple**: Uso esclusivo di `.ultraThinMaterial`, `.thinMaterial`, sfocature progressive e riflessi speculari traslucidi.
- **Supporto Dinamico Dark / Light Mode**: Palette colori, bordi sfumati con `Color.white.opacity(0.15)` e ombre adattive per la massima leggibilità in ogni condizione di luminosità.
- **Tipografia SF Pro**: Pesi semibold/bold con formattazione numerica monospaziata per gli importi monetari (€) e gerarchie secondarie per ID e date.
- **Pull-to-Refresh & Aptica**: Interazioni tattili immersive con `UIImpactFeedbackGenerator` e `UINotificationFeedbackGenerator`.

### 2. Reverse Engineering di Rete WebSyncro (Flusso a 2 Fasi)
L'applicazione implementa la comunicazione diretta con i server WebSyncro:
- **Base Host**: `https://www.appwebsyncro.it/WebSyncro/ClientiWebSyncro/Negozi/{shop_id}`
- **User-Agent Obbligatorio**: `ExnovoMercatino/1.2 CFNetwork/3896.100.1.2.1 Darwin/27.0.0`
- **Cache Policy**: `URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData` (bypass cache per garantire snapshot sempre aggiornati).

#### Flusso di Risoluzione:
1. **Fase 1 (Scraping Directory Listing)**: Esegue una richiesta `GET` all'indice del negozio, analizza il listato HTML tramite regex (`SM_\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}`) e individua la directory di snapshot più recente in ordine cronologico decrescente.
2. **Fase 2 (Download maturato.txt)**: Scarica il file dal percorso `.../{shop_id}/{latest_sync_folder}/{user_id}/maturato.txt` e ne decodifica i caratteri con fallback di codifica (UTF-8, Windows-1252, ISO-8859-1).

### 3. Parser Resiliente (`SalesParser`)
- Parsing a righe alternate dei record prima del delimitatore `<#FINEELENCO>`.
- Gestione automatica e bonifica di anomalie di codifica (es. simbolo `€` malformato come `â¬` o `\u{00E2}\u{00AC}`).
- Estrazione dei metadati facoltativi post-delimitatore (`<#FRASEOPZIONALE>` e avvisi in cassa).
- Gestione di righe descrizione mancanti con fallback intelligenti su `#ID`.

### 4. Supporto Multi-Utente e Multi-Negozio
- Gestione completa di più account con ID Negozio, ID Utente e Alias personalizzato.
- Switcher rapido nella navigation bar per passare da un account all'altro con aggiornamento immediato della vista.
- Memorizzazione sicura e reattiva tramite `AccountStore`.
- Modalità Demo integrata per testare l'interfaccia con dati simulati anche senza rete.

---

## 🏛️ Architettura del Progetto

```
WebSyncroClient/
├── Package.swift
├── Sources/WebSyncroClient/
│   ├── App/
│   │   ├── AppState.swift                   # Coordinatore di stato globale
│   │   └── WebSyncroApp.swift               # Entry point SwiftUI App
│   ├── Models/
│   │   ├── Models.swift                     # SaleItem, SalesReport
│   │   ├── UserAccount.swift                # Modello account e negozio
│   │   └── SyncStatus.swift                 # Stati di sincronizzazione e diagnostica
│   ├── Services/
│   │   ├── WebSyncroServiceProtocol.swift   # Protocollo di rete per DI e mock
│   │   ├── WebSyncroService.swift           # Flusso di rete 2-fasi con User-Agent e cache policy
│   │   ├── SalesParser.swift                # Parser maturato.txt con regex & encoding fix
│   │   └── MockWebSyncroService.swift       # Dati mock e simulazione
│   ├── Storage/
│   │   └── AccountStore.swift               # Persistenza account utente
│   ├── ViewModels/
│   │   ├── DashboardViewModel.swift         # Logica vendite, calcolo totali, filtri e ricerca
│   │   ├── AccountManagerViewModel.swift    # Gestione CRUD account
│   │   └── SettingsViewModel.swift          # Diagnostica e impostazioni
│   ├── Views/
│   │   ├── Components/
│   │   │   ├── LiquidGlassCard.swift        # Card con .ultraThinMaterial e specular gradient
│   │   │   ├── LiquidGlassBackground.swift  # Sfondo fluido ambientale
│   │   │   ├── MetricStatCard.swift         # Badge totali e metriche
│   │   │   ├── SaleItemRowView.swift        # Singola riga articolo venduto
│   │   │   ├── SearchBarView.swift          # Ricerca Liquid Glass
│   │   │   ├── EmptyOrErrorView.swift       # Gestione stati vuoti/errore/caricamento
│   │   │   └── GlassButton.swift            # Pulsanti traslucidi
│   │   ├── Dashboard/
│   │   │   ├── DashboardView.swift          # Schermata principale con pull-to-refresh
│   │   │   ├── SummaryHeaderView.swift      # Header riassuntivo totale maturato e avvisi
│   │   │   └── SalesListView.swift          # Lista vendite raggruppata per mese/anno
│   │   ├── Accounts/
│   │   │   ├── AccountManagerView.swift     # Gestione account
│   │   │   ├── AddAccountSheet.swift        # Form aggiunta/modifica credenziali
│   │   │   └── AccountSwitcherMenu.swift    # Menu rapido cambio account
│   │   ├── Detail/
│   │   │   └── SaleItemDetailSheet.swift    # Scheda dettaglio con ShareLink e copia rapida
│   │   └── Settings/
│   │       └── SettingsView.swift           # Impostazioni, diagnostica e toggle demo
│   └── Utilities/
│       ├── CurrencyFormatter.swift          # Formattazione valuta it_IT (€)
│       ├── DateExtensions.swift             # Parsing e raggruppamenti date
│       ├── HapticFeedback.swift             # Feedback aptici nativi
│       └── View+AdaptiveModifiers.swift     # Modificatori adattivi SwiftUI
└── Tests/WebSyncroClientTests/
    ├── SalesParserTests.swift               # Test suite parser maturato.txt e encoding
    ├── WebSyncroServiceTests.swift          # Test scraping directory e ordine snapshot
    ├── AccountStoreTests.swift              # Test persistenza e switch account
    ├── DashboardViewModelTests.swift        # Test filtri, ricerca e ordinamento
    └── AccountManagerViewModelTests.swift   # Test validazione form e gestione account
```

---

## 🧪 Esecuzione dei Test Unitari

Per eseguire la suite di test completa tramite riga di comando:

```bash
cd WebSyncroClient
swift test
```

Tutti i test inclusi validano:
- Il parsing di file `maturato.txt` standard e malformati.
- Il corretto trattamento delle anomalie del simbolo Euro (`â¬`).
- L'estrazione e ordinamento decrescente degli snapshot `SM_YYYY-MM-DDTHH:MM:SS`.
- Il filtraggio in tempo reale per testo, ID e periodo temporale.
- Le operazioni CRUD di memorizzazione account multi-utente.

