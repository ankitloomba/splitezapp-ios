import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var auth: AuthService

    var body: some View {
        NavigationStack {
            List {
                if let user = auth.currentUser {
                    Section {
                        HStack {
                            if let avatar = user.avatar {
                                Circle()
                                    .fill(Color(hex: avatar.backgroundColor))
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Text(avatar.initials)
                                            .font(.title2.bold())
                                            .foregroundColor(.white)
                                    )
                            }
                            VStack(alignment: .leading) {
                                Text(user.displayName).font(.headline)
                                if let email = user.email {
                                    Text(email).font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                Section("Account") {
                    NavigationLink("Edit Profile") {
                        EditProfileView()
                    }
                    NavigationLink("People") {
                        PeopleListView()
                    }
                }

                Section("Preferences") {
                    HStack {
                        Text("Currency")
                        Spacer()
                        Text(auth.currentUser?.currency ?? "INR")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button("Log Out", role: .destructive) {
                        Task { await auth.logout() }
                    }
                }

                Section {
                    Text("SplitEZ v1.0.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
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
