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

                SettingsView()
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
        HStack {
            tabButton(icon: "house.fill", label: "Home", tag: 0)
            tabButton(icon: "person.2", label: "Friends", tag: 1)

            // Center "Add" button
            Button {
                showAddSheet = true
            } label: {
                ZStack {
                    Circle()
                        .fill(SplitEZTheme.primary)
                        .frame(width: 52, height: 52)
                        .shadow(color: SplitEZTheme.primary.opacity(0.3), radius: 8, y: 4)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -12)

            tabButton(icon: "arrow.triangle.branch", label: "Activity", tag: 3)
            tabButton(icon: "ellipsis", label: "More", tag: 4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(icon: String, label: String, tag: Int) -> some View {
        Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(selectedTab == tag ? SplitEZTheme.primary : SplitEZTheme.muted)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Friends Tab

struct FriendsTabView: View {
    @State private var friends: [Friend] = []
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
                // Background: dark top, white bottom
                VStack(spacing: 0) {
                    SplitEZTheme.darkBg.frame(height: 160)
                    Color(.systemBackground)
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        friendsHeader

                        // Content card
                        VStack(spacing: 0) {
                            // All friends
                            HStack {
                                Text("All friends")
                                    .font(.headline)
                                Text("· \(friends.count)")
                                    .font(.headline)
                                    .foregroundColor(SplitEZTheme.textSecondary)
                                Spacer()
                                Button {
                                    // Sort action
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
                            .padding(.top, 20)
                            .padding(.bottom, 12)

                            if filteredFriends.isEmpty {
                                Text(searchText.isEmpty ? "No friends added yet" : "No results")
                                    .font(.subheadline)
                                    .foregroundColor(SplitEZTheme.textTertiary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 20)
                            } else {
                                ForEach(filteredFriends) { friend in
                                    FriendListRow(
                                        friend: friend,
                                        balance: balanceFor(friend.id)
                                    )
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

    // MARK: – Friends Header

    private var friendsHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top bar: title + icons
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

            // Search bar
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

    // MARK: – Load Data

    private func loadData() async {
        isLoading = true
        async let f: [Friend] = (try? api.get("/people")) ?? []
        async let b: [Balance] = (try? api.get("/balances")) ?? []
        friends = await f
        balances = await b
        isLoading = false
    }
}

// MARK: - Friend List Row

struct FriendListRow: View {
    let friend: Friend
    var balance: Int = 0

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
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
                if let phone = friend.phone, !phone.isEmpty {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(SplitEZTheme.textSecondary)
                }
            }

            Spacer()

            if balance == 0 {
                Text("Settled")
                    .font(.caption.weight(.medium))
                    .foregroundColor(SplitEZTheme.positive)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .stroke(SplitEZTheme.positive.opacity(0.4), lineWidth: 1)
                    )
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

    /// Convert Friend → UserSummary for AvatarView
    private var friendAsUser: UserSummary? {
        guard let data = try? JSONEncoder().encode(friend),
              let user = try? JSONDecoder().decode(UserSummary.self, from: data)
        else { return nil }
        return user
    }
}

// MARK: - Activity Tab (placeholder)

struct ActivityTabView: View {
    @State private var activities: [Activity] = []
    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            List {
                if activities.isEmpty {
                    Text("No recent activity")
                        .foregroundColor(SplitEZTheme.textSecondary)
                } else {
                    ForEach(activities) { activity in
                        ActivityRow(activity: activity)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Activity")
            .task {
                let feed: PaginatedResponse<Activity> = (try? await api.get("/activity/feed", query: ["limit": "50"])) ?? PaginatedResponse(items: [], nextCursor: nil)
                activities = feed.items
            }
        }
    }
}

// MARK: - Add Expense Sheet (placeholder)

struct AddExpenseSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Text("Add Expense")
                .font(.title2)
                .foregroundColor(SplitEZTheme.textSecondary)
                .navigationTitle("Add Expense")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}

// MARK: - Activity Row (moved here for shared use)

struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 12) {
            if let user = activity.user {
                AvatarView(user: user, size: 36)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(activityDescription)
                    .font(.subheadline)
                Text(activity.createdAt.prefix(10))
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var activityDescription: String {
        let name = activity.user?.firstName ?? "Someone"
        switch activity.type {
        case "EXPENSE_CREATED": return "\(name) added an expense"
        case "SETTLEMENT_COMPLETED": return "\(name) settled up"
        case "GROUP_CREATED": return "\(name) created a group"
        case "TRIP_CREATED": return "\(name) created a trip"
        case "GROUP_MEMBER_ADDED": return "\(name) joined a group"
        case "TRIP_MEMBER_ADDED": return "\(name) joined a trip"
        default: return "\(name) did something"
        }
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
