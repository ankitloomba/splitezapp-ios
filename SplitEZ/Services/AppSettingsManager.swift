import SwiftUI
import LocalAuthentication

@MainActor
class AppSettingsManager: ObservableObject {
    static let shared = AppSettingsManager()

    // MARK: - Appearance

    @AppStorage("appearance_theme") var themeMode: Int = 2 // 0=dark, 1=light, 2=system
    @AppStorage("appearance_accent") var accentIndex: Int = 0
    @AppStorage("appearance_compact") var compactList: Bool = false
    @AppStorage("appearance_avatars") var showAvatars: Bool = true
    @AppStorage("appearance_animations") var animationsEnabled: Bool = true

    var preferredColorScheme: ColorScheme? {
        switch themeMode {
        case 0: return .dark
        case 1: return .light
        default: return nil
        }
    }

    static let accentOptions: [(color: Color, hex: String, name: String)] = [
        (Color(hex: "6366F1"), "6366F1", "Indigo"),
        (Color(hex: "0D9488"), "0D9488", "Teal"),
        (Color(hex: "DC2626"), "DC2626", "Red"),
        (Color(hex: "F59E0B"), "F59E0B", "Amber"),
        (Color(hex: "16A34A"), "16A34A", "Green"),
    ]

    var accentColor: Color {
        let idx = min(accentIndex, Self.accentOptions.count - 1)
        return Self.accentOptions[max(0, idx)].color
    }

    // MARK: - Notifications

    @AppStorage("notif_push") var pushEnabled: Bool = true
    @AppStorage("notif_email") var emailEnabled: Bool = true
    @AppStorage("notif_new_expenses") var newExpenses: Bool = true
    @AppStorage("notif_payment_received") var paymentReceived: Bool = true
    @AppStorage("notif_friend_requests") var friendRequests: Bool = true
    @AppStorage("notif_reminders") var reminders: Bool = true
    @AppStorage("notif_group_updates") var groupUpdates: Bool = false
    @AppStorage("notif_promotions") var promotions: Bool = false

    // MARK: - Security

    @AppStorage("security_biometric") var biometricEnabled: Bool = false
    @AppStorage("security_app_lock") var appLockEnabled: Bool = false

    @Published var biometricType: LABiometryType = .none

    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        } else {
            biometricType = .none
        }
    }

    var biometricLabel: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        @unknown default: return "Biometric"
        }
    }

    func authenticateBiometric() async -> Bool {
        let context = LAContext()
        context.localizedReason = "Authenticate to enable biometric login"
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Verify your identity to enable \(biometricLabel)"
            )
        } catch {
            return false
        }
    }

    // MARK: - Notification preference sync

    private let api = APIClient.shared

    func syncNotificationPreferences() async {
        let prefs = NotificationPreferencesRequest(
            pushEnabled: pushEnabled,
            emailEnabled: emailEnabled,
            newExpenses: newExpenses,
            paymentReceived: paymentReceived,
            friendRequests: friendRequests,
            reminders: reminders,
            groupUpdates: groupUpdates,
            promotions: promotions
        )
        let _: AnyCodable? = try? await api.put("/users/me/notifications", body: prefs)
    }
}

struct NotificationPreferencesRequest: Codable {
    let pushEnabled: Bool
    let emailEnabled: Bool
    let newExpenses: Bool
    let paymentReceived: Bool
    let friendRequests: Bool
    let reminders: Bool
    let groupUpdates: Bool
    let promotions: Bool
}
