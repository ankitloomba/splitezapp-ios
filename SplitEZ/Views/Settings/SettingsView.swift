import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var auth: AuthService

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    SplitEZTheme.darkBg.frame(height: 260)
                    Color(.systemBackground)
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Dark header
                        settingsHeader

                        // White content card
                        VStack(spacing: 0) {
                            // Upgrade banner
                            upgradeBanner
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                                .padding(.bottom, 8)

                            // Preferences
                            sectionLabel("PREFERENCES")

                            settingsRowWithIconAndToggle(
                                icon: "moon",
                                label: "Dark mode",
                                subtitle: "Follow system · On · Off"
                            )
                            rowDivider

                            settingsRowWithIconAndValue(
                                icon: "questionmark.circle",
                                label: "Default currency",
                                value: "\(auth.currentUser?.currency ?? "INR") ₹"
                            ) {
                                Text("Currency settings coming soon")
                                    .navigationTitle("Default currency")
                            }
                            rowDivider

                            settingsRowWithIcon(icon: "bell", label: "Notifications") {
                                NotificationsListView()
                            }
                            rowDivider

                            settingsRowWithIconAndValue(
                                icon: "globe",
                                label: "Language",
                                value: "English"
                            ) {
                                Text("Language settings coming soon")
                                    .navigationTitle("Language")
                            }

                            // Account
                            sectionLabel("ACCOUNT")

                            settingsRow(label: "Payment methods · UPI") {
                                Text("Payment methods coming soon")
                                    .navigationTitle("Payment methods")
                            }
                            rowDivider

                            settingsRow(label: "Export all data") {
                                ExportView()
                            }
                            rowDivider

                            // Log out
                            Button {
                                Task { await auth.logout() }
                            } label: {
                                Text("Log out")
                                    .font(.subheadline)
                                    .foregroundColor(SplitEZTheme.negative)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 14)
                            }

                            // Footer
                            Text("SplitEZ 2.4.0 · Made in India")
                                .font(.caption)
                                .foregroundColor(SplitEZTheme.textTertiary)
                                .padding(.top, 32)
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

    // MARK: – Header

    private var settingsHeader: some View {
        VStack(spacing: 12) {
            // Back + Edit
            HStack {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
                NavigationLink(destination: EditProfileView()) {
                    Text("Edit")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                }
            }

            // User info
            if let user = auth.currentUser {
                HStack(spacing: 14) {
                    // Avatar with camera badge
                    ZStack(alignment: .bottomLeading) {
                        if let avatar = user.avatar {
                            Circle()
                                .fill(Color(hex: avatar.backgroundColor))
                                .frame(width: 72, height: 72)
                                .overlay(
                                    Text(avatar.initials)
                                        .font(.title.bold())
                                        .foregroundColor(.white)
                                )
                        } else {
                            Circle()
                                .fill(SplitEZTheme.primary)
                                .frame(width: 72, height: 72)
                                .overlay(
                                    Text(user.firstName.prefix(1).uppercased())
                                        .font(.title.bold())
                                        .foregroundColor(.white)
                                )
                        }

                        // Camera badge
                        Image(systemName: "camera.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(5)
                            .background(Circle().fill(SplitEZTheme.darkBg).overlay(Circle().stroke(Color.white, lineWidth: 1.5)))
                            .offset(x: 0, y: 4)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.displayName)
                            .font(.title3.weight(.bold))
                            .foregroundColor(.white)
                        HStack(spacing: 0) {
                            if let email = user.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(SplitEZTheme.textTertiary)
                            }
                            if let phone = user.phone, !phone.isEmpty {
                                Text(" · \(phone)")
                                    .font(.caption)
                                    .foregroundColor(SplitEZTheme.textTertiary)
                            }
                        }
                        Text("Add profile photo")
                            .font(.caption.weight(.medium))
                            .foregroundColor(SplitEZTheme.primary)
                    }

                    Spacer()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(SplitEZTheme.darkBg)
    }

    // MARK: – Upgrade Banner

    private var upgradeBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("SplitEZ Plus · ad-free")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(SplitEZTheme.textPrimary)
                Text("7 days free, then ₹99/month")
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.textSecondary)
            }
            Spacer()
            Button("Start trial") {}
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(SplitEZTheme.darkBg)
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(SplitEZTheme.textTertiary.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: – Helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundColor(SplitEZTheme.primary)
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

    private func settingsRowWithIcon<D: View>(icon: String, label: String, @ViewBuilder destination: () -> D) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(SplitEZTheme.textSecondary)
                    .frame(width: 24)
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

    private func settingsRowWithIconAndValue<D: View>(icon: String, label: String, value: String, @ViewBuilder destination: () -> D) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(SplitEZTheme.textSecondary)
                    .frame(width: 24)
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(SplitEZTheme.textPrimary)
                Spacer()
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(SplitEZTheme.primary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(SplitEZTheme.textTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    @State private var darkModeOn = true

    private func settingsRowWithIconAndToggle(icon: String, label: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(SplitEZTheme.textSecondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(SplitEZTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.textTertiary)
            }
            Spacer()
            Toggle("", isOn: $darkModeOn)
                .labelsHidden()
                .tint(SplitEZTheme.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var rowDivider: some View {
        Divider().padding(.leading, 56)
    }
}

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
