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
            .tint(appSettings.accentColor)
            .task { await auth.checkAuth() }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    PushNotificationManager.shared.requestPermission()
                }
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    interstitialAd.showIfReady()
                }
            }
        }
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
