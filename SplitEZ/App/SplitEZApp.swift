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

// MARK: - AppDelegate for push notification callbacks

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
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        // Force light mode at the UIKit level — SwiftUI's preferredColorScheme alone
        // doesn't override UIKit components (tab bar, nav bar, system backgrounds).
        for window in windowScene.windows {
            window.overrideUserInterfaceStyle = .light
        }
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
