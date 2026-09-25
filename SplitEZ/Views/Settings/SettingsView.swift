import SwiftUI
import LocalAuthentication
import CoreImage.CIFilterBuiltins

struct SettingsView: View {
    @EnvironmentObject var auth: AuthService
    @State private var isPlusUser = false
    @State private var showQR = false
    @State private var showPurchaseConfirm = false
    @State private var showManageSubscription = false
    @State private var showContactForm = false
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
                        settingsRowWithValue(label: "Currency", value: auth.currentUser?.currency ?? "INR") {
                            CurrencyPickerView()
                        }

                        sectionLabel("HELP & SUPPORT")

                        Button {
                            showContactForm = true
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
        .sheet(isPresented: $showManageSubscription) {
            ManageSubscriptionSheet(isPlusUser: $isPlusUser)
        }
        .sheet(isPresented: $showContactForm) {
            ContactFormSheet()
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
                    showManageSubscription = true
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

struct CurrencyItem: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String
    let code: String
}

struct CurrencyPickerView: View {
    @EnvironmentObject var auth: AuthService
    @State private var selectedCode: String = "INR"
    @State private var search = ""
    private let api = APIClient.shared

    private static let allCurrencies: [CurrencyItem] = {
        let rest: [CurrencyItem] = [
            CurrencyItem(name: "Afghan Afghani", symbol: "؋", code: "AFN"),
            CurrencyItem(name: "Albanian Lek", symbol: "L", code: "ALL"),
            CurrencyItem(name: "Algerian Dinar", symbol: "د.ج", code: "DZD"),
            CurrencyItem(name: "Angolan Kwanza", symbol: "Kz", code: "AOA"),
            CurrencyItem(name: "Argentine Peso", symbol: "$", code: "ARS"),
            CurrencyItem(name: "Armenian Dram", symbol: "֏", code: "AMD"),
            CurrencyItem(name: "Australian Dollar", symbol: "A$", code: "AUD"),
            CurrencyItem(name: "Azerbaijani Manat", symbol: "₼", code: "AZN"),
            CurrencyItem(name: "Bahamian Dollar", symbol: "B$", code: "BSD"),
            CurrencyItem(name: "Bahraini Dinar", symbol: ".د.ب", code: "BHD"),
            CurrencyItem(name: "Bangladeshi Taka", symbol: "৳", code: "BDT"),
            CurrencyItem(name: "Barbadian Dollar", symbol: "Bds$", code: "BBD"),
            CurrencyItem(name: "Belarusian Ruble", symbol: "Br", code: "BYN"),
            CurrencyItem(name: "Belize Dollar", symbol: "BZ$", code: "BZD"),
            CurrencyItem(name: "Bhutanese Ngultrum", symbol: "Nu", code: "BTN"),
            CurrencyItem(name: "Bolivian Boliviano", symbol: "Bs.", code: "BOB"),
            CurrencyItem(name: "Bosnia-Herzegovina Mark", symbol: "KM", code: "BAM"),
            CurrencyItem(name: "Botswanan Pula", symbol: "P", code: "BWP"),
            CurrencyItem(name: "Brazilian Real", symbol: "R$", code: "BRL"),
            CurrencyItem(name: "British Pound", symbol: "£", code: "GBP"),
            CurrencyItem(name: "Brunei Dollar", symbol: "B$", code: "BND"),
            CurrencyItem(name: "Bulgarian Lev", symbol: "лв", code: "BGN"),
            CurrencyItem(name: "Burundian Franc", symbol: "Fr", code: "BIF"),
            CurrencyItem(name: "Cambodian Riel", symbol: "៛", code: "KHR"),
            CurrencyItem(name: "Canadian Dollar", symbol: "CA$", code: "CAD"),
            CurrencyItem(name: "Cape Verdean Escudo", symbol: "Esc", code: "CVE"),
            CurrencyItem(name: "CFA Franc BCEAO", symbol: "Fr", code: "XOF"),
            CurrencyItem(name: "CFA Franc BEAC", symbol: "Fr", code: "XAF"),
            CurrencyItem(name: "Chilean Peso", symbol: "$", code: "CLP"),
            CurrencyItem(name: "Chinese Yuan", symbol: "¥", code: "CNY"),
            CurrencyItem(name: "Colombian Peso", symbol: "$", code: "COP"),
            CurrencyItem(name: "Comorian Franc", symbol: "Fr", code: "KMF"),
            CurrencyItem(name: "Congolese Franc", symbol: "Fr", code: "CDF"),
            CurrencyItem(name: "Costa Rican Colón", symbol: "₡", code: "CRC"),
            CurrencyItem(name: "Croatian Kuna", symbol: "kn", code: "HRK"),
            CurrencyItem(name: "Cuban Peso", symbol: "$", code: "CUP"),
            CurrencyItem(name: "Czech Koruna", symbol: "Kč", code: "CZK"),
            CurrencyItem(name: "Danish Krone", symbol: "kr", code: "DKK"),
            CurrencyItem(name: "Djiboutian Franc", symbol: "Fr", code: "DJF"),
            CurrencyItem(name: "Dominican Peso", symbol: "RD$", code: "DOP"),
            CurrencyItem(name: "Egyptian Pound", symbol: "£", code: "EGP"),
            CurrencyItem(name: "Eritrean Nakfa", symbol: "Nfk", code: "ERN"),
            CurrencyItem(name: "Ethiopian Birr", symbol: "Br", code: "ETB"),
            CurrencyItem(name: "Euro", symbol: "€", code: "EUR"),
            CurrencyItem(name: "Fijian Dollar", symbol: "FJ$", code: "FJD"),
            CurrencyItem(name: "Gambian Dalasi", symbol: "D", code: "GMD"),
            CurrencyItem(name: "Georgian Lari", symbol: "₾", code: "GEL"),
            CurrencyItem(name: "Ghanaian Cedi", symbol: "₵", code: "GHS"),
            CurrencyItem(name: "Guatemalan Quetzal", symbol: "Q", code: "GTQ"),
            CurrencyItem(name: "Guinean Franc", symbol: "Fr", code: "GNF"),
            CurrencyItem(name: "Haitian Gourde", symbol: "G", code: "HTG"),
            CurrencyItem(name: "Honduran Lempira", symbol: "L", code: "HNL"),
            CurrencyItem(name: "Hong Kong Dollar", symbol: "HK$", code: "HKD"),
            CurrencyItem(name: "Hungarian Forint", symbol: "Ft", code: "HUF"),
            CurrencyItem(name: "Icelandic Króna", symbol: "kr", code: "ISK"),
            CurrencyItem(name: "Indonesian Rupiah", symbol: "Rp", code: "IDR"),
            CurrencyItem(name: "Iranian Rial", symbol: "﷼", code: "IRR"),
            CurrencyItem(name: "Iraqi Dinar", symbol: "ع.د", code: "IQD"),
            CurrencyItem(name: "Israeli New Shekel", symbol: "₪", code: "ILS"),
            CurrencyItem(name: "Jamaican Dollar", symbol: "J$", code: "JMD"),
            CurrencyItem(name: "Japanese Yen", symbol: "¥", code: "JPY"),
            CurrencyItem(name: "Jordanian Dinar", symbol: "د.ا", code: "JOD"),
            CurrencyItem(name: "Kazakhstani Tenge", symbol: "₸", code: "KZT"),
            CurrencyItem(name: "Kenyan Shilling", symbol: "KSh", code: "KES"),
            CurrencyItem(name: "Kuwaiti Dinar", symbol: "د.ك", code: "KWD"),
            CurrencyItem(name: "Kyrgyzstani Som", symbol: "с", code: "KGS"),
            CurrencyItem(name: "Lao Kip", symbol: "₭", code: "LAK"),
            CurrencyItem(name: "Lebanese Pound", symbol: "ل.ل", code: "LBP"),
            CurrencyItem(name: "Lesotho Loti", symbol: "L", code: "LSL"),
            CurrencyItem(name: "Liberian Dollar", symbol: "L$", code: "LRD"),
            CurrencyItem(name: "Libyan Dinar", symbol: "ل.د", code: "LYD"),
            CurrencyItem(name: "Macanese Pataca", symbol: "P", code: "MOP"),
            CurrencyItem(name: "Macedonian Denar", symbol: "ден", code: "MKD"),
            CurrencyItem(name: "Malagasy Ariary", symbol: "Ar", code: "MGA"),
            CurrencyItem(name: "Malawian Kwacha", symbol: "MK", code: "MWK"),
            CurrencyItem(name: "Malaysian Ringgit", symbol: "RM", code: "MYR"),
            CurrencyItem(name: "Maldivian Rufiyaa", symbol: "Rf", code: "MVR"),
            CurrencyItem(name: "Mauritanian Ouguiya", symbol: "UM", code: "MRU"),
            CurrencyItem(name: "Mauritian Rupee", symbol: "₨", code: "MUR"),
            CurrencyItem(name: "Mexican Peso", symbol: "$", code: "MXN"),
            CurrencyItem(name: "Moldovan Leu", symbol: "L", code: "MDL"),
            CurrencyItem(name: "Mongolian Tögrög", symbol: "₮", code: "MNT"),
            CurrencyItem(name: "Moroccan Dirham", symbol: "د.م.", code: "MAD"),
            CurrencyItem(name: "Mozambican Metical", symbol: "MT", code: "MZN"),
            CurrencyItem(name: "Myanmar Kyat", symbol: "K", code: "MMK"),
            CurrencyItem(name: "Namibian Dollar", symbol: "N$", code: "NAD"),
            CurrencyItem(name: "Nepalese Rupee", symbol: "₨", code: "NPR"),
            CurrencyItem(name: "New Taiwan Dollar", symbol: "NT$", code: "TWD"),
            CurrencyItem(name: "New Zealand Dollar", symbol: "NZ$", code: "NZD"),
            CurrencyItem(name: "Nicaraguan Córdoba", symbol: "C$", code: "NIO"),
            CurrencyItem(name: "Nigerian Naira", symbol: "₦", code: "NGN"),
            CurrencyItem(name: "Norwegian Krone", symbol: "kr", code: "NOK"),
            CurrencyItem(name: "Omani Rial", symbol: "ر.ع.", code: "OMR"),
            CurrencyItem(name: "Pakistani Rupee", symbol: "₨", code: "PKR"),
            CurrencyItem(name: "Panamanian Balboa", symbol: "B/.", code: "PAB"),
            CurrencyItem(name: "Papua New Guinean Kina", symbol: "K", code: "PGK"),
            CurrencyItem(name: "Paraguayan Guaraní", symbol: "₲", code: "PYG"),
            CurrencyItem(name: "Peruvian Sol", symbol: "S/.", code: "PEN"),
            CurrencyItem(name: "Philippine Peso", symbol: "₱", code: "PHP"),
            CurrencyItem(name: "Polish Złoty", symbol: "zł", code: "PLN"),
            CurrencyItem(name: "Qatari Riyal", symbol: "ر.ق", code: "QAR"),
            CurrencyItem(name: "Romanian Leu", symbol: "lei", code: "RON"),
            CurrencyItem(name: "Russian Ruble", symbol: "₽", code: "RUB"),
            CurrencyItem(name: "Rwandan Franc", symbol: "Fr", code: "RWF"),
            CurrencyItem(name: "São Tomé Dobra", symbol: "Db", code: "STN"),
            CurrencyItem(name: "Saudi Riyal", symbol: "ر.س", code: "SAR"),
            CurrencyItem(name: "Serbian Dinar", symbol: "din", code: "RSD"),
            CurrencyItem(name: "Seychellois Rupee", symbol: "₨", code: "SCR"),
            CurrencyItem(name: "Sierra Leonean Leone", symbol: "Le", code: "SLL"),
            CurrencyItem(name: "Singapore Dollar", symbol: "S$", code: "SGD"),
            CurrencyItem(name: "Somali Shilling", symbol: "Sh", code: "SOS"),
            CurrencyItem(name: "South African Rand", symbol: "R", code: "ZAR"),
            CurrencyItem(name: "South Korean Won", symbol: "₩", code: "KRW"),
            CurrencyItem(name: "South Sudanese Pound", symbol: "£", code: "SSP"),
            CurrencyItem(name: "Sri Lankan Rupee", symbol: "₨", code: "LKR"),
            CurrencyItem(name: "Sudanese Pound", symbol: "£", code: "SDG"),
            CurrencyItem(name: "Swazi Lilangeni", symbol: "L", code: "SZL"),
            CurrencyItem(name: "Swedish Krona", symbol: "kr", code: "SEK"),
            CurrencyItem(name: "Swiss Franc", symbol: "Fr", code: "CHF"),
            CurrencyItem(name: "Syrian Pound", symbol: "£", code: "SYP"),
            CurrencyItem(name: "Tajikistani Somoni", symbol: "SM", code: "TJS"),
            CurrencyItem(name: "Tanzanian Shilling", symbol: "Sh", code: "TZS"),
            CurrencyItem(name: "Thai Baht", symbol: "฿", code: "THB"),
            CurrencyItem(name: "Tongan Paʻanga", symbol: "T$", code: "TOP"),
            CurrencyItem(name: "Trinidad & Tobago Dollar", symbol: "TT$", code: "TTD"),
            CurrencyItem(name: "Tunisian Dinar", symbol: "د.ت", code: "TND"),
            CurrencyItem(name: "Turkish Lira", symbol: "₺", code: "TRY"),
            CurrencyItem(name: "Turkmenistani Manat", symbol: "T", code: "TMT"),
            CurrencyItem(name: "Ugandan Shilling", symbol: "Sh", code: "UGX"),
            CurrencyItem(name: "Ukrainian Hryvnia", symbol: "₴", code: "UAH"),
            CurrencyItem(name: "United Arab Emirates Dirham", symbol: "د.إ", code: "AED"),
            CurrencyItem(name: "Uruguayan Peso", symbol: "$U", code: "UYU"),
            CurrencyItem(name: "US Dollar", symbol: "$", code: "USD"),
            CurrencyItem(name: "Uzbekistani Som", symbol: "сўм", code: "UZS"),
            CurrencyItem(name: "Vanuatu Vatu", symbol: "Vt", code: "VUV"),
            CurrencyItem(name: "Venezuelan Bolívar", symbol: "Bs.S", code: "VES"),
            CurrencyItem(name: "Vietnamese Đồng", symbol: "₫", code: "VND"),
            CurrencyItem(name: "Yemeni Rial", symbol: "﷼", code: "YER"),
            CurrencyItem(name: "Zambian Kwacha", symbol: "ZK", code: "ZMW"),
            CurrencyItem(name: "Zimbabwean Dollar", symbol: "Z$", code: "ZWL"),
        ].sorted { $0.name < $1.name }
        return rest
    }()

    private var pinnedINR: CurrencyItem {
        CurrencyItem(name: "Indian Rupee", symbol: "₹", code: "INR")
    }

    private var filtered: [CurrencyItem] {
        let q = search.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return Self.allCurrencies }
        return Self.allCurrencies.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            $0.code.localizedCaseInsensitiveContains(q) ||
            $0.symbol.contains(q)
        }
    }

