import Foundation

public final class WebSyncroService: WebSyncroServiceProtocol, @unchecked Sendable {
    public static let shared = WebSyncroService()

    public static let defaultUserAgent = "ExnovoMercatino/1.2 CFNetwork/3896.100.1.2.1 Darwin/27.0.0"
    public static let baseHost = "https://www.appwebsyncro.it/WebSyncro/ClientiWebSyncro"

    private let session: URLSession
    private let userAgent: String

    private static let snapshotRegex = try! NSRegularExpression(
        pattern: #"SM_\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}"#
    )

    public init(
        session: URLSession = .shared,
        userAgent: String = WebSyncroService.defaultUserAgent
    ) {
        self.session = session
        self.userAgent = userAgent
    }

    /// Esegue il recupero del report maturato o non maturato
    public func fetchSalesReport(
        shopId: String,
        userId: String,
        isNonMatured: Bool = false,
        onProgress: (@Sendable (SyncStatus) -> Void)? = nil
    ) async throws -> SalesReport {
        let cleanShopId = shopId.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanShopId.isEmpty else {
            throw WebSyncroError.shopNotFound(shopId: shopId)
        }
        guard !cleanUserId.isEmpty else {
            throw WebSyncroError.invalidURL("ID Utente / Tessera non valido")
        }

        // FASE 1: Directory Listing Scrape
        onProgress?(.scrapingDirectory(shopId: cleanShopId))
        let snapshots = try await fetchAvailableSnapshots(shopId: cleanShopId)

        guard let latestSnapshot = snapshots.first else {
            throw WebSyncroError.noSnapshotsFound(shopId: cleanShopId)
        }

        // FASE 2: Download file
        let fileName = isNonMatured ? "nonmaturato.txt" : "maturato.txt"
        onProgress?(.downloadingReport(shopId: cleanShopId, snapshot: latestSnapshot, userId: cleanUserId))
        
        let reportURLString = "\(Self.baseHost)/Negozi/\(cleanShopId)/\(latestSnapshot)/\(cleanUserId)/\(fileName)"
        guard let reportURL = URL(string: reportURLString) else {
            throw WebSyncroError.invalidURL(reportURLString)
        }

        var request = URLRequest(
            url: reportURL,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 25.0
        )
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("text/plain, text/html, */*", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WebSyncroError.networkError("Risposta non HTTP")
        }

        if httpResponse.statusCode == 404 {
            throw WebSyncroError.userReportNotFound(shopId: cleanShopId, userId: cleanUserId, snapshot: latestSnapshot)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw WebSyncroError.httpError(
                statusCode: httpResponse.statusCode,
                message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            )
        }

        let textContent = decodeDataToString(data)

        let report = SalesParser.parse(
            content: textContent,
            shopId: cleanShopId,
            userId: cleanUserId,
            syncTimestamp: latestSnapshot,
            isNonMatured: isNonMatured
        )

        return report
    }

    /// Scarica contemporaneamente sia il report maturato che non maturato (in recesso)
    public func fetchBothReports(
        shopId: String,
        userId: String,
        onProgress: (@Sendable (SyncStatus) -> Void)? = nil
    ) async throws -> (matured: SalesReport, nonMatured: SalesReport) {
        let cleanShopId = shopId.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanShopId.isEmpty else {
            throw WebSyncroError.shopNotFound(shopId: shopId)
        }
        guard !cleanUserId.isEmpty else {
            throw WebSyncroError.invalidURL("ID Utente / Tessera non valido")
        }

        // FASE 1: Directory Listing Scrape
        onProgress?(.scrapingDirectory(shopId: cleanShopId))
        let snapshots = try await fetchAvailableSnapshots(shopId: cleanShopId)

        guard let latestSnapshot = snapshots.first else {
            throw WebSyncroError.noSnapshotsFound(shopId: cleanShopId)
        }

        onProgress?(.downloadingReport(shopId: cleanShopId, snapshot: latestSnapshot, userId: cleanUserId))

        // FASE 2: Download parallelo
        async let maturedData = fetchReportFile(shopId: cleanShopId, snapshot: latestSnapshot, userId: cleanUserId, fileName: "maturato.txt")
        async let nonMaturedData = fetchReportFile(shopId: cleanShopId, snapshot: latestSnapshot, userId: cleanUserId, fileName: "nonmaturato.txt")

        let (matData, nonMatData) = try await (maturedData, nonMaturedData)

        let maturedReport = SalesParser.parse(
            content: matData,
            shopId: cleanShopId,
            userId: cleanUserId,
            syncTimestamp: latestSnapshot,
            isNonMatured: false
        )

        let nonMaturedReport = SalesParser.parse(
            content: nonMatData,
            shopId: cleanShopId,
            userId: cleanUserId,
            syncTimestamp: latestSnapshot,
            isNonMatured: true
        )

        return (maturedReport, nonMaturedReport)
    }

