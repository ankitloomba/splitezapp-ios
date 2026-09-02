import SwiftUI

struct HomeView: View {
    @EnvironmentObject var auth: AuthService
    @State private var balances: [Balance] = []
    @State private var recentActivity: [Activity] = []
    @State private var banners: [PromotionalBanner] = []
    @State private var dashboardElements: [DashboardElement] = []
    @State private var isLoading = true

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting
                    if let user = auth.currentUser {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Hi, \(user.firstName)!")
                                    .font(.title2.bold())
                                Text("Here's your summary")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            NavigationLink(destination: NotificationsListView()) {
                                Image(systemName: "bell.fill")
                                    .font(.title3)
                                    .foregroundColor(SplitEZTheme.primary)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Dashboard Elements
                    ForEach(dashboardElements) { element in
                        DashboardElementCard(element: element)
                            .padding(.horizontal)
                    }

                    // Banners
                    if !banners.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(banners) { banner in
                                    BannerCard(banner: banner)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Ad banner
                    AdBannerSlot(placementName: "home_banner")

                    // Balances summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Balances")
                            .font(.headline)
                            .padding(.horizontal)

                        if balances.isEmpty {
                            Text("No outstanding balances")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        } else {
                            ForEach(balances, id: \.userId) { balance in
                                BalanceRow(balance: balance)
                            }
                        }
                    }

                    // Recent activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.headline)
                            .padding(.horizontal)

                        if recentActivity.isEmpty {
                            Text("No recent activity")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        } else {
                            ForEach(recentActivity) { activity in
                                ActivityRow(activity: activity)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("SplitEZ")
            .refreshable { await loadData() }
            .task { await loadData() }
        }
    }

    private func loadData() async {
        isLoading = true
        async let b: [Balance] = (try? api.get("/balances")) ?? []
        async let a: PaginatedResponse<Activity> = (try? api.get("/activity/feed", query: ["limit": "10"])) ?? PaginatedResponse(items: [], nextCursor: nil)
        async let p: [PromotionalBanner] = (try? api.get("/promos", query: ["screen": "home"])) ?? []
        async let d: [DashboardElement] = (try? api.get("/dashboard/elements", query: ["screen": "home"])) ?? []
        balances = await b
        recentActivity = await a.items
        banners = await p
        dashboardElements = await d
        isLoading = false
        // Load ad placements for this screen
        await AdManager.shared.loadPlacements(screen: "home")
    }
}

struct BannerCard: View {
    let banner: PromotionalBanner

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(banner.title)
                .font(.headline)
                .foregroundColor(.white)
            if let subtitle = banner.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            if let cta = banner.cta {
                Text(cta)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.top, 4)
            }
        }
        .padding()
        .frame(width: 260, alignment: .leading)
        .background(
            LinearGradient(
                colors: [SplitEZTheme.primary, SplitEZTheme.accent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}

struct DashboardElementCard: View {
    let element: DashboardElement

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = element.title {
                Text(title)
                    .font(element.type == "greeting" ? .title2.bold() : .headline)
            }
            if let subtitle = element.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if let body = element.body {
                Text(body)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if let cta = element.cta {
                Text(cta)
                    .font(.subheadline.bold())
                    .foregroundColor(SplitEZTheme.primary)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
    }

    private var backgroundColor: Color {
        if let config = element.config,
           let bgValue = config["backgroundColor"]?.value as? String {
            return Color(hex: bgValue)
        }
        switch element.type {
        case "announcement": return SplitEZTheme.primary.opacity(0.1)
        case "tip": return Color.yellow.opacity(0.1)
        case "spotlight": return SplitEZTheme.accent.opacity(0.1)
        default: return SplitEZTheme.secondaryBackground
        }
    }
}

struct BalanceRow: View {
    let balance: Balance

    var body: some View {
        HStack {
            if let user = balance.user {
                AvatarView(user: user, size: 36)
                Text(user.displayName)
            }
            Spacer()
            Text(formatAmount(abs(balance.amount)))
                .font(.subheadline.bold())
                .foregroundColor(balance.amount >= 0 ? SplitEZTheme.positive : SplitEZTheme.negative)
            Text(balance.amount >= 0 ? "owes you" : "you owe")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack {
            if let user = activity.user {
                AvatarView(user: user, size: 32)
            }
            VStack(alignment: .leading) {
                Text(activityDescription)
                    .font(.subheadline)
                Text(activity.createdAt.prefix(10))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
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