    private var showPinned: Bool {
        search.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                SplitEZTheme.darkBg.frame(height: 160)
                Color(.systemGroupedBackground)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15))
                            .foregroundColor(SplitEZTheme.textTertiary)
                        TextField("Search currency, code or symbol", text: $search)
                            .font(.system(size: 15))
                            .foregroundColor(SplitEZTheme.textPrimary)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                        if !search.isEmpty {
                            Button { search = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(SplitEZTheme.textTertiary)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray5))
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    // Card
                    VStack(spacing: 0) {
                        if showPinned {
                            sectionHeader("SUGGESTED")
                            currencyRow(pinnedINR)
                            Divider().padding(.leading, 68)
                        }

                        if !filtered.isEmpty {
                            sectionHeader(showPinned ? "ALL CURRENCIES · A–Z" : "RESULTS")
                            ForEach(Array(filtered.enumerated()), id: \.element.id) { idx, currency in
                                if idx > 0 { Divider().padding(.leading, 68) }
                                currencyRow(currency)
                            }
                        } else {
                            Text("No results for "\(search)"")
                                .font(.subheadline)
                                .foregroundColor(SplitEZTheme.textTertiary)
                                .padding(32)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    .padding(.top, 4)

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationTitle("Currency")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(SplitEZTheme.darkBg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            selectedCode = auth.currentUser?.currency ?? "INR"
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(SplitEZTheme.textTertiary)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 6)
    }

    private func currencyRow(_ currency: CurrencyItem) -> some View {
        CurrencyRowView(
            currency: currency,
            isSelected: selectedCode == currency.code,
            onTap: {
                selectedCode = currency.code
                Task {
                    let _: AnyCodable? = try? await api.put("/users/me", body: ["currency": currency.code])
                    await auth.checkAuth()
                }
            }
        )
    }
}

