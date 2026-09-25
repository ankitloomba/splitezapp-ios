import SwiftUI
import LocalAuthentication
import CoreImage.CIFilterBuiltins

struct SettingsView: View {
    @EnvironmentObject var auth: AuthService
    @State private var isPlusUser = false
    @State private var showQR = false
    @State private var showPurchaseConfirm = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                SplitEZTheme.darkBg.frame(height: 280)
                Color(.systemBackground)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    settingsHeader

                    VStack(spacing: 0) {
                        sectionLabel("PREFERENCES")

                        settingsRow(label: "Notifications") {
                            NotificationSettingsView()
                        }
                        rowDivider
                        settingsRow(label: "Security") {
                            SecuritySettingsView()
                        }
                        rowDivider
                        settingsRow(label: "Appearance") {
                            AppearanceSettingsView()
                        }
                        rowDivider
                        settingsRowWithValue(label: "Currency & language", value: "\(auth.currentUser?.currency ?? "INR") · EN") {
                            CurrencyLanguageView()
                        }

                        sectionLabel("HELP & SUPPORT")

                        Button {
                            if let url = URL(string: "mailto:support@splitez.app") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .font(.system(size: 16))
                                    .foregroundColor(SplitEZTheme.textSecondary)
                                Text("Contact us")
                                    .font(.subheadline)
                                    .foregroundColor(SplitEZTheme.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(SplitEZTheme.textTertiary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                        rowDivider

                        Button {
                            // Replace with your real App Store ID
                            if let url = URL(string: "itms-apps://itunes.apple.com/app/id6745397980?action=write-review") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Text("Rate SplitEZ")
                                    .font(.subheadline)
                                    .foregroundColor(SplitEZTheme.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(SplitEZTheme.textTertiary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)

                        Button {
                            Task { await auth.logout() }
                        } label: {
                            Text("Log out")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(SplitEZTheme.negative)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(SplitEZTheme.negative, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                        VStack(spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(SplitEZTheme.primary)
                                Text("An ")
                                    .font(.caption)
                                    .foregroundColor(SplitEZTheme.textTertiary)
                                + Text("Adrevo")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(SplitEZTheme.primary)
                                + Text(" Product")
                                    .font(.caption)
                                    .foregroundColor(SplitEZTheme.textTertiary)
                            }
                            Text("© 2026 SplitEZ · 1.0.0")
                                .font(.caption2)
                                .foregroundColor(SplitEZTheme.textTertiary)
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 8)

                        Spacer().frame(height: 80)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    .offset(y: -16)
                }
            }
        }
        .navigationBarHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showQR) {
            UserQRSheet(isPresented: $showQR)
                .environmentObject(auth)
        }
        .alert("Go Ad Free", isPresented: $showPurchaseConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Subscribe ₹99/mo") {
                // In production: trigger StoreKit purchase here
                isPlusUser = true
            }
        } message: {
            Text("Remove all ads, get priority support and data exports for ₹99/month. Cancel any time.")
        }
    }

    // MARK: - Header

    private var settingsHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("Account")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Spacer()
                Color.clear.frame(width: 24)
            }

            if let user = auth.currentUser {
                HStack(spacing: 14) {
                    ZStack(alignment: .bottomLeading) {
                        Circle()
                            .stroke(
                                SplitEZTheme.primary.opacity(0.3),
                                style: StrokeStyle(lineWidth: 2, dash: [4, 3])
                            )
                            .frame(width: 68, height: 68)
                            .overlay(
                                Group {
                                    if let pic = user.profilePicture, let url = URL(string: pic) {
                                        AsyncImage(url: url) { image in
                                            image.resizable().scaledToFill()
                                        } placeholder: {
                                            Circle().fill(SplitEZTheme.primary)
                                                .overlay(Text(user.firstName.prefix(1).uppercased()).font(.title2.bold()).foregroundColor(.white))
                                        }
                                        .frame(width: 56, height: 56)
                                        .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(SplitEZTheme.primary)
                                            .frame(width: 56, height: 56)
                                            .overlay(
                                                Text(user.firstName.prefix(1).uppercased())
                                                    .font(.title2.bold())
                                                    .foregroundColor(.white)
                                            )
                                    }
                                }
                            )

                        Button { showQR = true } label: {
                            Image(systemName: "qrcode")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(5)
                                .background(
                                    Circle()
                                        .fill(SplitEZTheme.primary)
                                        .overlay(Circle().stroke(SplitEZTheme.darkBg, lineWidth: 2))
                                )
                        }
                        .offset(x: 2, y: 2)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.displayName)
                            .font(.title3.weight(.bold))
                            .foregroundColor(.white)
                        if let email = user.email {
                            Text(email)
                                .font(.caption)
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                    }

                    Spacer()

                    NavigationLink(destination: EditProfileView()) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }

            upgradeBanner
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(SplitEZTheme.darkBg)
    }

