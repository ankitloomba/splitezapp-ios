import SwiftUI

struct GroupsListView: View {
    @State private var groups: [ExpenseGroup] = []
    @State private var isLoading = true
    @State private var showCreate = false
    @State private var activeFilter = "All groups"
    @State private var showSearch = false
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss
    private let api = APIClient.shared

    private let filters = ["All groups", "Active", "Archived"]

    private var filteredGroups: [ExpenseGroup] {
        var result = groups
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    private static let groupStyles: [(icon: String, color: Color)] = [
        ("house", Color(hex: "6366F1")),
        ("clock", Color(hex: "F59E0B")),
        ("person.3", Color(hex: "16A34A")),
        ("fork.knife", Color(hex: "F87171")),
        ("suitcase", Color(hex: "8B5CF6")),
        ("cart", Color(hex: "0EA5E9")),
    ]

    private func styleForGroup(_ index: Int) -> (icon: String, color: Color) {
        Self.groupStyles[index % Self.groupStyles.count]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Dark header — pinned, not in scroll
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Groups")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button { } label: {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                    Button { showCreate = true } label: {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    }
                    Button { withAnimation { showSearch.toggle(); if !showSearch { searchText = "" } } } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                    Menu {
                        Button { } label: { Label("Security", systemImage: "lock.shield") }
                        Button { } label: { Label("Export data", systemImage: "square.and.arrow.up") }
                        Button { } label: { Label("Import data", systemImage: "square.and.arrow.down") }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                    }
                }

                // Filter pills
                HStack(spacing: 8) {
                    ForEach(filters, id: \.self) { filter in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { activeFilter = filter }
                        } label: {
                            Text(filter)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(activeFilter == filter ? .white : Color.white.opacity(0.7))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(activeFilter == filter
                                              ? Color.white.opacity(0.2)
                                              : Color.clear)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(activeFilter == filter ? 0 : 0.3), lineWidth: 1)
                                )
                        }
                    }
                }

                if showSearch {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundColor(SplitEZTheme.textTertiary)
                        TextField("Search groups", text: $searchText)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(SplitEZTheme.textTertiary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.1))
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SplitEZTheme.darkBg.ignoresSafeArea(edges: .top))

            // Content — scrollable, with rounded top corners over dark bg
            ScrollView {
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
                        ForEach(Array(filteredGroups.enumerated()), id: \.element.id) { index, group in
                            if index > 0 {
                                Divider().padding(.leading, 76)
                            }
                            let style = styleForGroup(index)
                            NavigationLink(destination: GroupDetailView(group: group)) {
                                HStack(spacing: 12) {
                                    Image(systemName: style.icon)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(style.color)
                                        .frame(width: 48, height: 48)
                                        .background(style.color.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(group.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(SplitEZTheme.textPrimary)
                                        Text("\(group.memberCount ?? 0) members · unsettled")
                                            .font(.caption)
                                            .foregroundColor(SplitEZTheme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(SplitEZTheme.textTertiary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer().frame(height: 80)
                }
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 20
                    )
                )
            }
            .background(SplitEZTheme.darkBg)
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
        if groups.isEmpty { groups = SampleData.groups }
        isLoading = false
    }
}

struct GroupDetailView: View {
    let group: ExpenseGroup
    @State private var expenses: [Expense] = []
    @State private var balances: [Balance] = []
    @State private var simplifyDebts = true
    @State private var showDeleteConfirm = false
    @State private var showArchiveConfirm = false
    @State private var showShareSheet = false
    @State private var showInviteShare = false
    @State private var isDeleting = false
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

                        Button {
                            Task { await duplicateGroup() }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 16))
                                    .foregroundColor(SplitEZTheme.textSecondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Duplicate group")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(SplitEZTheme.textPrimary)
                                    Text("Copies members, categories, split rules")
                                        .font(.caption)
                                        .foregroundColor(SplitEZTheme.textTertiary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        rowDivider
                        Button { showArchiveConfirm = true } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "archivebox")
                                    .font(.system(size: 16))
                                    .foregroundColor(SplitEZTheme.textSecondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Archive group")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(SplitEZTheme.textPrimary)
                                    Text("Hidden from Home, ledger kept")
                                        .font(.caption)
                                        .foregroundColor(SplitEZTheme.textTertiary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        rowDivider

                        Button { showDeleteConfirm = true } label: {
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
            if expenses.isEmpty {
                expenses = SampleData.recentExpenses.filter { $0.groupId == group.id }
            }
            if balances.isEmpty {
                let memberIds = group.members?.map(\.id) ?? []
                balances = SampleData.balances.filter { memberIds.contains($0.userId) }
            }
        }
        .alert("Delete Group", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await deleteGroup() }
            }
        } message: {
            Text("This will permanently delete \"\(group.name)\" and all its expenses. This cannot be undone.")
        }
        .alert("Archive Group", isPresented: $showArchiveConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Archive") {
                Task { await archiveGroup() }
            }
        } message: {
            Text("This will hide \"\(group.name)\" from your Home screen. The ledger and history are kept.")
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheetView(items: [generateShareText()])
        }
        .sheet(isPresented: $showInviteShare) {
            ShareSheetView(items: ["Join my group \"\(group.name)\" on SplitEZ! Download the app and use invite code: \(group.id)"])
        }
    }

    private func deleteGroup() async {
        isDeleting = true
        let _: AnyCodable? = try? await api.post("/groups/\(group.id)/delete")
        isDeleting = false
        dismiss()
    }

    private func archiveGroup() async {
        let _: AnyCodable? = try? await api.put("/groups/\(group.id)", body: ["status": "archived"])
        dismiss()
    }

    private func duplicateGroup() async {
        let _: ExpenseGroup? = try? await api.post("/groups/\(group.id)/duplicate")
        dismiss()
    }

    private func generateShareText() -> String {
        var text = "\(group.name)\n"
        text += "\(memberCount) members\n\n"
        if !balances.isEmpty {
            text += "Balances:\n"
            for b in balances {
                let name = b.user?.displayName ?? "Unknown"
                let amt = formatAmount(abs(b.amount))
                text += b.amount > 0 ? "  \(name) owes you \(amt)\n" : "  You owe \(name) \(amt)\n"
            }
        }
        text += "\nShared via SplitEZ"
        return text
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
                Button { showInviteShare = true } label: {
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
                Button { showShareSheet = true } label: {
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

    private var rowDivider: some View {
        Divider().padding(.leading, 20)
    }
}

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