private struct CurrencyRowView: View {
    let currency: CurrencyItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(SplitEZTheme.primary.opacity(isSelected ? 0.18 : 0.1))
                        .frame(width: 40, height: 40)
                    Text(currency.symbol)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(SplitEZTheme.primary)
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .frame(width: 34)
                }
                Text(currency.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(SplitEZTheme.textPrimary)
                Spacer()
                Text(currency.code)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(isSelected ? SplitEZTheme.primary : SplitEZTheme.textTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(isSelected ? SplitEZTheme.primary.opacity(0.07) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Edit Profile

struct EditProfileView: View {
    @EnvironmentObject var auth: AuthService
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var selectedCountry = CountryCode.india
    @State private var profileImage: UIImage?
    @State private var isSaving = false
    @State private var showPhotoOptions = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showCountryPicker = false
    @State private var pendingEmail = ""
    @State private var showOTPSheet = false
    @State private var emailVerified = false
    @Environment(\.dismiss) var dismiss
    private let api = APIClient.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Avatar picker
                VStack(spacing: 8) {
                    Button { showPhotoOptions = true } label: {
                        ZStack(alignment: .bottomTrailing) {
                            Group {
                                if let img = profileImage {
                                    Image(uiImage: img)
                                        .resizable().scaledToFill()
                                        .frame(width: 96, height: 96)
                                        .clipShape(Circle())
                                } else if let pic = auth.currentUser?.profilePicture, let url = URL(string: pic) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Circle().fill(SplitEZTheme.primary)
                                            .overlay(Text(auth.currentUser?.firstName.prefix(1).uppercased() ?? "A").font(.system(size: 36, weight: .bold)).foregroundColor(.white))
                                    }
                                    .frame(width: 96, height: 96)
                                    .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(SplitEZTheme.primary)
                                        .frame(width: 96, height: 96)
                                        .overlay(Text(auth.currentUser?.firstName.prefix(1).uppercased() ?? "A").font(.system(size: 36, weight: .bold)).foregroundColor(.white))
                                }
                            }
                            ZStack {
                                Circle().fill(Color(.systemBackground)).frame(width: 32, height: 32)
                                Circle().fill(SplitEZTheme.primary).frame(width: 28, height: 28)
                                Image(systemName: "camera.fill").font(.system(size: 12)).foregroundColor(.white)
                            }
                            .offset(x: 2, y: 2)
                        }
                    }
                    Text("Change photo")
                        .font(.caption)
                        .foregroundColor(SplitEZTheme.primary)
                }
                .padding(.top, 20)

                // Form
                VStack(alignment: .leading, spacing: 20) {
                    // Full Name
                    fieldSection(label: "FULL NAME") {
                        TextField("Full name", text: $fullName)
                            .font(.system(size: 16))
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(SplitEZTheme.primary.opacity(0.3), lineWidth: 1))
                    }

                    // Email
                    fieldSection(label: "EMAIL") {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                TextField("Email address", text: $email)
                                    .font(.system(size: 16))
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                if emailVerified {
                                    Label("Verified", systemImage: "checkmark.seal.fill")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(SplitEZTheme.positive)
                                        .labelStyle(.iconOnly)
                                } else if email != (auth.currentUser?.email ?? "") && !email.isEmpty {
                                    Button("Send code") {
                                        pendingEmail = email
                                        showOTPSheet = true
                                    }
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Capsule().fill(SplitEZTheme.primary))
                                }
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(emailVerified ? SplitEZTheme.positive : Color(.systemGray4), lineWidth: 1))

                            if email != (auth.currentUser?.email ?? "") && !email.isEmpty && !emailVerified {
                                Label("Verify to update your email", systemImage: "exclamationmark.circle")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }

                    // Phone
                    fieldSection(label: "PHONE") {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 0) {
                                // Country code button
                                Button { showCountryPicker = true } label: {
                                    HStack(spacing: 6) {
                                        Text(selectedCountry.flag)
                                            .font(.system(size: 18))
                                        Text(selectedCountry.dialCode)
                                            .font(.system(size: 15))
                                            .foregroundColor(SplitEZTheme.textPrimary)
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(SplitEZTheme.textTertiary)
                                    }
                                    .padding(.leading, 14)
                                }
                                Rectangle()
                                    .fill(Color(.systemGray4))
                                    .frame(width: 1, height: 22)
                                    .padding(.horizontal, 10)
                                TextField("Phone number", text: $phone)
                                    .font(.system(size: 16))
                                    .keyboardType(.phonePad)
                            }
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color(.systemGray4), lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Save button
                Button {
                    Task {
                        isSaving = true
                        let parts = fullName.split(separator: " ", maxSplits: 1)
                        let first = String(parts.first ?? "")
                        let last = parts.count > 1 ? String(parts[1]) : nil
                        let _: UserProfile? = try? await api.put("/users/me", body: UpdateUserRequest(firstName: first, lastName: last))
                        await auth.checkAuth()
                        isSaving = false
                        dismiss()
                    }
                } label: {
                    Group {
                        if isSaving { ProgressView().tint(.white) }
                        else { Text("Save changes").font(.subheadline.weight(.bold)).foregroundColor(.white) }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(fullName.isEmpty ? SplitEZTheme.primary.opacity(0.4) : SplitEZTheme.primary))
                }
                .disabled(fullName.isEmpty || isSaving)
                .padding(.horizontal, 20)

            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(SplitEZTheme.darkBg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            let user = auth.currentUser
            fullName = user?.displayName ?? ""
            email = user?.email ?? ""
            phone = user?.phone ?? ""
            emailVerified = user?.email != nil
        }
        .confirmationDialog("Change Profile Photo", isPresented: $showPhotoOptions) {
            Button("Take Photo") { showCamera = true }
            Button("Choose from Library") { showPhotoPicker = true }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showCamera) {
            ImagePickerView(sourceType: .camera, selectedImage: $profileImage)
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImagePickerView(sourceType: .photoLibrary, selectedImage: $profileImage)
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerSheet(selected: $selectedCountry)
        }
        .sheet(isPresented: $showOTPSheet) {
            OTPVerificationSheet(
                destination: pendingEmail,
                onVerified: {
                    emailVerified = true
                    email = pendingEmail
                    showOTPSheet = false
                }
            )
        }
    }

    private func fieldSection<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(SplitEZTheme.primary)
                .tracking(0.5)
            content()
        }
    }
}