    // MARK: - Upgrade Banner

    private var upgradeBanner: some View {
        HStack {
            if isPlusUser {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("SplitEZ Ad Free")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                    Text("Renews on 15 Oct 2026")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.7))
                }
                Spacer()
                Button("Manage") {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(SplitEZTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(Color.white.opacity(0.3))
                )
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Get SplitEZ Ad Free")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                    Text("No ads · priority support · exports")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.7))
                }
                Spacer()
                Button("₹99/mo") { showPurchaseConfirm = true }
                    .font(.caption.weight(.bold))
                    .foregroundColor(SplitEZTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(Color.orange)
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [SplitEZTheme.primary.opacity(0.8), SplitEZTheme.primary.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundColor(SplitEZTheme.textTertiary)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 8)
    }

    private func settingsRow<D: View>(label: String, @ViewBuilder destination: () -> D) -> some View {
        NavigationLink(destination: destination()) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(SplitEZTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(SplitEZTheme.textTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private func settingsRowWithValue<D: View>(label: String, value: String, @ViewBuilder destination: () -> D) -> some View {
        NavigationLink(destination: destination()) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(SplitEZTheme.textPrimary)
                Spacer()
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(SplitEZTheme.textTertiary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(SplitEZTheme.textTertiary)
                    .padding(.leading, 2)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private var rowDivider: some View {
        Divider().padding(.leading, 20)
    }
}

// MARK: - Notification Settings (Screen 19)

struct NotificationSettingsView: View {
    @ObservedObject private var settings = AppSettingsManager.shared
    @State private var showSystemSettings = false

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                SplitEZTheme.darkBg.frame(height: 160)
                Color(.systemBackground)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 8)

                    VStack(spacing: 0) {
                        toggleRow(label: "Push notifications", subtitle: "Reminders, settlements & activity", isOn: $settings.pushEnabled) {
                            if settings.pushEnabled {
                                PushNotificationManager.shared.requestPermission()
                            }
                            syncPreferences()
                        }
                        rowDivider
                        toggleRow(label: "Email notifications", subtitle: "Weekly summary & receipts", isOn: $settings.emailEnabled) {
                            syncPreferences()
                        }

                        sectionLabel("NOTIFY ME ABOUT")

                        toggleRow(label: "New expenses added", isOn: $settings.newExpenses) { syncPreferences() }
                        rowDivider
                        toggleRow(label: "Payment received", isOn: $settings.paymentReceived) { syncPreferences() }
                        rowDivider
                        toggleRow(label: "Friend requests", isOn: $settings.friendRequests) { syncPreferences() }
                        rowDivider
                        toggleRow(label: "Reminders sent to you", isOn: $settings.reminders) { syncPreferences() }
                        rowDivider
                        toggleRow(label: "Group updates", isOn: $settings.groupUpdates) { syncPreferences() }
                        rowDivider
                        toggleRow(label: "Promotional offers", isOn: $settings.promotions) { syncPreferences() }

                        Spacer().frame(height: 40)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(SplitEZTheme.darkBg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func syncPreferences() {
        Task { await settings.syncNotificationPreferences() }
    }

    private func toggleRow(label: String, subtitle: String? = nil, isOn: Binding<Bool>, onChange: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(SplitEZTheme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(SplitEZTheme.textTertiary)
                }
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(SplitEZTheme.primary)
                .onChange(of: isOn.wrappedValue) { _, _ in
                    onChange()
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundColor(SplitEZTheme.textTertiary)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 8)
    }

    private var rowDivider: some View {
        Divider().padding(.leading, 20)
    }
}

// MARK: - Security Settings (Screen 20)

struct SecuritySettingsView: View {
    @ObservedObject private var settings = AppSettingsManager.shared
    @EnvironmentObject var auth: AuthService
    @State private var showChangePassword = false
    @State private var showDeleteConfirm = false
    @State private var showRevokeConfirm = false
    @State private var showLogoutAllConfirm = false
    @State private var biometricError: String?
    @State private var showBiometricAlert = false

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                SplitEZTheme.darkBg.frame(height: 160)
                Color(.systemBackground)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 8)

                    VStack(spacing: 0) {
                        // Change password
                        NavigationLink(destination: ChangePasswordView()) {
                            HStack(spacing: 12) {
                                Image(systemName: "lock")
                                    .font(.system(size: 16))
                                    .foregroundColor(SplitEZTheme.textSecondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Change password")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(SplitEZTheme.textPrimary)
                                    Text("Last changed 3 months ago")
                                        .font(.caption)
                                        .foregroundColor(SplitEZTheme.textTertiary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(SplitEZTheme.textTertiary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                        rowDivider

                        // Biometric login
                        HStack(spacing: 12) {
                            Image(systemName: "shield")
                                .font(.system(size: 16))
                                .foregroundColor(SplitEZTheme.textSecondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Biometric login")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(SplitEZTheme.textPrimary)
                                Text(settings.biometricType == .none ? "Not available on this device" : settings.biometricLabel)
                                    .font(.caption)
                                    .foregroundColor(SplitEZTheme.textTertiary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { settings.biometricEnabled },
                                set: { newValue in
                                    if newValue {
                                        Task {
                                            let success = await settings.authenticateBiometric()
                                            if success {
                                                settings.biometricEnabled = true
                                            } else {
                                                biometricError = "Authentication failed. Please try again."
                                                showBiometricAlert = true
                                            }
                                        }
                                    } else {
                                        settings.biometricEnabled = false
                                    }
                                }
                            ))
                            .labelsHidden()
                            .tint(SplitEZTheme.primary)
                            .disabled(settings.biometricType == .none)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        rowDivider

                        // App lock
                        HStack(spacing: 12) {
                            Image(systemName: "rectangle.on.rectangle")
                                .font(.system(size: 16))
                                .foregroundColor(SplitEZTheme.textSecondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("App lock")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(SplitEZTheme.textPrimary)
                                Text("Require PIN on every open")
                                    .font(.caption)
                                    .foregroundColor(SplitEZTheme.textTertiary)
                            }
                            Spacer()
                            Toggle("", isOn: $settings.appLockEnabled)
                                .labelsHidden()
                                .tint(SplitEZTheme.primary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)

                        // Sessions
                        sectionLabel("SESSIONS")

                        // Current device
                        HStack(spacing: 12) {
                            Image(systemName: "iphone")
                                .font(.system(size: 16))
                                .foregroundColor(SplitEZTheme.textSecondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(UIDevice.current.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(SplitEZTheme.textPrimary)
                                Text("Active now · this device")
                                    .font(.caption)
                                    .foregroundColor(SplitEZTheme.positive)
                            }
                            Spacer()
                            Circle()
                                .fill(SplitEZTheme.positive)
                                .frame(width: 8, height: 8)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        rowDivider

                        // Other session
                        HStack(spacing: 12) {
                            Image(systemName: "desktopcomputer")
                                .font(.system(size: 16))
                                .foregroundColor(SplitEZTheme.textSecondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Chrome · Windows")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(SplitEZTheme.textPrimary)
                                Text("Last active 2 days ago")
                                    .font(.caption)
                                    .foregroundColor(SplitEZTheme.textTertiary)
                            }
                            Spacer()
                            Button("Revoke") {
                                showRevokeConfirm = true
                            }
                            .font(.caption.weight(.medium))
                            .foregroundColor(SplitEZTheme.negative)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)

                        // Log out all
                        Button {
                            showLogoutAllConfirm = true
                        } label: {
                            Text("Log out all other devices")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(SplitEZTheme.negative)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(SplitEZTheme.negative, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        // Account section
                        sectionLabel("ACCOUNT")

                        Button {
                            showDeleteConfirm = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16))
                                    .foregroundColor(SplitEZTheme.negative)
                                Text("Delete account")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(SplitEZTheme.negative)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(SplitEZTheme.textTertiary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)

                        Spacer().frame(height: 40)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                }
            }
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(SplitEZTheme.darkBg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            settings.checkBiometricAvailability()
        }
        .alert("Biometric Authentication", isPresented: $showBiometricAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(biometricError ?? "Authentication failed.")
        }
        .alert("Delete Account", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    let api = APIClient.shared
                    let _: AnyCodable? = try? await api.post("/users/me/delete")
                    await auth.logout()
                }
            }
        } message: {
            Text("This will permanently delete your account and all data. This action cannot be undone.")
        }
        .alert("Revoke Session", isPresented: $showRevokeConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Revoke", role: .destructive) {
                Task {
                    let api = APIClient.shared
                    let _: AnyCodable? = try? await api.post("/auth/sessions/revoke-all")
                }
            }
        } message: {
            Text("This will end the selected session. The device will need to log in again.")
        }
        .alert("Log Out All Devices", isPresented: $showLogoutAllConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out All", role: .destructive) {
                Task {
                    let api = APIClient.shared
                    let _: AnyCodable? = try? await api.post("/auth/sessions/revoke-all")
                }
            }
        } message: {
            Text("All other devices will be logged out. You'll stay logged in on this device.")
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundColor(SplitEZTheme.textTertiary)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 8)
    }

    private var rowDivider: some View {
        Divider().padding(.leading, 56)
    }
}

// MARK: - Change Password

struct ChangePasswordView: View {
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @Environment(\.dismiss) var dismiss
    private let api = APIClient.shared

    private var isValid: Bool {
        !currentPassword.isEmpty && newPassword.count >= 8 && newPassword == confirmPassword
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                SplitEZTheme.darkBg.frame(height: 100)
                Color(.systemBackground)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 8)

                    VStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 16) {
                            passwordField("Current password", text: $currentPassword)
                            passwordField("New password", text: $newPassword)
                            passwordField("Confirm new password", text: $confirmPassword)

                            if newPassword.count > 0 && newPassword.count < 8 {
                                Text("Password must be at least 8 characters")
                                    .font(.caption)
                                    .foregroundColor(SplitEZTheme.negative)
                            }

                            if !confirmPassword.isEmpty && newPassword != confirmPassword {
                                Text("Passwords do not match")
                                    .font(.caption)
                                    .foregroundColor(SplitEZTheme.negative)
                            }

                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(SplitEZTheme.negative)
                            }

                            Button {
                                Task {
                                    isLoading = true
                                    errorMessage = nil
                                    do {
                                        let _: AnyCodable = try await api.put("/users/me/password", body: ChangePasswordRequest(
                                            currentPassword: currentPassword,
                                            newPassword: newPassword
                                        ))
                                        showSuccess = true
                                    } catch {
                                        errorMessage = "Failed to change password. Check your current password."
                                    }
                                    isLoading = false
                                }
                            } label: {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                } else {
                                    Text("Update Password")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(isValid ? SplitEZTheme.primary : SplitEZTheme.primary.opacity(0.4))
                            )
                            .disabled(!isValid || isLoading)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)

                        Spacer().frame(height: 40)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                }
            }
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(SplitEZTheme.darkBg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Password Changed", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your password has been updated successfully.")
        }
    }

    private func passwordField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .textContentType(.password)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemGray6))
            )
    }
}

