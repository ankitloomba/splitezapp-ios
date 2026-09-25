import SwiftUI

@main
struct SplitEZApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var auth = AuthService.shared
    @StateObject private var appSettings = AppSettingsManager.shared
    @Environment(\.scenePhase) private var scenePhase
    private let interstitialAd = InterstitialAdManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isLoggedIn {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(auth)
            .environmentObject(appSettings)
            .preferredColorScheme(.light)
            .tint(appSettings.accentColor)
            .task { await auth.checkAuth() }
            .onAppear {
                // Force light mode at UIKit level so UIKit components (tab bar,
                // nav bar, system backgrounds) also stay light regardless of device setting.
                forceLight()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    PushNotificationManager.shared.requestPermission()
                }
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    interstitialAd.showIfReady()
                    forceLight()
                }
            }
        }
    }

    private func forceLight() {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { $0.overrideUserInterfaceStyle = .light }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = PushNotificationManager.shared
        InterstitialAdManager.shared.configure()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        PushNotificationManager.shared.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        PushNotificationManager.shared.didFailToRegisterForRemoteNotifications(error: error)
    }
}