// MARK: - Country Code

struct CountryCode: Identifiable, Equatable {
    let id = UUID()
    let flag: String
    let name: String
    let dialCode: String

    static let india = CountryCode(flag: "🇮🇳", name: "India", dialCode: "+91")

    static let all: [CountryCode] = [
        CountryCode(flag: "🇮🇳", name: "India", dialCode: "+91"),
        CountryCode(flag: "🇺🇸", name: "United States", dialCode: "+1"),
        CountryCode(flag: "🇬🇧", name: "United Kingdom", dialCode: "+44"),
        CountryCode(flag: "🇦🇺", name: "Australia", dialCode: "+61"),
        CountryCode(flag: "🇨🇦", name: "Canada", dialCode: "+1"),
        CountryCode(flag: "🇦🇪", name: "UAE", dialCode: "+971"),
        CountryCode(flag: "🇸🇬", name: "Singapore", dialCode: "+65"),
        CountryCode(flag: "🇩🇪", name: "Germany", dialCode: "+49"),
        CountryCode(flag: "🇫🇷", name: "France", dialCode: "+33"),
        CountryCode(flag: "🇯🇵", name: "Japan", dialCode: "+81"),
        CountryCode(flag: "🇨🇳", name: "China", dialCode: "+86"),
        CountryCode(flag: "🇧🇷", name: "Brazil", dialCode: "+55"),
        CountryCode(flag: "🇿🇦", name: "South Africa", dialCode: "+27"),
        CountryCode(flag: "🇳🇬", name: "Nigeria", dialCode: "+234"),
        CountryCode(flag: "🇲🇾", name: "Malaysia", dialCode: "+60"),
        CountryCode(flag: "🇳🇿", name: "New Zealand", dialCode: "+64"),
        CountryCode(flag: "🇮🇩", name: "Indonesia", dialCode: "+62"),
        CountryCode(flag: "🇵🇰", name: "Pakistan", dialCode: "+92"),
        CountryCode(flag: "🇧🇩", name: "Bangladesh", dialCode: "+880"),
        CountryCode(flag: "🇱🇰", name: "Sri Lanka", dialCode: "+94"),
    ]
}