    /// Recupera l'elenco di tutti i negozi WebSyncro da ElencoNegozi.txt
    public func fetchShopDirectory() async throws -> [ShopDetails] {
        let urlString = "\(Self.baseHost)/ElencoNegozi.txt"
        guard let url = URL(string: urlString) else {
            throw WebSyncroError.invalidURL(urlString)
        }

        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 20.0
        )
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            return []
        }

        let raw = decodeDataToString(data)
        return SalesParser.parseShopDirectory(content: raw)
    }

    /// Recupera i dettagli completi e gli orari del negozio
    public func fetchShopDetails(shopId: String) async throws -> ShopDetails {
        let cleanShopId = shopId.trimmingCharacters(in: .whitespacesAndNewlines)

        async let directoryTask = fetchShopDirectory()
        async let scheduleTask = fetchSchedule(shopId: cleanShopId)

        let (directory, schedule) = await (try? directoryTask, try? scheduleTask)

        let foundShop = directory?.first(where: { $0.slug.caseInsensitiveCompare(cleanShopId) == .orderedSame })

        var details = foundShop ?? ShopDetails(
            name: cleanShopId.capitalized,
            slug: cleanShopId,
            address: "",
            cityZip: "",
            phone: "",
            email: ""
        )

        if let sched = schedule {
            details.schedule = sched
        }

        return details
    }

    /// Recupera l'elenco delle notizie dal mercatino
    public func fetchNotifications(shopId: String) async throws -> [ShopNotification] {
        let cleanShopId = shopId.trimmingCharacters(in: .whitespacesAndNewlines)
        let dirURLString = "\(Self.baseHost)/Negozi/\(cleanShopId)/Notifiche/"

        guard let dirURL = URL(string: dirURLString) else {
            return []
        }

        var request = URLRequest(
            url: dirURL,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 20.0
        )
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("text/html, */*", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            return []
        }

        let html = decodeDataToString(data)
        let filenames = SalesParser.extractNotificationFilenames(from: html)

        if filenames.isEmpty {
            return []
        }

        // Scarica le singole notifiche in parallelo
        return await withTaskGroup(of: ShopNotification?.self, returning: [ShopNotification].self) { group in
            for filename in filenames {
                group.addTask {
                    let fileURLString = "\(Self.baseHost)/Negozi/\(cleanShopId)/Notifiche/\(filename)"
                    guard let fileURL = URL(string: fileURLString) else { return nil }

                    var req = URLRequest(url: fileURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 15.0)
                    req.httpMethod = "GET"
                    req.setValue(self.userAgent, forHTTPHeaderField: "User-Agent")

                    guard let (fileData, fileResp) = try? await self.session.data(for: req),
                          let http = fileResp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                        return nil
                    }

                    let content = self.decodeDataToString(fileData)
                    return SalesParser.parseNotification(content: content, filename: filename)
                }
            }

            var notifications: [ShopNotification] = []
            for await notif in group {
                if let n = notif {
                    notifications.append(n)
                }
            }

            return notifications.sorted(by: { $0.rawFilename > $1.rawFilename })
        }
    }

    private func fetchSchedule(shopId: String) async throws -> [DaySchedule] {
        let urlString = "\(Self.baseHost)/Negozi/\(shopId)/Orario.txt"
        guard let url = URL(string: urlString) else {
            throw WebSyncroError.invalidURL(urlString)
        }

        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 20.0
        )
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            return []
        }

        let raw = decodeDataToString(data)
        return SalesParser.parseSchedule(content: raw)
    }

    private func fetchReportFile(shopId: String, snapshot: String, userId: String, fileName: String) async throws -> String {
        let reportURLString = "\(Self.baseHost)/Negozi/\(shopId)/\(snapshot)/\(userId)/\(fileName)"
        guard let reportURL = URL(string: reportURLString) else {
            throw WebSyncroError.invalidURL(reportURLString)
        }

        var request = URLRequest(
            url: reportURL,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 25.0
        )
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("text/plain, text/html, */*", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WebSyncroError.networkError("Risposta non HTTP")
        }

        if httpResponse.statusCode == 404 {
            return ""
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw WebSyncroError.httpError(
                statusCode: httpResponse.statusCode,
                message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            )
        }

        return decodeDataToString(data)
    }

    public func fetchAvailableSnapshots(shopId: String) async throws -> [String] {
        let cleanShopId = shopId.trimmingCharacters(in: .whitespacesAndNewlines)
        let dirURLString = "\(Self.baseHost)/Negozi/\(cleanShopId)/"

        guard let dirURL = URL(string: dirURLString) else {
            throw WebSyncroError.invalidURL(dirURLString)
        }

        var request = URLRequest(
            url: dirURL,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 20.0
        )
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WebSyncroError.networkError("Risposta non HTTP")
        }

        if httpResponse.statusCode == 404 {
            throw WebSyncroError.shopNotFound(shopId: cleanShopId)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw WebSyncroError.httpError(
                statusCode: httpResponse.statusCode,
                message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            )
        }

        let htmlString = decodeDataToString(data)
        return Self.extractSnapshots(from: htmlString)
    }

    public static func extractSnapshots(from html: String) -> [String] {
        let range = NSRange(location: 0, length: (html as NSString).length)
        let matches = snapshotRegex.matches(in: html, options: [], range: range)

        var uniqueSnapshots = Set<String>()
        let nsString = html as NSString

        for match in matches {
            let matchedText = nsString.substring(with: match.range)
            uniqueSnapshots.insert(matchedText)
        }

        return uniqueSnapshots.sorted(by: >)
    }

    private func decodeDataToString(_ data: Data) -> String {
        if let utf8 = String(data: data, encoding: .utf8) {
            return utf8
        }
        if let win1252 = String(data: data, encoding: .windowsCP1252) {
            return win1252
        }
        if let latin1 = String(data: data, encoding: .isoLatin1) {
            return latin1
        }
        return String(decoding: data, as: UTF8.self)
    }
}
