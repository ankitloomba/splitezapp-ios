import SwiftUI

struct GroupsListView: View {
    @State private var groups: [ExpenseGroup] = []
    @State private var isLoading = true
    @State private var showCreate = false
    @Environment(\.dismiss) var dismiss
    private let api = APIClient.shared

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                SplitEZTheme.darkBg.frame(height: 120)
                Color(.systemBackground)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Dark header
                    HStack {
                        Text("Groups")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Button { showCreate = true } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .background(SplitEZTheme.darkBg)

                    // Content card
                    VStack(spacing: 0) {
                        if groups.isEmpty && !isLoading {
                            VStack(spacing: 12) {
                                Image(systemName: "person.3")
                                    .font(.system(size: 40))
                                    .foregroundColor(SplitEZTheme.textTertiary)
                                Text("No Groups")
                                    .font(.headline)
                                    .foregroundColor(SplitEZTheme.textPrimary)
                                Text("Create a group to start splitting expenses")
                                    .font(.subheadline)
                                    .foregroundColor(SplitEZTheme.textTertiary)
                            }
                            .padding(.vertical, 60)
                        } else {
                            ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                                if index > 0 {
                                    Divider().padding(.leading, 76)
                                }
                                NavigationLink(destination: GroupDetailView(group: group)) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.3.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(SplitEZTheme.primary)
                                            .frame(width: 44, height: 44)
                                            .background(SplitEZTheme.primary.opacity(0.1))
                                            .clipShape(Circle())
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(group.name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(SplitEZTheme.textPrimary)
                                            Text("\(group.memberCount ?? 0) people · Group")
                                                .font(.caption)
                                                .foregroundColor(SplitEZTheme.textSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(SplitEZTheme.textTertiary)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                            }
                        }

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
        .sheet(isPresented: $showCreate) {
            CreateGroupView { await loadGroups() }
        }
        .task { await loadGroups() }
    }

    private func loadGroups() async {
        isLoading = true
        groups = (try? await api.get("/groups")) ?? []
        isLoading = false
    }
}

struct GroupDetailView: View {
    let group: ExpenseGroup
    @State private var expenses: [Expense] = []
    @State private var balances: [Balance] = []
    @State private var simplifyDebts = true
    @Environment(\.dismiss) var dismiss
    private let api = APIClient.shared

    private var memberCount: Int { group.memberCount ?? group.members?.count ?? 0 }
    private var createdDate: String {
        let prefix = String(group.createdAt.prefix(10))
        if let date = ISO8601DateFormatter().date(from: group.createdAt) {
            let fmt = DateFormatter()
            fmt.dateFormat = "dd MMM yyyy"
            return fmt.string(from: date)
        }
        return prefix
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    groupHeader
                    VStack(spacing: 0) {
                        membersRow
                            .padding(.top, 20)

                        sectionLabel("GROUP SETTINGS")

                        settingsRowWithValue(label: "Categories", value: "6 in use")
                        rowDivider
                        settingsRowWithValue(label: "Default split", value: "Evenly")
                        rowDivider

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Group buy")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(SplitEZTheme.textPrimary)
                                Text("Curated rates for this group")
                                    .font(.caption)
                                    .foregroundColor(SplitEZTheme.textTertiary)
                            }
                            Spacer()
                            Text("4 offers")
                                .font(.caption.weight(.medium))
                                .foregroundColor(SplitEZTheme.positive)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(SplitEZTheme.positive.opacity(0.1))
                                )
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        rowDivider

                        HStack {
                            Text("Simplify debts")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(SplitEZTheme.textPrimary)
                            Spacer()
                            Toggle("", isOn: $simplifyDebts)
                                .labelsHidden()
                                .tint(SplitEZTheme.primary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)

                        sectionLabel("MANAGE")

                        manageRow(icon: "doc.on.doc", label: "Duplicate group", subtitle: "Copies members, categories, split rules")
                        rowDivider
                        manageRow(icon: "archivebox", label: "Archive group", subtitle: "Hidden from Home, ledger kept")
                        rowDivider

                        Button {
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16))
                                    .foregroundColor(SplitEZTheme.negative)
                                Text("Delete group")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(SplitEZTheme.negative)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                        }

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
        .task {
            expenses = (try? await api.get("/expenses", query: ["groupId": group.id])) ?? []
            balances = (try? await api.get("/balances", query: ["groupId": group.id])) ?? []
        }
    }

    private var groupHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "camera")
                            .font(.system(size: 12, weight: .medium))
                        Text("Change banner")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.2)))
                }
            }

            Text("GROUP MANAGER")
                .font(.caption.weight(.semibold))
                .foregroundColor(Color.white.opacity(0.7))
                .tracking(0.5)

            Text(group.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("\(memberCount) members · created \(createdDate)")
                .font(.caption)
                .foregroundColor(Color.white.opacity(0.6))

            HStack(spacing: 12) {
                Button(action: {}) {
                    Text("Invite member")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(SplitEZTheme.primary)
                        )
                }
                Button(action: {}) {
                    Text("Share sheet")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(SplitEZTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color(.systemBackground))
                        )
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(
            LinearGradient(
                colors: [SplitEZTheme.darkBg, SplitEZTheme.primary.opacity(0.7), Color.teal.opacity(0.5)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    private var membersRow: some View {
        NavigationLink(destination: EmptyView()) {
            HStack(spacing: 8) {
                ZStack {
                    ForEach(Array((group.members ?? []).prefix(3).enumerated()), id: \.element.id) { index, member in
                        AvatarView(user: member, size: 32)
                            .offset(x: CGFloat(index) * 20)
                    }
                }
                .frame(width: CGFloat(min((group.members ?? []).count, 3)) * 20 + 12, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(memberCount) members")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(SplitEZTheme.textPrimary)
                    Text("You are the owner")
                        .font(.caption)
                        .foregroundColor(SplitEZTheme.textTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(SplitEZTheme.textTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
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

    private func settingsRowWithValue(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundColor(SplitEZTheme.textPrimary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(SplitEZTheme.primary)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(SplitEZTheme.textTertiary)
                .padding(.leading, 2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func manageRow(icon: String, label: String, subtitle: String) -> some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(SplitEZTheme.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(SplitEZTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(SplitEZTheme.textTertiary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private var rowDivider: some View {
        Divider().padding(.leading, 20)
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
                            let _: ExpenseGroup? = try? await api.post("/groups", body: CreateGroupRequest(
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

// MARK: - Balance Row

struct BalanceRow: View {
    let balance: Balance

    var body: some View {
        HStack {
            if let user = balance.user {
                AvatarView(user: user, size: 36)
            }
            Text(balance.user?.displayName ?? "Unknown")
                .font(.subheadline)
            Spacer()
            if balance.amount == 0 {
                Text("Settled")
                    .font(.caption.weight(.medium))
                    .foregroundColor(SplitEZTheme.positive)
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(balance.amount > 0 ? "owes you" : "you owe")
                        .font(.caption)
                        .foregroundColor(SplitEZTheme.textSecondary)
                    Text(formatAmount(abs(balance.amount)))
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(balance.amount > 0 ? SplitEZTheme.positive : SplitEZTheme.negative)
                }
            }
        }
    }
}
