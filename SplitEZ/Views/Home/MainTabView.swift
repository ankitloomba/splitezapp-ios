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

// MARK: - Friends Tab (placeholder, wraps Groups for now)

struct FriendsTabView: View {
    var body: some View {
        NavigationStack {
            GroupsListView()
                .navigationTitle("Friends")
        }
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
