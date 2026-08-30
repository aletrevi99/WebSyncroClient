import SwiftUI

/// Schermata per visualizzare le comunicazioni e notizie pubblicate dal mercatino
public struct NewsListView: View {
    @ObservedObject var accountStore: AccountStore
    @State private var notifications: [ShopNotification] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedNotification: ShopNotification?

    private let service: WebSyncroServiceProtocol

    public init(
        accountStore: AccountStore? = nil,
        service: WebSyncroServiceProtocol = WebSyncroService.shared
    ) {
        self.accountStore = accountStore ?? AccountStore.shared
        self.service = service
    }

    private var activeShopId: String {
        accountStore.activeAccount?.shopId ?? "exnovomercatino"
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        if isLoading && notifications.isEmpty {
                            EmptyOrErrorView(type: .loading(message: "Caricamento notizie dal mercatino..."))
                                .padding(.top, 40)
                        } else if let error = errorMessage, notifications.isEmpty {
                            EmptyOrErrorView(
                                type: .error(
                                    message: error,
                                    onRetry: { Task { await loadNotifications() } }
                                )
                            )
                            .padding(.top, 40)
                        } else if notifications.isEmpty {
                            EmptyOrErrorView(
                                type: .empty(
                                    title: "Nessuna Notizia",
                                    message: "Il mercatino non ha pubblicato comunicazioni recenti."
                                )
                            )
                            .padding(.top, 40)
                        } else {
                            ForEach(notifications) { notif in
                                notificationCard(notif)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .refreshable {
                    await loadNotifications()
                }
            }
            .navigationTitle("Notizie")
            .adaptiveLargeTitle()
            .sheet(item: $selectedNotification) { notif in
                notificationDetailSheet(notif)
            }
            .task {
                await loadNotifications()
            }
            .onChange(of: accountStore.activeAccountId) { _, _ in
                Task {
                    await loadNotifications()
                }
            }
        }
    }

    @ViewBuilder
    private func notificationCard(_ notif: ShopNotification) -> some View {
        Button(action: {
            HapticFeedback.selection()
            selectedNotification = notif
        }) {
            LiquidGlassCard(cornerRadius: 22, padding: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        // Mittente
                        HStack(spacing: 6) {
                            Image(systemName: "megaphone.fill")
                                .font(.caption)
                                .foregroundColor(.accentColor)

                            Text(notif.sender)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.accentColor)
                        }

                        Spacer()

                        // Data
                        Text(notif.displayDate)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Titolo
                    Text(notif.title)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    // Anteprima messaggio
                    Text(notif.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    HStack {
                        Spacer()
                        Text("Leggi tutto →")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                    }
                    .padding(.top, 2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func notificationDetailSheet(_ notif: ShopNotification) -> some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        LiquidGlassCard(cornerRadius: 24, padding: 20) {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Label(notif.sender, systemImage: "megaphone.fill")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.accentColor)

                                    Spacer()

                                    Text(notif.displayDate)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Divider()

                                Text(notif.title)
                                    .font(.system(.title2, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)

                                Text(notif.message)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .lineSpacing(4)
                            }
                        }

                        Spacer()
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Comunicazione")
            .adaptiveInlineTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chiudi") {
                        selectedNotification = nil
                    }
                }
            }
        }
    }

    private func loadNotifications() async {
        isLoading = true
        errorMessage = nil
        do {
            self.notifications = try await service.fetchNotifications(shopId: activeShopId)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