private struct ChangePasswordRequest: Codable {
    let currentPassword: String
    let newPassword: String
}

// MARK: - Appearance Settings

struct AppearanceSettingsView: View {
    @ObservedObject private var settings = AppSettingsManager.shared

    private let themes: [(icon: String, label: String, iconColor: Color, bgColor: Color)] = [
        ("moon.fill", "Dark", .white, Color(hex: "10142A")),
        ("sun.min", "Light", .orange, Color(.systemGray6)),
        ("circle.righthalf.filled", "System", Color(hex: "10142A"), Color(.systemGray6)),
    ]

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                SplitEZTheme.darkBg.frame(height: 100)
                Color(.systemBackground)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 8)

                    VStack(spacing: 0) {
                        sectionLabel("THEME")

                        HStack(spacing: 12) {
                            ForEach(Array(themes.enumerated()), id: \.offset) { index, theme in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        settings.themeMode = index
                                    }
                                } label: {
                                    VStack(spacing: 10) {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(theme.bgColor)
                                            .frame(width: 52, height: 52)
                                            .overlay(
                                                Image(systemName: theme.icon)
                                                    .font(.system(size: 20, weight: .medium))
                                                    .foregroundColor(theme.iconColor)
                                            )
                                        Text(theme.label)
                                            .font(.caption.weight(.medium))
                                            .foregroundColor(settings.themeMode == index ? SplitEZTheme.primary : SplitEZTheme.textSecondary)
                                        Circle()
                                            .fill(settings.themeMode == index ? SplitEZTheme.primary : Color.clear)
                                            .frame(width: 6, height: 6)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(
                                                settings.themeMode == index ? SplitEZTheme.primary : Color(.systemGray4),
                                                lineWidth: settings.themeMode == index ? 2 : 1
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)

                        sectionLabel("ACCENT COLOUR")

                        HStack(spacing: 16) {
                            ForEach(Array(AppSettingsManager.accentOptions.enumerated()), id: \.offset) { index, accent in
                                Button {
                                    settings.accentIndex = index
                                } label: {
                                    Circle()
                                        .fill(accent.color)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                                .opacity(settings.accentIndex == index ? 1 : 0)
                                        )
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)

                        sectionLabel("DISPLAY")

                        toggleRow(label: "Compact list view", isOn: $settings.compactList)
                        Divider().padding(.leading, 20)
                        toggleRow(label: "Show avatars in lists", isOn: $settings.showAvatars)
                        Divider().padding(.leading, 20)
                        toggleRow(label: "Animations", isOn: $settings.animationsEnabled)

                        Spacer().frame(height: 40)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                }
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(SplitEZTheme.darkBg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundColor(SplitEZTheme.textTertiary)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 12)
    }

    private func toggleRow(label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundColor(SplitEZTheme.textPrimary)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(SplitEZTheme.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Currency & Language

struct CurrencyLanguageView: View {
    @State private var selectedCurrency = 0
    @State private var selectedLanguage = 0

    private let currencies: [(flag: String, name: String, symbol: String, code: String)] = [
        ("\u{1F1EE}\u{1F1F3}", "Indian Rupee", "₹", "INR"),
        ("\u{1F1FA}\u{1F1F8}", "US Dollar", "$", "USD"),
        ("\u{1F1EA}\u{1F1FA}", "Euro", "€", "EUR"),
        ("\u{1F1EC}\u{1F1E7}", "British Pound", "£", "GBP"),
    ]

    private let languages: [(name: String, native: String, code: String)] = [
        ("English", "English", "EN"),
        ("Hindi", "हिन्दी", "HI"),
        ("Spanish", "Español", "ES"),
    ]

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                SplitEZTheme.darkBg.frame(height: 100)
                Color(.systemBackground)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 8)

                    VStack(spacing: 0) {
                        sectionLabel("DEFAULT CURRENCY")

                        ForEach(Array(currencies.enumerated()), id: \.offset) { index, currency in
                            if index > 0 {
                                Divider().padding(.leading, 20)
                            }
                            Button {
                                selectedCurrency = index
                            } label: {
                                HStack(spacing: 12) {
                                    Text(currency.flag)
                                        .font(.title2)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(currency.name)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(SplitEZTheme.textPrimary)
                                        Text("\(currency.symbol) · \(currency.code)")
                                            .font(.caption)
                                            .foregroundColor(SplitEZTheme.textTertiary)
                                    }
                                    Spacer()
                                    Circle()
                                        .fill(selectedCurrency == index ? SplitEZTheme.primary : Color.clear)
                                        .frame(width: 12, height: 12)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedCurrency == index ? SplitEZTheme.primary : Color(.systemGray3), lineWidth: 1.5)
                                                .frame(width: 18, height: 18)
                                        )
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)
                        }

                        Divider().padding(.leading, 20)

                        Button(action: {}) {
                            Text("+ Add more currencies")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(SplitEZTheme.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }

                        sectionLabel("LANGUAGE")

                        ForEach(Array(languages.enumerated()), id: \.offset) { index, lang in
                            if index > 0 {
                                Divider().padding(.leading, 20)
                            }
                            Button {
                                selectedLanguage = index
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(index == 0 ? lang.name : lang.native)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(SplitEZTheme.textPrimary)
                                        Text(index == 0 ? "\(lang.code) · default" : lang.name)
                                            .font(.caption)
                                            .foregroundColor(SplitEZTheme.textTertiary)
                                    }
                                    Spacer()
                                    Circle()
                                        .fill(selectedLanguage == index ? SplitEZTheme.primary : Color.clear)
                                        .frame(width: 12, height: 12)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedLanguage == index ? SplitEZTheme.primary : Color(.systemGray3), lineWidth: 1.5)
                                                .frame(width: 18, height: 18)
                                        )
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer().frame(height: 40)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                }
            }
        }
        .navigationTitle("Currency & language")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(SplitEZTheme.darkBg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundColor(SplitEZTheme.textTertiary)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 12)
    }
}