struct CountryPickerSheet: View {
    @Binding var selected: CountryCode
    @State private var search = ""
    @Environment(\.dismiss) var dismiss

    private var filtered: [CountryCode] {
        if search.isEmpty { return CountryCode.all }
        return CountryCode.all.filter { $0.name.localizedCaseInsensitiveContains(search) || $0.dialCode.contains(search) }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { country in
                Button {
                    selected = country
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Text(country.flag).font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(country.name).font(.subheadline.weight(.medium)).foregroundColor(SplitEZTheme.textPrimary)
                            Text(country.dialCode).font(.caption).foregroundColor(SplitEZTheme.textTertiary)
                        }
                        Spacer()
                        if country == selected {
                            Image(systemName: "checkmark").foregroundColor(SplitEZTheme.primary)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $search, prompt: "Search country")
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - OTP Verification Sheet

struct OTPVerificationSheet: View {
    let destination: String
    let onVerified: () -> Void

    @State private var code = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var resendCountdown = 30
    @State private var timer: Timer?
    @Environment(\.dismiss) var dismiss
    private let api = APIClient.shared

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            Image(systemName: "envelope.badge")
                .font(.system(size: 44))
                .foregroundColor(SplitEZTheme.primary)

            VStack(spacing: 6) {
                Text("Enter verification code")
                    .font(.title3.weight(.bold))
                    .foregroundColor(SplitEZTheme.textPrimary)
                Text("We sent a 6-digit code to")
                    .font(.subheadline)
                    .foregroundColor(SplitEZTheme.textSecondary)
                Text(destination)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(SplitEZTheme.textPrimary)
            }
            .multilineTextAlignment(.center)

            // 6-box OTP input
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { i in
                    let char = code.count > i ? String(Array(code)[i]) : ""
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(code.count == i ? SplitEZTheme.primary : Color(.systemGray4), lineWidth: code.count == i ? 2 : 1)
                            .frame(width: 44, height: 52)
                        Text(char)
                            .font(.title2.weight(.bold))
                            .foregroundColor(SplitEZTheme.textPrimary)
                    }
                }
            }
            .overlay(
                TextField("", text: $code)
                    .keyboardType(.numberPad)
                    .font(.system(size: 1))
                    .foregroundColor(.clear)
                    .accentColor(.clear)
                    .onChange(of: code) { _, v in
                        code = String(v.filter(\.isNumber).prefix(6))
                        if code.count == 6 { verifyCode() }
                    }
            )

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.negative)
            }

            if resendCountdown > 0 {
                Text("Resend in \(resendCountdown)s")
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.textTertiary)
            } else {
                Button("Resend code") { sendCode(); startTimer() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(SplitEZTheme.primary)
            }

            Button {
                verifyCode()
            } label: {
                Group {
                    if isLoading { ProgressView().tint(.white) }
                    else { Text("Verify").font(.subheadline.weight(.bold)).foregroundColor(.white) }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(code.count == 6 ? SplitEZTheme.primary : SplitEZTheme.primary.opacity(0.4)))
            }
            .disabled(code.count < 6 || isLoading)
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.horizontal, 24)
        .presentationDetents([.medium])
        .onAppear { sendCode(); startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    private func startTimer() {
        resendCountdown = 30
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if resendCountdown > 0 { resendCountdown -= 1 } else { t.invalidate() }
        }
    }

    private func sendCode() {
        let body: [String: String] = ["email": destination]
        Task { let _: AnyCodable? = try? await api.post("/auth/send-otp", body: body) }
    }

    private func verifyCode() {
        isLoading = true
        error = nil
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            // In production: await api.post("/auth/verify-otp", body: ...)
            // For demo, accept any 6-digit code
            await MainActor.run {
                isLoading = false
                onVerified()
            }
        }
    }
}

