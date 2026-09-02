import SwiftUI

struct GroupsListView: View {
    @State private var groups: [Group] = []
    @State private var isLoading = true
    @State private var showCreate = false
    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            List {
                ForEach(groups) { group in
                    NavigationLink(destination: GroupDetailView(group: group)) {
                        HStack {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(SplitEZTheme.primary)
                                .frame(width: 40, height: 40)
                                .background(SplitEZTheme.primary.opacity(0.1))
                                .clipShape(Circle())
                            VStack(alignment: .leading) {
                                Text(group.name).font(.headline)
                                Text("\(group.memberCount ?? 0) members")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .overlay {
                if groups.isEmpty && !isLoading {
                    ContentUnavailableView("No Groups",
                        systemImage: "person.3",
                        description: Text("Create a group to start splitting expenses"))
                }
            }
            .navigationTitle("Groups")
            .toolbar {
                Button { showCreate = true } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateGroupView { await loadGroups() }
            }
            .refreshable { await loadGroups() }
            .task { await loadGroups() }
        }
    }

    private func loadGroups() async {
        isLoading = true
        groups = (try? await api.get("/groups")) ?? []
        isLoading = false
    }
}

struct GroupDetailView: View {
    let group: Group
    @State private var expenses: [Expense] = []
    @State private var balances: [Balance] = []
    private let api = APIClient.shared

    var body: some View {
        List {
            Section("Members") {
                ForEach(group.members ?? [], id: \.id) { member in
                    HStack {
                        AvatarView(user: member, size: 32)
                        Text(member.displayName)
                    }
                }
            }
            Section("Balances") {
                if balances.isEmpty {
                    Text("All settled up!").foregroundColor(.secondary)
                }
                ForEach(balances, id: \.userId) { b in
                    BalanceRow(balance: b)
                }
            }
            Section("Expenses") {
                ForEach(expenses) { expense in
                    ExpenseRow(expense: expense)
                }
            }
        }
        .navigationTitle(group.name)
        .task {
            expenses = (try? await api.get("/expenses", query: ["groupId": group.id])) ?? []
            balances = (try? await api.get("/balances", query: ["groupId": group.id])) ?? []
        }
    }
}

struct CreateGroupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var isLoading = false
    let onCreated: () async -> Void
    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            Form {
                TextField("Group Name", text: $name)
                TextField("Description (optional)", text: $description)
            }
            .navigationTitle("New Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isLoading = true
                            let _: Group? = try? await api.post("/groups", body: CreateGroupRequest(
                                name: name,
                                description: description.isEmpty ? nil : description
                            ))
                            await onCreated()
                            isLoading = false
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || isLoading)
                }
            }
        }
    }
}