// MARK: - Edit Profile

struct EditProfileView: View {
    @EnvironmentObject var auth: AuthService
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var isSaving = false
    @State private var showDeleteConfirm = false
    @Environment(\.dismiss) var dismiss
    private let api = APIClient.shared

    private var isEmailVerified: Bool {
        email == auth.currentUser?.email && auth.currentUser?.email != nil
    }

    private var isPhoneVerified: Bool {
        phone == auth.currentUser?.phone && auth.currentUser?.phone != nil
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                SplitEZTheme.darkBg.frame(height: 300)
                Color(.systemBackground)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 0) {
                        HStack {
                            Button { dismiss() } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Text("Edit profile")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Color.clear.frame(width: 20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 60)

                        // Avatar with camera
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(SplitEZTheme.primary)
                                .frame(width: 88, height: 88)
                                .overlay(
                                    Text(auth.currentUser?.firstName.prefix(1).uppercased() ?? "A")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.white)
                                )

                            ZStack {
                                Circle()
                                    .fill(SplitEZTheme.darkBg)
                                    .frame(width: 30, height: 30)
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                            .offset(x: 2, y: 2)
                        }
                        .padding(.top, 20)

                        Text("Change photo")
                            .font(.caption)
                            .foregroundColor(SplitEZTheme.textSecondary)
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                    }