// MARK: - Image Picker

struct ImagePickerView: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        init(_ parent: ImagePickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let edited = info[.editedImage] as? UIImage {
                parent.selectedImage = edited
            } else if let original = info[.originalImage] as? UIImage {
                parent.selectedImage = original
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
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

// MARK: - Manage Subscription Sheet

struct ManageSubscriptionSheet: View {
    @Binding var isPlusUser: Bool
    @Environment(\.dismiss) var dismiss
    @State private var showCancelConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 24)

            VStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(SplitEZTheme.primary)
                Text("SplitEZ Ad Free")
                    .font(.title3.weight(.bold))
                    .foregroundColor(SplitEZTheme.textPrimary)
                Text("Active subscription")
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.positive)
            }
            .padding(.bottom, 24)

            VStack(spacing: 0) {
                infoRow(label: "Plan", value: "Ad Free Monthly")
                Divider().padding(.leading, 20)
                infoRow(label: "Price", value: "₹99 / month")
                Divider().padding(.leading, 20)
                infoRow(label: "Renews on", value: "15 Oct 2026")
                Divider().padding(.leading, 20)
                infoRow(label: "Status", value: "Active")
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
            .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 10) {
                Text("INCLUDED IN YOUR PLAN")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(SplitEZTheme.textTertiary)
                    .tracking(0.5)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                ForEach(["No ads, ever", "Priority support", "Data exports (CSV)", "Early access to new features"], id: \.self) { feature in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(SplitEZTheme.positive)
                        Text(feature)
                            .font(.subheadline)
                            .foregroundColor(SplitEZTheme.textPrimary)
                    }
                    .padding(.horizontal, 24)
                }
            }

            Spacer()

            Button {
                showCancelConfirm = true
            } label: {
                Text("Cancel subscription")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(SplitEZTheme.negative)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(SplitEZTheme.negative, lineWidth: 1)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .presentationDetents([.medium, .large])
        .alert("Cancel Subscription?", isPresented: $showCancelConfirm) {
            Button("Keep Plan", role: .cancel) {}
            Button("Cancel Subscription", role: .destructive) {
                isPlusUser = false
                dismiss()
            }
        } message: {
            Text("Your plan stays active until 15 Oct 2026. After that, ads will resume.")
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(SplitEZTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(SplitEZTheme.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

// MARK: - Contact Form Sheet

struct ContactFormSheet: View {
    @EnvironmentObject var auth: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var topic = "Feedback"
    @State private var message = ""
    @State private var attachments: [UIImage] = []
    @State private var showPhotoPicker = false
    @State private var isSending = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    private let api = APIClient.shared

    let topics = ["Feedback", "Complaints", "Suggestions", "General"]

    var isValid: Bool { !name.isEmpty && !email.isEmpty && !message.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Dark header background
                VStack(spacing: 0) {
                    SplitEZTheme.darkBg.frame(height: 120)
                    Color(.systemGroupedBackground)
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Sub-header
                        Text("We usually reply within 24 hours")
                            .font(.subheadline)
                            .foregroundColor(Color.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)

                        // Form card
                        VStack(alignment: .leading, spacing: 0) {
                            formField(label: "NAME") {
                                TextField("Full name", text: $name)
                                    .font(.system(size: 16))
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 12)
                            }
                            Divider()
                            formField(label: "EMAIL") {
                                TextField("Email address", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .font(.system(size: 16))
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 12)
                            }
                            Divider()
                            formField(label: "PHONE") {
                                TextField("+91 XXXXX XXXXX", text: $phone)
                                    .keyboardType(.phonePad)
                                    .font(.system(size: 16))
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 12)
                            }
                            Divider()
                            formField(label: "TOPIC") {
                                Menu {
                                    ForEach(topics, id: \.self) { t in
                                        Button(t) { topic = t }
                                    }
                                } label: {
                                    HStack {
                                        Text(topic)
                                            .font(.system(size: 16))
                                            .foregroundColor(SplitEZTheme.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(SplitEZTheme.primary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(SplitEZTheme.primary, lineWidth: 1.5)
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                }
                            }
                            Divider()
                            formField(label: "MESSAGE") {
                                ZStack(alignment: .topLeading) {
                                    TextEditor(text: $message)
                                        .font(.system(size: 16))
                                        .frame(minHeight: 110)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                    if message.isEmpty {
                                        Text("Tell us what's on your mind...")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(.placeholderText))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 16)
                                            .allowsHitTesting(false)
                                    }
                                }
                            }
                            Divider()

                            // Attachments
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ATTACHMENTS")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(SplitEZTheme.textTertiary)
                                    .tracking(0.5)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)

                                if !attachments.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(attachments.indices, id: \.self) { i in
                                                ZStack(alignment: .topTrailing) {
                                                    Image(uiImage: attachments[i])
                                                        .resizable().scaledToFill()
                                                        .frame(width: 64, height: 64)
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                    Button {
                                                        attachments.remove(at: i)
                                                    } label: {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .font(.system(size: 18))
                                                            .foregroundColor(.white)
                                                            .background(Circle().fill(Color.black.opacity(0.5)))
                                                    }
                                                    .offset(x: 4, y: -4)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }

                                Button { showPhotoPicker = true } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "paperclip")
                                            .font(.system(size: 18))
                                            .foregroundColor(SplitEZTheme.primary)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Browse files")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(SplitEZTheme.primary)
                                            Text("JPG, PNG or PDF · up to 10 MB")
                                                .font(.caption)
                                                .foregroundColor(SplitEZTheme.textTertiary)
                                        }
                                        Spacer()
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                                            .foregroundColor(SplitEZTheme.primary.opacity(0.4))
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 16)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal, 0)

                        if let err = errorMessage {
                            Text(err)
                                .font(.caption)
                                .foregroundColor(SplitEZTheme.negative)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                        }

                        // Submit
                        Button {
                            submitForm()
                        } label: {
                            Group {
                                if isSending { ProgressView().tint(.white) }
                                else { Text("Submit").font(.subheadline.weight(.bold)).foregroundColor(.white) }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(RoundedRectangle(cornerRadius: 32).fill(isValid ? SplitEZTheme.primary : SplitEZTheme.primary.opacity(0.4)))
                        }
                        .disabled(!isValid || isSending)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Contact us")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SplitEZTheme.darkBg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .onAppear {
                let user = auth.currentUser
                name = user?.displayName ?? ""
                email = user?.email ?? ""
                phone = user?.phone ?? ""
            }
            .sheet(isPresented: $showPhotoPicker) {
                ImagePickerView(sourceType: .photoLibrary, selectedImage: Binding(
                    get: { nil },
                    set: { if let img = $0 { attachments.append(img) } }
                ))
            }
            .alert("Message Sent", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("We've received your message and will get back to you within 24 hours.")
            }
        }
    }

    private func submitForm() {
        isSending = true
        errorMessage = nil
        Task {
            do {
                struct EnquiryBody: Encodable {
                    let name: String
                    let email: String
                    let phone: String?
                    let topic: String
                    let message: String
                    let attachments: [String]
                }
                let body = EnquiryBody(
                    name: name,
                    email: email,
                    phone: phone.isEmpty ? nil : phone,
                    topic: topic,
                    message: message,
                    attachments: []
                )
                let _: AnyCodable? = try? await api.post("/support/enquiries", body: body)
                await MainActor.run {
                    isSending = false
                    showSuccess = true
                }
            }
        }
    }

    private func formField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(SplitEZTheme.textTertiary)
                .tracking(0.5)
                .padding(.horizontal, 16)
                .padding(.top, 12)
            content()
        }
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
