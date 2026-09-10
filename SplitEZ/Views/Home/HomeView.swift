import SwiftUI

struct HomeView: View {
    @EnvironmentObject var auth: AuthService
    @State private var balances: [Balance] = []
    @State private var recentActivity: [Activity] = []
    @State private var banners: [PromotionalBanner] = []
    @State private var dashboardElements: [DashboardElement] = []
    @State private var isLoading = true

    private let api = APIClient.shared

    @State private var activeFilter = "All"
    private let filters = ["All", "Owed", "You owe", "Settled"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Dark header with balance
                    ZStack {
                        SplitEZTheme.darkBg.ignoresSafeArea(edges: .top)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                // Logo
                                HStack(spacing: 6) {
                                    Image(systemName: "circle.lefthalf.filled")
                                        .font(.title3)
                                        .foregroundColor(SplitEZTheme.primaryLight)
                                    Text("Split")
                                        .font(.system(size: 18, weight: .heavy))
                                        .foregroundColor(.white)
                                    + Text("EZ")
                                        .font(.system(size: 18, weight: .heavy))
                                        .foregroundColor(SplitEZTheme.primaryLight)
                                }
                                Spacer()
                                HStack(spacing: 14) {
                                    NavigationLink(destination: NotificationsListView()) {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(SplitEZTheme.primaryLight)
                                    }
                                    NavigationLink(destination: NotificationsListView()) {
                                        Image(systemName: "gearshape")
                                            .foregroundColor(SplitEZTheme.primaryLight)
                                    }
                                }
                            }
                            .padding(.bottom, 16)

                            Text("Overall, you are owed")
                                .font(.caption)
                                .foregroundColor(SplitEZTheme.muted)

                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(totalOwed)
                                    .font(.system(size: 36, weight: .heavy))
                                    .foregroundColor(SplitEZTheme.positive)
                                    .monospacedDigit()
                                Text("INR ▾")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(SplitEZTheme.muted)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }

                    // White card area
                    VStack(spacing: 0) {
                        // Filter pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 7) {
                                ForEach(filters, id: \.self) { filter in
                                    Text(filter)
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 13)
                                        .padding(.vertical, 7)
                                        .background(
                                            Capsule().fill(
                                                filter == activeFilter
                                                    ? SplitEZTheme.primary
                                                    : SplitEZTheme.pillInactive
                                            )
                                        )
                                        .foregroundColor(
                                            filter == activeFilter ? .white : SplitEZTheme.textSecondary
                                        )
                                        .onTapGesture { activeFilter = filter }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                        }

                        // Dashboard Elements
                        ForEach(dashboardElements) { element in
                            DashboardElementCard(element: element)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 8)
                        }

                        // Banners
                        if !banners.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(banners) { banner in
                                        BannerCard(banner: banner)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.bottom, 12)
                        }

                        // Ad banner
                        AdBannerSlot(placementName: "home_banner")

                        // Groups & trips header
                        HStack {
                            Text("Groups & trips")
                                .font(.subheadline.weight(.bold))
                            Spacer()
                            Text("See all")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(SplitEZTheme.primary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)

                        // Balances
                        if balances.isEmpty {
                            Text("No outstanding balances")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(20)
                        } else {
                            ForEach(balances, id: \.userId) { balance in
                                BalanceRow(balance: balance)
                                Divider().padding(.leading, 70)
                            }
                        }

                        // Recent activity
                        HStack {
                            Text("Recent Activity")
                                .font(.subheadline.weight(.bold))
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                        if recentActivity.isEmpty {
                            Text("No recent activity")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                        } else {
                            ForEach(recentActivity) { activity in
                                ActivityRow(activity: activity)
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .offset(y: -20)
                }
            }
            .background(SplitEZTheme.darkBg)
            .navigationBarHidden(true)
            .refreshable { await loadData() }
            .task { await loadData() }
        }
    }

    private var totalOwed: String {
        let total = balances.filter { $0.amount > 0 }.reduce(0.0) { $0 + $1.amount }
        return formatAmount(total)
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