                    // White content card
                    VStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 20) {
                            // Full Name
                            VStack(alignment: .leading, spacing: 6) {
                                Text("FULL NAME")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(SplitEZTheme.primary)
                                    .tracking(0.5)
                                TextField("Full name", text: $fullName)
                                    .font(.system(size: 16))
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(SplitEZTheme.primary.opacity(0.3), lineWidth: 1)
                                    )
                            }

                            // Email
                            VStack(alignment: .leading, spacing: 6) {
                                Text("EMAIL")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(SplitEZTheme.primary)
                                    .tracking(0.5)
                                HStack {
                                    TextField("Email address", text: $email)
                                        .font(.system(size: 16))
                                        .keyboardType(.emailAddress)
                                        .textContentType(.emailAddress)
                                        .autocapitalization(.none)
                                    if !isEmailVerified {
                                        Button("Verify") {}
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(SplitEZTheme.primary)
                                    }
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(isEmailVerified ? Color(.systemGray4) : Color.orange.opacity(0.5), lineWidth: 1)
                                )
                                if !isEmailVerified {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.circle")
                                            .font(.system(size: 12))
                                        Text("Not verified · we'll send a link to this email")
                                            .font(.system(size: 12))
                                    }
                                    .foregroundColor(.orange)
                                }
                            }

                            // Phone
                            VStack(alignment: .leading, spacing: 6) {
                                Text("PHONE")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(SplitEZTheme.primary)
                                    .tracking(0.5)
                                HStack(spacing: 0) {
                                    Text("+91")
                                        .font(.system(size: 16))
                                        .foregroundColor(SplitEZTheme.textSecondary)
                                        .padding(.leading, 14)
                                    Divider()
                                        .frame(height: 20)
                                        .padding(.horizontal, 10)
                                    TextField("Phone number", text: $phone)
                                        .font(.system(size: 16))
                                        .keyboardType(.phonePad)
                                    if isPhoneVerified {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .semibold))
                                            Text("Verified")
                                                .font(.system(size: 13, weight: .semibold))
                                        }
                                        .foregroundColor(SplitEZTheme.positive)
                                        .padding(.trailing, 14)
                                    }
                                }
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                Text("Changing your number needs an OTP")
                                    .font(.system(size: 12))
                                    .foregroundColor(SplitEZTheme.textTertiary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                        Spacer().frame(height: 40)

                        // Save button
                        Button {
                            Task {
                                isSaving = true
                                let parts = fullName.split(separator: " ", maxSplits: 1)
                                let first = String(parts.first ?? "")
                                let last = parts.count > 1 ? String(parts[1]) : nil
                                let _: UserProfile? = try? await api.put("/users/me", body: UpdateUserRequest(
                                    firstName: first, lastName: last))
                                await auth.checkAuth()
                                isSaving = false
                                dismiss()
                            }
                        } label: {
                            Text(isSaving ? "Saving..." : "Save changes")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                                        .fill(fullName.isEmpty ? SplitEZTheme.primary.opacity(0.4) : SplitEZTheme.primary)
                                )
                        }
                        .disabled(fullName.isEmpty || isSaving)
                        .padding(.horizontal, 20)

                        // Delete account
                        Button { showDeleteConfirm = true } label: {
                            Text("Delete account")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(SplitEZTheme.negative)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Delete Account", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {}
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
        .onAppear {
            let user = auth.currentUser
            fullName = user?.displayName ?? ""
            email = user?.email ?? ""
            phone = user?.phone ?? ""
        }
    }
}

