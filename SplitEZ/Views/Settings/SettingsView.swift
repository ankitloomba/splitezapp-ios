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

                            settingsRow(label: "Notifications") {
                                NotificationsListView()
                            }
                            rowDivider

                            settingsRow(label: "Security") {
                                // Placeholder
                                Text("Security settings coming soon")
                                    .navigationTitle("Security")
                            }
                            rowDivider

                            settingsRow(label: "Appearance") {
                                // Placeholder
                                Text("Appearance settings coming soon")
                                    .navigationTitle("Appearance")
                            }
                            rowDivider

                            settingsRowWithValue(label: "Currency & language", value: "\(auth.currentUser?.currency ?? "INR") · EN") {
                                // Placeholder
                                Text("Currency & language settings coming soon")
                                    .navigationTitle("Currency & language")
                            }

                            // Help & Support
                            sectionLabel("HELP & SUPPORT")

                            settingsRowWithIcon(icon: "envelope", label: "Contact us") {
                                Text("Contact support coming soon")
                                    .navigationTitle("Contact us")
                            }
                            rowDivider

                            settingsRow(label: "Rate SplitEZ") {
                                Text("Rate SplitEZ coming soon")
                                    .navigationTitle("Rate SplitEZ")
                            }

                            // Log out
                            Button {
                                Task { await auth.logout() }
                            } label: {
                                Text("Log out")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color(red: 0.85, green: 0.25, blue: 0.2))
                                    )
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 24)

                            // Footer
                            VStack(spacing: 4) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(SplitEZTheme.primary)
                                        .frame(width: 16, height: 16)
                                    Text("An ")
                                        .font(.caption)
                                        .foregroundColor(SplitEZTheme.textTertiary)
                                    + Text("Adrevo")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(SplitEZTheme.primary)
                                    + Text(" Product")
                                        .font(.caption)
                                        .foregroundColor(SplitEZTheme.textTertiary)
                                }
                                Text("© 2026 SplitEZ · 1.0.0")
                                    .font(.caption2)
                                    .foregroundColor(SplitEZTheme.textTertiary)
                            }
                            .padding(.top, 16)
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
        VStack(spacing: 16) {
            // Back + title
            HStack {
                // Back button only when pushed onto nav stack
                Spacer()
                Text("Account")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }

            // User info
            if let user = auth.currentUser {
                HStack(spacing: 14) {
                    // Avatar with dashed border
                    ZStack(alignment: .bottomLeading) {
                        Circle()
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                            .foregroundColor(SplitEZTheme.primary)
                            .frame(width: 68, height: 68)
                            .overlay(
                                Group {
                                    if let avatar = user.avatar {
                                        Circle()
                                            .fill(Color(hex: avatar.backgroundColor))
                                            .frame(width: 58, height: 58)
                                            .overlay(
                                                Text(avatar.initials)
                                                    .font(.title2.bold())
                                                    .foregroundColor(.white)
                                            )
                                    } else {
                                        Circle()
                                            .fill(SplitEZTheme.primary)
                                            .frame(width: 58, height: 58)
                                            .overlay(
                                                Text(user.firstName.prefix(1).uppercased())
                                                    .font(.title2.bold())
                                                    .foregroundColor(.white)
                                            )
                                    }
                                }
                            )

                        // QR badge
                        Image(systemName: "qrcode")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Circle().fill(SplitEZTheme.primary))
                            .offset(x: 2, y: 2)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.displayName)
                            .font(.title3.weight(.bold))
                            .foregroundColor(.white)
                        if let email = user.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(SplitEZTheme.textTertiary)
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
                Text("Get SplitEZ Ad Free")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
                Text("No ads · priority support · exports")
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.7))
            }
            Spacer()
            Text("₹99/mo")
                .font(.subheadline.weight(.bold))
                .foregroundColor(SplitEZTheme.darkBg)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(red: 0.95, green: 0.8, blue: 0.4))
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [SplitEZTheme.primary, SplitEZTheme.primary.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }

    // MARK: – Helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundColor(SplitEZTheme.textTertiary)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
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
                    .foregroundColor(SplitEZTheme.primary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(SplitEZTheme.textTertiary)
                    .padding(.leading, 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private func settingsRowWithIcon<D: View>(icon: String, label: String, @ViewBuilder destination: () -> D) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(SplitEZTheme.textSecondary)
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

    private var rowDivider: some View {
        Divider().padding(.leading, 20)
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
