import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var auth: AuthService
    @State private var isPlusUser = false

    var body: some View {
        NavigationStack {
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
                            // Preferences
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

                            // Help & Support
                            sectionLabel("HELP & SUPPORT")

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
                            rowDivider

                            settingsRow(label: "Rate SplitEZ") {
                                Text("Rate SplitEZ coming soon").navigationTitle("Rate SplitEZ")
                            }

                            // Log out button
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

                            // Footer
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
        }
    }

    // MARK: - Header

    private var settingsHeader: some View {
        VStack(spacing: 16) {
            // Nav bar
            HStack {
                Button(action: {}) {
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

            // Profile row
            if let user = auth.currentUser {
                HStack(spacing: 14) {
                    // Avatar with QR badge
                    ZStack(alignment: .bottomLeading) {
                        Circle()
                            .stroke(
                                SplitEZTheme.primary.opacity(0.3),
                                style: StrokeStyle(lineWidth: 2, dash: [4, 3])
                            )
                            .frame(width: 68, height: 68)
                            .overlay(
                                Circle()
                                    .fill(SplitEZTheme.primary)
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Text(user.firstName.prefix(1).uppercased())
                                            .font(.title2.bold())
                                            .foregroundColor(.white)
                                    )
                            )

                        Image(systemName: "qrcode")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(5)
                            .background(
                                Circle()
                                    .fill(SplitEZTheme.primary)
                                    .overlay(Circle().stroke(SplitEZTheme.darkBg, lineWidth: 2))
                            )
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

            // Upgrade banner
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
                Button("Manage") {}
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
                Button("₹99/mo") {}
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
    @State private var pushEnabled = true
    @State private var emailEnabled = true
    @State private var newExpenses = true
    @State private var paymentReceived = true
    @State private var friendRequests = true
    @State private var reminders = true
    @State private var groupUpdates = false
    @State private var promotions = false

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                SplitEZTheme.darkBg.frame(height: 100)
                Color(.systemBackground)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header handled by NavigationStack title
                    Spacer().frame(height: 8)

                    VStack(spacing: 0) {
                        toggleRow(label: "Push notifications", subtitle: "Reminders, settlements & activity", isOn: $pushEnabled)
                        rowDivider
                        toggleRow(label: "Email notifications", subtitle: "Weekly summary & receipts", isOn: $emailEnabled)

                        sectionLabel("NOTIFY ME ABOUT")

                        toggleRow(label: "New expenses added", isOn: $newExpenses)
                        rowDivider
                        toggleRow(label: "Payment received", isOn: $paymentReceived)
                        rowDivider
                        toggleRow(label: "Friend requests", isOn: $friendRequests)
                        rowDivider
                        toggleRow(label: "Reminders sent to you", isOn: $reminders)
                        rowDivider
                        toggleRow(label: "Group updates", isOn: $groupUpdates)
                        rowDivider
                        toggleRow(label: "Promotional offers", isOn: $promotions)

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

    private func toggleRow(label: String, subtitle: String? = nil, isOn: Binding<Bool>) -> some View {
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
    @State private var biometricEnabled = true
    @State private var appLockEnabled = false

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
                        // Change password
                        NavigationLink(destination: Text("Change password coming soon").navigationTitle("Change Password")) {
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
                                Text("Face ID / fingerprint")
                                    .font(.caption)
                                    .foregroundColor(SplitEZTheme.textTertiary)
                            }
                            Spacer()
                            Toggle("", isOn: $biometricEnabled)
                                .labelsHidden()
                                .tint(SplitEZTheme.primary)
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
                            Toggle("", isOn: $appLockEnabled)
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
                                Text("iPhone 15 Pro")
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
                            Button("Revoke") {}
                                .font(.caption.weight(.medium))
                                .foregroundColor(SplitEZTheme.negative)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)

                        // Log out all
                        Button(action: {}) {
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

                        NavigationLink(destination: Text("Delete account coming soon").navigationTitle("Delete Account")) {
                            HStack(spacing: 12) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16))
                                    .foregroundColor(SplitEZTheme.positive)
                                Text("Delete account")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(SplitEZTheme.positive)
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

// MARK: - Appearance Settings

struct AppearanceSettingsView: View {
    @State private var darkModeOption = 0 // 0=system, 1=light, 2=dark

    var body: some View {
        VStack(spacing: 0) {
            Picker("Theme", selection: $darkModeOption) {
                Text("System").tag(0)
                Text("Light").tag(1)
                Text("Dark").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(20)

            Spacer()
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Currency & Language

struct CurrencyLanguageView: View {
    var body: some View {
        List {
            Section("Currency") {
                Text("INR ₹ (Indian Rupee)")
            }
            Section("Language") {
                Text("English")
            }
        }
        .navigationTitle("Currency & language")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Edit Profile

struct EditProfileView: View {
    @EnvironmentObject var auth: AuthService
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isSaving = false
    private let api = APIClient.shared

    var body: some View {
        Form {
            TextField("First Name", text: $firstName)
            TextField("Last Name", text: $lastName)
            Button("Save") {
                Task {
                    isSaving = true
                    let _: UserProfile? = try? await api.put("/users/me", body: UpdateUserRequest(
                        firstName: firstName, lastName: lastName.isEmpty ? nil : lastName))
                    await auth.checkAuth()
                    isSaving = false
                }
            }
            .disabled(firstName.isEmpty || isSaving)
        }
        .navigationTitle("Edit Profile")
        .onAppear {
            firstName = auth.currentUser?.firstName ?? ""
            lastName = auth.currentUser?.lastName ?? ""
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
