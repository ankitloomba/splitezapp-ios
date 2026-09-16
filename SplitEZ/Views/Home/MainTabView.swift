import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showAddSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)

                FriendsTabView()
                    .tag(1)

                // Placeholder for the center Add button
                Color.clear
                    .tag(2)

                ActivityTabView()
                    .tag(3)

                MoreTabView()
                    .tag(4)
            }

            // Persistent ad banner + custom tab bar
            VStack(spacing: 0) {
                SponsoredBannerView()
                customTabBar
            }
        }
        .onAppear {
            // Hide the default tab bar so only our custom one shows
            UITabBar.appearance().isHidden = true
        }
        .sheet(isPresented: $showAddSheet) {
            AddExpenseSheet()
        }
        .onChange(of: selectedTab) { _, tab in
            if tab == 2 {
                // Reset to previous tab, show add sheet instead
                selectedTab = 0
                showAddSheet = true
            }
            let screens = ["home", "friends", "add", "activity", "settings"]
            if tab < screens.count && tab != 2 {
                Task { await AnalyticsTracker.shared.trackScreen(screens[tab]) }
            }
        }
        .task {
            await AnalyticsTracker.shared.startSession()
            await AnalyticsTracker.shared.trackScreen("home")
        }
    }

    // MARK: – Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(activeIcon: "house.fill", inactiveIcon: "house", label: "Home", tag: 0)
            tabButton(activeIcon: "person.2.fill", inactiveIcon: "person.2", label: "Friends", tag: 1)

            // Center "Add" button
            Button {
                showAddSheet = true
            } label: {
                ZStack {
                    Circle()
                        .fill(SplitEZTheme.primary)
                        .frame(width: 52, height: 52)
                        .shadow(color: SplitEZTheme.primary.opacity(0.25), radius: 8, y: 4)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .offset(y: -14)

            tabButton(activeIcon: "arrow.triangle.branch", inactiveIcon: "arrow.triangle.branch", label: "Activity", tag: 3)
            tabButton(activeIcon: "ellipsis.circle.fill", inactiveIcon: "ellipsis", label: "More", tag: 4)
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(
            Rectangle()
                .fill(SplitEZTheme.darkBg)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(activeIcon: String, inactiveIcon: String, label: String, tag: Int) -> some View {
        let isActive = selectedTab == tag
        return Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 4) {
                Image(systemName: isActive ? activeIcon : inactiveIcon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isActive ? .white : Color.white.opacity(0.45))
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Friends Tab

struct FriendsTabView: View {
    @State private var friends: [Friend] = []
    @State private var pendingRequests: [FriendRequest] = []
    @State private var balances: [Balance] = []
    @State private var searchText = ""
    @State private var isLoading = true
    private let api = APIClient.shared

    private var filteredFriends: [Friend] {
        if searchText.isEmpty { return friends }
        return friends.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func balanceFor(_ friendId: String) -> Int {
        balances.first(where: { $0.userId == friendId })?.amount ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    SplitEZTheme.darkBg.frame(height: 160)
                    Color(.systemBackground)
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        friendsHeader

                        VStack(spacing: 0) {
                            // Pending requests
                            if !pendingRequests.isEmpty {
                                pendingRequestsSection
                            }

                            // All friends header
                            HStack {
                                Text("All friends")
                                    .font(.headline)
                                Text("· \(friends.count)")
                                    .font(.headline)
                                    .foregroundColor(SplitEZTheme.textSecondary)
                                Spacer()
                                Button {
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "line.3.horizontal.decrease")
                                            .font(.caption)
                                        Text("Sort")
                                            .font(.subheadline.weight(.medium))
                                    }
                                    .foregroundColor(SplitEZTheme.primary)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, pendingRequests.isEmpty ? 20 : 8)
                            .padding(.bottom, 12)

                            if filteredFriends.isEmpty {
                                Text(searchText.isEmpty ? "No friends added yet" : "No results")
                                    .font(.subheadline)
                                    .foregroundColor(SplitEZTheme.textTertiary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 20)
                            } else {
                                ForEach(Array(filteredFriends.enumerated()), id: \.element.id) { index, friend in
                                    if index > 0 {
                                        Divider().padding(.leading, 76)
                                    }
                                    NavigationLink(destination: FriendLedgerView(friend: friend)) {
                                        FriendListRow(
                                            friend: friend,
                                            balance: balanceFor(friend.id)
                                        )
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
            .task { await loadData() }
        }
    }

    // MARK: – Pending Requests

    private var pendingRequestsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Pending requests")
                    .font(.headline)
                Text("\(pendingRequests.count)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(SplitEZTheme.negative))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            ForEach(Array(pendingRequests.enumerated()), id: \.element.id) { index, request in
                if index > 0 {
                    Divider().padding(.leading, 76)
                }
                PendingRequestRow(request: request) {
                    Task { await acceptRequest(request.id) }
                } onReject: {
                    Task { await rejectRequest(request.id) }
                }
            }

            Divider()
                .padding(.top, 8)
                .padding(.bottom, 4)
        }
    }

    // MARK: – Friends Header

    private var friendsHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Friends")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.trailing, 12)
                Button(action: {}) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(SplitEZTheme.textTertiary)
                TextField("Search friends", text: $searchText)
                    .font(.subheadline)
                    .foregroundColor(.white)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
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
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(SplitEZTheme.darkBg)
    }

    // MARK: – Actions

    private func loadData() async {
        isLoading = true
        async let f: [Friend] = (try? api.get("/people")) ?? []
        async let b: [Balance] = (try? api.get("/balances")) ?? []
        async let r: [FriendRequest] = (try? api.get("/friend-requests", query: ["status": "pending"])) ?? []
        friends = await f
        balances = await b
        pendingRequests = await r
        isLoading = false
    }

    private func acceptRequest(_ id: String) async {
        let _: SuccessResponse? = try? await api.put("/friend-requests/\(id)/accept", body: EmptyBody())
        await loadData()
    }

    private func rejectRequest(_ id: String) async {
        let _: SuccessResponse? = try? await api.put("/friend-requests/\(id)/reject", body: EmptyBody())
        await loadData()
    }
}

private struct EmptyBody: Codable {}

// MARK: - Pending Request Row

struct PendingRequestRow: View {
    let request: FriendRequest
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(user: request.fromUser, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(request.fromUser.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(SplitEZTheme.textPrimary)
                if let source = request.source {
                    Text(source)
                        .font(.caption)
                        .foregroundColor(SplitEZTheme.textSecondary)
                }
            }

            Spacer()

            Button(action: onAccept) {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(SplitEZTheme.positive)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(SplitEZTheme.positive.opacity(0.1))
                    )
            }

            Button(action: onReject) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(SplitEZTheme.textTertiary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color(.systemGray5))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

// MARK: - Friend List Row

struct FriendListRow: View {
    let friend: Friend
    var balance: Int = 0

    var body: some View {
        HStack(spacing: 12) {
            if let user = friendAsUser {
                AvatarView(user: user, size: 44)
            } else {
                Circle()
                    .fill(SplitEZTheme.pillInactive)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(friend.firstName.prefix(1).uppercased())
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(SplitEZTheme.textSecondary)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(SplitEZTheme.textPrimary)
                Text(subtitleText)
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.textSecondary)
            }

            Spacer()

            if balance == 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("settled up")
                        .font(.caption)
                        .foregroundColor(SplitEZTheme.textSecondary)
                    Text("₹0")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(SplitEZTheme.positive)
                }
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(balance > 0 ? "owes you" : "you owe")
                        .font(.caption)
                        .foregroundColor(SplitEZTheme.textSecondary)
                    Text(formatAmount(abs(balance)))
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(balance > 0 ? SplitEZTheme.positive : SplitEZTheme.negative)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var subtitleText: String {
        var parts: [String] = []
        if let count = friend.groupCount, count > 0 {
            parts.append("\(count) group\(count == 1 ? "" : "s")")
        }
        if let lastActive = friend.lastActiveAt {
            parts.append("last active \(relativeTime(lastActive))")
        } else if let phone = friend.phone, !phone.isEmpty {
            parts.append(phone)
        }
        return parts.isEmpty ? (friend.phone ?? "") : parts.joined(separator: " · ")
    }

    private func relativeTime(_ iso: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: iso) else { return "" }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days == 0 { return "today" }
        if days == 1 { return "1d ago" }
        return "\(days)d ago"
    }

    private var friendAsUser: UserSummary? {
        guard let data = try? JSONEncoder().encode(friend),
              let user = try? JSONDecoder().decode(UserSummary.self, from: data)
        else { return nil }
        return user
    }
}

// MARK: - Activity Tab

struct ActivityTabView: View {
    @State private var activities: [Activity] = []
    @State private var activeSort = "Date"
    @State private var searchText = ""
    private let api = APIClient.shared
    private let sortOptions = ["Date", "Name", "Type", "Amount"]

    /// Group activities by day label (TODAY, YESTERDAY, or date)
    private var groupedActivities: [(String, [Activity])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        var groups: [String: [Activity]] = [:]
        var order: [String] = []

        for activity in activities {
            let label: String
            if let date = parseDate(activity.createdAt) {
                let day = calendar.startOfDay(for: date)
                if day == today { label = "TODAY" }
                else if day == yesterday { label = "YESTERDAY" }
                else {
                    let fmt = DateFormatter()
                    fmt.dateFormat = "MMM d, yyyy"
                    label = fmt.string(from: date).uppercased()
                }
            } else {
                label = "OLDER"
            }
            if groups[label] == nil { order.append(label) }
            groups[label, default: []].append(activity)
        }
        return order.map { ($0, groups[$0]!) }
    }

    private func parseDate(_ str: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return iso.date(from: str) ?? ISO8601DateFormatter().date(from: str)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    SplitEZTheme.darkBg.frame(height: 160)
                    Color(.systemBackground)
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        activityHeader

                        // Content card
                        VStack(spacing: 0) {
                            if activities.isEmpty {
                                Text("No recent activity")
                                    .font(.subheadline)
                                    .foregroundColor(SplitEZTheme.textTertiary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 40)
                            } else {
                                ForEach(groupedActivities, id: \.0) { label, items in
                                    // Section header
                                    Text(label)
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(SplitEZTheme.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 20)
                                        .padding(.bottom, 8)

                                    ForEach(items) { activity in
                                        ActivityRow(activity: activity)
                                        if activity.id != items.last?.id {
                                            Divider()
                                                .padding(.leading, 72)
                                                .padding(.trailing, 20)
                                        }
                                    }
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
            .task {
                let feed: PaginatedResponse<Activity> = (try? await api.get("/activity/feed", query: ["limit": "50"])) ?? PaginatedResponse(items: [], nextCursor: nil)
                activities = feed.items
            }
        }
    }

    // MARK: – Activity Header

    private var activityHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title + icons
            HStack {
                Text("Activity")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.trailing, 12)
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
            }

            // Sort pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sortOptions, id: \.self) { option in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { activeSort = option }
                        } label: {
                            HStack(spacing: 4) {
                                Text(option)
                                    .font(.subheadline.weight(.medium))
                                if activeSort == option {
                                    Image(systemName: "arrow.down")
                                        .font(.system(size: 10, weight: .bold))
                                }
                            }
                            .foregroundColor(activeSort == option ? .white : Color.white.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(activeSort == option
                                          ? SplitEZTheme.primary
                                          : Color.white.opacity(0.12))
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(SplitEZTheme.darkBg)
    }
}

// MARK: - Add Expense Sheet

struct AddExpenseSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var amountText = ""
    @State private var description = ""
    @State private var selectedCurrency = "INR"
    @State private var selectedCategory: ExpenseCategory = .food
    @State private var showCategoryPicker = false
    @State private var splitMethod = "EQUAL"
    @State private var note = ""
    @State private var expenseDate = Date()
    @State private var showDatePicker = false
    @State private var showNotesField = false
    @State private var isLoading = false
    @State private var error: String?
    @State private var paidByIndex = 0
    @State private var showCurrencyPicker = false

    private let api = APIClient.shared

    private let currencies = ["INR", "USD", "EUR", "GBP"]
    private let currencySymbols: [String: String] = ["INR": "₹", "USD": "$", "EUR": "€", "GBP": "£"]

    private var sampleMembers: [(initial: String, name: String, color: Color)] {
        [
            ("SK", "You", SplitEZTheme.primary),
            ("R", "Rahul", Color.purple),
            ("A", "Anita", Color(hex: "6366F1")),
            ("P", "Priya", Color(hex: "6366F1").opacity(0.6)),
        ]
    }

    private var perPersonAmount: String {
        guard let amount = Double(amountText), amount > 0 else { return "₹0" }
        let share = amount / Double(sampleMembers.count)
        return "\(currencySymbols[selectedCurrency] ?? "₹")\(Int(share).formatted())"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Dark header
                Color.clear.frame(height: 0)
                    .background(SplitEZTheme.darkBg.ignoresSafeArea(edges: .top))
                VStack(spacing: 8) {
                    // Nav bar
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Text("New expense")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Color.clear.frame(width: 24)
                    }
                    .padding(.horizontal, 20)

                    // Amount input
                    HStack(alignment: .center, spacing: 4) {
                        Text(currencySymbols[selectedCurrency] ?? "₹")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.5))

                        TextField("0", text: $amountText)
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.white)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: true, vertical: false)

                        Button {
                            showCurrencyPicker = true
                        } label: {
                            HStack(spacing: 4) {
                                Text(selectedCurrency)
                                    .font(.caption.weight(.semibold))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.white.opacity(0.15)))
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
                .background(SplitEZTheme.darkBg)

                // Content – white card with rounded top
                ScrollView {
                    VStack(spacing: 16) {
                        // Category + Description
                        HStack(spacing: 12) {
                            Button { showCategoryPicker = true } label: {
                                Image(systemName: selectedCategory.icon)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(selectedCategory.color)
                                    .frame(width: 44, height: 44)
                                    .background(selectedCategory.color.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }

                            TextField("Dinner at Olive Garden", text: $description)
                                .font(.subheadline)
                                .foregroundColor(SplitEZTheme.textPrimary)
                                .onChange(of: description) { _, newValue in
                                    let detected = ExpenseCategory.detect(from: newValue)
                                    if detected != .other || selectedCategory == .other {
                                        selectedCategory = detected
                                    }
                                }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )

                        // Paid By + Split
                        HStack(spacing: 16) {
                            // Paid By
                            VStack(alignment: .leading, spacing: 8) {
                                Text("PAID BY")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundColor(SplitEZTheme.textTertiary)
                                    .tracking(0.5)

                                Button(action: {}) {
                                    HStack(spacing: 8) {
                                        miniAvatar(initial: sampleMembers[paidByIndex].initial, color: sampleMembers[paidByIndex].color)
                                        Text(sampleMembers[paidByIndex].name)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(SplitEZTheme.textPrimary)
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(SplitEZTheme.textTertiary)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // Split
                            VStack(alignment: .leading, spacing: 8) {
                                Text("SPLIT")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundColor(SplitEZTheme.textTertiary)
                                    .tracking(0.5)

                                Button(action: {}) {
                                    HStack(spacing: -6) {
                                        ForEach(sampleMembers.prefix(2), id: \.name) { member in
                                            miniAvatar(initial: member.initial, color: member.color)
                                        }
                                        if sampleMembers.count > 2 {
                                            Text("+\(sampleMembers.count - 2)")
                                                .font(.caption2.weight(.bold))
                                                .foregroundColor(.white)
                                                .frame(width: 24, height: 24)
                                                .background(Circle().fill(SplitEZTheme.primary.opacity(0.5)))
                                                .padding(.leading, 2)
                                        }
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(SplitEZTheme.textTertiary)
                                            .padding(.leading, 8)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                                }
                            }
                        }

                        // Split method + Group
                        HStack(spacing: 12) {
                            Button {
                                splitMethod = "EQUAL"
                            } label: {
                                HStack(spacing: 6) {
                                    Text("Equally")
                                        .font(.subheadline.weight(.semibold))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundColor(splitMethod == "EQUAL" ? .white : SplitEZTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(splitMethod == "EQUAL" ? SplitEZTheme.primary : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(splitMethod == "EQUAL" ? Color.clear : Color(.systemGray4), lineWidth: 1)
                                )
                            }

                            Button(action: {}) {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.2")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Group")
                                        .font(.subheadline.weight(.medium))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundColor(SplitEZTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                        }

                        // Each person pays
                        VStack(spacing: 0) {
                            Text("EACH PERSON PAYS")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(SplitEZTheme.textTertiary)
                                .tracking(0.5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                .padding(.bottom, 12)

                            ForEach(Array(sampleMembers.enumerated()), id: \.element.name) { index, member in
                                if index > 0 {
                                    Divider().padding(.leading, 52)
                                }
                                HStack(spacing: 10) {
                                    miniAvatar(initial: member.initial, color: member.color)
                                    Text(member.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(SplitEZTheme.textPrimary)
                                    Spacer()
                                    Text(perPersonAmount)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(SplitEZTheme.textPrimary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }

                            Spacer().frame(height: 8)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemGray6))
                        )

                        // Date, Notes, Receipt row
                        HStack(spacing: 0) {
                            Button {
                                showDatePicker.toggle()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 14))
                                    Text(dateLabel)
                                        .font(.subheadline)
                                }
                                .foregroundColor(SplitEZTheme.textSecondary)
                            }

                            Divider().frame(height: 20).padding(.horizontal, 16)

                            Button {
                                showNotesField.toggle()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 14))
                                    Text("Notes")
                                        .font(.subheadline)
                                }
                                .foregroundColor(SplitEZTheme.textSecondary)
                            }

                            Divider().frame(height: 20).padding(.horizontal, 16)

                            Button(action: {}) {
                                HStack(spacing: 6) {
                                    Image(systemName: "camera")
                                        .font(.system(size: 14))
                                    Text("Receipt")
                                        .font(.subheadline)
                                }
                                .foregroundColor(SplitEZTheme.textSecondary)
                            }

                            Spacer()
                        }
                        .padding(.top, 4)

                        if showDatePicker {
                            DatePicker("", selection: $expenseDate, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .tint(SplitEZTheme.primary)
                        }

                        if showNotesField {
                            TextField("Add a note...", text: $note, axis: .vertical)
                                .font(.subheadline)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(.systemGray6))
                                )
                        }

                        if let error {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(SplitEZTheme.negative)
                        }

                        Spacer().frame(height: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
                .background(
                    Color(.systemBackground)
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 24,
                                topTrailingRadius: 24
                            )
                        )
                )
                .offset(y: -16)
            }

            // Save button
            VStack(spacing: 0) {
                Button {
                    Task { await saveExpense() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        Text("Save expense")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(canSave ? SplitEZTheme.primary : SplitEZTheme.primary.opacity(0.4))
                )
                .disabled(!canSave || isLoading)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .background(Color(.systemBackground))
        .confirmationDialog("Select Currency", isPresented: $showCurrencyPicker) {
            ForEach(currencies, id: \.self) { currency in
                Button("\(currencySymbols[currency] ?? "") \(currency)") {
                    selectedCurrency = currency
                }
            }
        }
        .confirmationDialog("Select Category", isPresented: $showCategoryPicker) {
            ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                Button(cat.label) {
                    selectedCategory = cat
                }
            }
        }
    }

    private var dateLabel: String {
        if Calendar.current.isDateInToday(expenseDate) {
            return "Today"
        }
        if Calendar.current.isDateInYesterday(expenseDate) {
            return "Yesterday"
        }
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM"
        return fmt.string(from: expenseDate)
    }

    private var canSave: Bool {
        !description.isEmpty && !amountText.isEmpty && (Double(amountText) ?? 0) > 0
    }

    private func saveExpense() async {
        guard let amountDouble = Double(amountText) else {
            error = "Invalid amount"
            return
        }
        let amount = Int(amountDouble * 100)
        isLoading = true
        error = nil

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"

        let req = CreateExpenseRequest(
            description: description,
            amount: amount,
            currency: selectedCurrency,
            splitMethod: splitMethod,
            category: selectedCategory.label,
            note: note.isEmpty ? nil : note,
            date: dateFmt.string(from: expenseDate),
            participants: []
        )

        do {
            let _: Expense = try await api.post("/expenses", body: req)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func miniAvatar(initial: String, color: Color) -> some View {
        Text(initial)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 28, height: 28)
            .background(Circle().fill(color))
    }
}

// MARK: - Expense Categories

enum ExpenseCategory: String, CaseIterable {
    case food, transport, shopping, stay, entertainment, utilities, health, education, travel, other

    var label: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .stay: return "house.fill"
        case .entertainment: return "film"
        case .utilities: return "bolt.fill"
        case .health: return "heart.fill"
        case .education: return "book.fill"
        case .travel: return "airplane"
        case .other: return "square.grid.2x2"
        }
    }

    var color: Color {
        switch self {
        case .food: return .orange
        case .transport: return Color(hex: "6366F1")
        case .shopping: return .pink
        case .stay: return .green
        case .entertainment: return .purple
        case .utilities: return .yellow
        case .health: return .red
        case .education: return .blue
        case .travel: return .teal
        case .other: return .gray
        }
    }

    var keywords: [String] {
        switch self {
        case .food: return ["dinner", "lunch", "breakfast", "coffee", "restaurant", "pizza", "burger", "snack", "cafe", "meal", "food", "drink", "bar", "pub", "brunch", "bakery", "chai", "tea", "biryani", "dosa", "thali", "swiggy", "zomato"]
        case .transport: return ["uber", "ola", "cab", "taxi", "auto", "bus", "metro", "train", "fuel", "petrol", "diesel", "gas", "parking", "toll", "rickshaw", "rapido"]
        case .shopping: return ["amazon", "flipkart", "myntra", "clothes", "shoes", "electronics", "gadget", "phone", "laptop", "mall", "market", "shop", "buy", "gift"]
        case .stay: return ["hotel", "airbnb", "hostel", "resort", "room", "rent", "stay", "accommodation", "lodge", "oyo"]
        case .entertainment: return ["movie", "cinema", "netflix", "concert", "game", "show", "theatre", "event", "bookmyshow", "party"]
        case .utilities: return ["electricity", "water", "wifi", "internet", "phone bill", "recharge", "gas bill", "maintenance", "broadband"]
        case .health: return ["doctor", "hospital", "medicine", "pharmacy", "gym", "fitness", "yoga", "dental", "medical", "lab test"]
        case .education: return ["book", "course", "tuition", "school", "college", "udemy", "class", "coaching", "stationery"]
        case .travel: return ["flight", "airport", "visa", "passport", "ticket", "booking", "trip", "vacation", "holiday", "tour"]
        case .other: return []
        }
    }

    static func detect(from text: String) -> ExpenseCategory {
        let lower = text.lowercased()
        for category in allCases where category != .other {
            if category.keywords.contains(where: { lower.contains($0) }) {
                return category
            }
        }
        return .food
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 12) {
            // Category icon circle
            Circle()
                .fill(iconBackground)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: iconName)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                // Bold name + action
                Text(activityTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(SplitEZTheme.textPrimary)
                Text(activitySubtitle)
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.textSecondary)
            }

            Spacer()

            // Amount or time
            if let amount = activityAmount {
                Text(amount)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(amountColor)
            } else {
                Text(timeString)
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.textTertiary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: – Icon

    private var iconName: String {
        switch activity.type {
        case "SETTLEMENT_COMPLETED": return "checkmark"
        case "EXPENSE_CREATED": return "fork.knife"
        case "GROUP_CREATED": return "house"
        case "TRIP_CREATED": return "paperplane"
        case "GROUP_MEMBER_ADDED", "TRIP_MEMBER_ADDED": return "person.badge.plus"
        default: return "bell"
        }
    }

    private var iconColor: Color {
        switch activity.type {
        case "SETTLEMENT_COMPLETED": return SplitEZTheme.positive
        case "EXPENSE_CREATED": return Color(red: 0.8, green: 0.6, blue: 0.2)
        case "GROUP_CREATED", "TRIP_CREATED": return SplitEZTheme.primary
        default: return SplitEZTheme.negative
        }
    }

    private var iconBackground: Color {
        iconColor.opacity(0.12)
    }

    // MARK: – Text

    private var activityTitle: AttributedString {
        let name = activity.user?.firstName ?? "Someone"
        var result = AttributedString()
        switch activity.type {
        case "EXPENSE_CREATED":
            var bold = AttributedString(name)
            bold.font = .subheadline.weight(.bold)
            let desc = activity.metadata?["description"]
            let expName = (desc?.value as? String) ?? "an expense"
            result = bold + AttributedString(" added \(expName)")
        case "SETTLEMENT_COMPLETED":
            var bold = AttributedString(name)
            bold.font = .subheadline.weight(.bold)
            result = bold + AttributedString(" paid you back")
        case "GROUP_CREATED":
            var bold = AttributedString("You")
            bold.font = .subheadline.weight(.bold)
            result = bold + AttributedString(" created a group")
        case "TRIP_CREATED":
            var bold = AttributedString("You")
            bold.font = .subheadline.weight(.bold)
            result = bold + AttributedString(" created a trip")
        default:
            var bold = AttributedString(name)
            bold.font = .subheadline.weight(.bold)
            result = bold + AttributedString(" did something")
        }
        return result
    }

    private var activitySubtitle: String {
        let groupName = (activity.metadata?["groupName"]?.value as? String)
            ?? (activity.metadata?["tripName"]?.value as? String)
            ?? ""
        switch activity.type {
        case "SETTLEMENT_COMPLETED":
            return groupName.isEmpty ? "settlement" : "\(groupName) · settlement"
        case "EXPENSE_CREATED":
            let share = activity.metadata?["shareAmount"]?.value
            let shareStr = share != nil ? " · your share \(formatAmount(share as? Int ?? 0))" : ""
            return groupName.isEmpty ? "expense\(shareStr)" : "\(groupName)\(shareStr)"
        default:
            return groupName
        }
    }

    private var activityAmount: String? {
        guard let meta = activity.metadata else { return nil }
        if let amt = meta["amount"]?.value as? Int, amt != 0 {
            let prefix = amt > 0 ? "+ " : "– "
            return "\(prefix)\(formatAmount(abs(amt)))"
        }
        if let share = meta["shareAmount"]?.value as? Int, share != 0 {
            return "– \(formatAmount(abs(share)))"
        }
        return nil
    }

    private var amountColor: Color {
        if let meta = activity.metadata, let amt = meta["amount"]?.value as? Int {
            return amt >= 0 ? SplitEZTheme.positive : SplitEZTheme.negative
        }
        return SplitEZTheme.negative
    }

    private var timeString: String {
        // Extract HH:mm from ISO date
        if activity.createdAt.count >= 16 {
            let idx = activity.createdAt.index(activity.createdAt.startIndex, offsetBy: 11)
            let end = activity.createdAt.index(idx, offsetBy: 5)
            return String(activity.createdAt[idx..<end])
        }
        return ""
    }
}

// MARK: - More Tab

struct MoreTabView: View {
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    SplitEZTheme.darkBg.frame(height: 120)
                    Color(.systemBackground)
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("More")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                        .background(SplitEZTheme.darkBg)

                        // Menu items
                        VStack(spacing: 0) {
                            moreSection(title: "Manage") {
                                moreRow(icon: "rectangle.3.group", iconColor: SplitEZTheme.primary, label: "Groups", destination: AnyView(GroupsListView()))
                                moreRow(icon: "paperplane", iconColor: Color.orange, label: "Trips", destination: AnyView(TripsListView()))
                                moreRow(icon: "creditcard", iconColor: Color.teal, label: "Expenses", destination: AnyView(CreateExpenseView(groupId: nil, tripId: nil, members: [], onCreated: {})))
                            }

                            moreSection(title: "Finances") {
                                moreRow(icon: "chart.pie", iconColor: SplitEZTheme.positive, label: "Finances", destination: AnyView(FinancesView()))
                                moreRow(icon: "square.and.arrow.up", iconColor: Color.blue, label: "Export", destination: AnyView(ExportView()))
                                moreRow(icon: "square.and.arrow.down", iconColor: Color.purple, label: "Import", destination: AnyView(ImportView()))
                            }

                            moreSection(title: "Account") {
                                moreRow(icon: "bell", iconColor: SplitEZTheme.negative, label: "Notifications", destination: AnyView(NotificationsListView()))
                                moreRow(icon: "gearshape", iconColor: SplitEZTheme.muted, label: "Settings", destination: AnyView(SettingsView()))
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
        }
    }

    private func moreSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(SplitEZTheme.textTertiary)
                .textCase(.uppercase)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)

            content()
        }
    }

    private func moreRow(icon: String, iconColor: Color, label: String, destination: AnyView) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(iconColor)
                    )

                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(SplitEZTheme.textPrimary)

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

// MARK: - Sponsored Banner (persistent above tab bar on all screens)

struct SponsoredBannerView: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("AD")
                .font(.caption2.weight(.bold))
                .foregroundColor(SplitEZTheme.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(SplitEZTheme.pillInactive)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Sponsored")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(SplitEZTheme.textPrimary)
                Text("Remove ads · SplitEZ Plus ₹99/mo")
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.textSecondary)
            }
            Spacer()
            Button("Go Plus") {}
                .font(.caption.weight(.semibold))
                .foregroundColor(SplitEZTheme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(SplitEZTheme.primary, lineWidth: 1)
                )
        }
        .padding(14)
        .background(
            Rectangle()
                .fill(SplitEZTheme.secondaryBackground)
                .shadow(color: .black.opacity(0.04), radius: 4, y: -1)
        )
    }
}