// MARK: - User QR Sheet

struct UserQRSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var auth: AuthService

    private var qrContent: String {
        let id = auth.currentUser?.id ?? "unknown"
        return "splitez://add-friend?id=\(id)"
    }

    private var qrImage: UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(qrContent.utf8)
        filter.correctionLevel = "M"
        guard let ciImage = filter.outputImage else { return nil }
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            Text("My QR Code")
                .font(.title3.weight(.bold))
                .foregroundColor(SplitEZTheme.textPrimary)

            if let user = auth.currentUser {
                VStack(spacing: 8) {
                    if let pic = user.profilePicture, let url = URL(string: pic) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Circle().fill(SplitEZTheme.primary)
                                .overlay(Text(user.firstName.prefix(1).uppercased()).font(.title.bold()).foregroundColor(.white))
                        }
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(SplitEZTheme.primary)
                            .frame(width: 64, height: 64)
                            .overlay(Text(user.firstName.prefix(1).uppercased()).font(.title.bold()).foregroundColor(.white))
                    }
                    Text(user.displayName)
                        .font(.headline)
                        .foregroundColor(SplitEZTheme.textPrimary)
                    Text(user.email ?? "")
                        .font(.caption)
                        .foregroundColor(SplitEZTheme.textSecondary)
                }
            }

            if let img = qrImage {
                Image(uiImage: img)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white)
                    )
            }

            Text("Ask a friend to scan this to add you on SplitEZ")
                .font(.caption)
                .foregroundColor(SplitEZTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button("Done") { isPresented = false }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(SplitEZTheme.primary))
                .padding(.horizontal, 32)

            Spacer()
        }
        .padding(.horizontal, 24)
        .presentationDetents([.medium, .large])
    }
}

struct PeopleListView: View {
    @State private var people: [UserSummary] = []
    private let api = APIClient.shared

    var body: some View {
        List {
            ForEach(people) { person in
                HStack {
                    AvatarView(user: person, size: 36)
                    Text(person.displayName)
                }
            }
        }
        .overlay {
            if people.isEmpty {
                ContentUnavailableView("No Contacts", systemImage: "person.crop.circle.badge.plus")
            }
        }
        .navigationTitle("People")
        .task { people = (try? await api.get("/people")) ?? [] }
    }
}
