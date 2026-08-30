import SwiftUI

#if canImport(UserNotifications)
import UserNotifications
#endif
#if canImport(UIKit)
import UIKit

public class AppDelegate: NSObject, UIApplicationDelegate {
    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        #if canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        center.delegate = NotificationManager.shared
        center.requestAuthorization(options: [.alert, .badge, .sound, .provisional]) { granted, _ in
            Task { @MainActor in
                NotificationManager.shared.permissionGranted = granted
            }
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
        #endif
        return true
    }
}
#endif

/// Entry point per l'applicazione iOS WebSyncro Mercatini
#if os(iOS)
@main
#endif
public struct WebSyncroApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    @StateObject private var appState = AppState.shared
    @StateObject private var notificationManager = NotificationManager.shared

    public init() {}

    public var body: some Scene {
        WindowGroup {
            MainTabView(accountStore: appState.accountStore)
                .environmentObject(appState)
                .environmentObject(notificationManager)
                .task {
                    _ = await notificationManager.requestPermission()
                }
        }
    }
}
