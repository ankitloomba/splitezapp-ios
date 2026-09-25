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
            .preferredColorScheme(appSettings.preferredColorScheme)
            .tint(appSettings.accentColor)
            .task { await auth.checkAuth() }
            .onAppear {
                applyUIKitColorScheme()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    PushNotificationManager.shared.requestPermission()
                }
            }
            .onChange(of: appSettings.themeMode) {
                applyUIKitColorScheme()
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    interstitialAd.showIfReady()
                    applyUIKitColorScheme()
                }
            }
        }
    }

    /// Mirrors themeMode to UIKit so native components (tab bar, status bar)
    /// also respect the user's choice. 0=dark, 1=light, 2=system.
    private func applyUIKitColorScheme() {
        let style: UIUserInterfaceStyle
        switch appSettings.themeMode {
        case 0: style = .dark
        case 1: style = .light
        default: style = .unspecified
        }
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { $0.overrideUserInterfaceStyle = style }
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
        // Apply stored theme before any window is rendered so UIScreen.main.traitCollection
        // is already correct on first SwiftUI layout pass.
        let themeMode = UserDefaults.standard.integer(forKey: "appearance_theme")
        // Key hasn't been written yet (new install) → default to system (unspecified)
        let style: UIUserInterfaceStyle
        switch themeMode {
        case 0: style = .dark
        case 1: style = .light
        default: style = .unspecified
        }
        UIApplication.shared.windows.forEach { $0.overrideUserInterfaceStyle = style }
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
