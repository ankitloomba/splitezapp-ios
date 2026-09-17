import SwiftUI

struct HomeView: View {
    @EnvironmentObject var auth: AuthService
    @State private var groups: [ExpenseGroup] = []
    @State private var trips: [Trip] = []
    @State private var balances: [Balance] = []
    @State private var banners: [PromotionalBanner] = []
    @State private var dashboardElements: [DashboardElement] = []
    @State private var isLoading = true

    private let api = APIClient.shared

    @State private var activeFilter = "All"
    private let filters = ["All", "Owed", "You owe", "Hide settled"]

    // MARK: – Derived values

    private var netBalance: Int {
        balances.reduce(0) { $0 + $1.amount }
    }

    private var currency: String {
        auth.currentUser?.currency ?? "INR"
    }

    // MARK: – Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Bottom half is always white so no dark gap shows
                VStack(spacing: 0) {
                    SplitEZTheme.darkBg
                        .frame(height: 200)
                    Color(.systemBackground)
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                        contentSection
                    }
                }
                .refreshable { await loadData() }
            }
            .navigationBarHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
            .task { await loadData() }
        }
    }

    // MARK: – Header (dark navy)

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top bar: logo + icons
            HStack {
                // Logo
                HStack(spacing: 6) {
                    LogoMark(size: 28)
                    Text("Split")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white) +
                    Text("EZ")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(SplitEZTheme.primaryLight)
                }
                Spacer()
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.trailing, 12)
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            // Summary line
            Text("Overall, \(netBalance >= 0 ? "you are owed" : "you owe")")
                .font(.subheadline)
                .foregroundColor(SplitEZTheme.textTertiary)
                .padding(.top, 4)

            // Big balance number + currency picker
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(formatAmount(abs(netBalance), currency: currency))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(netBalance >= 0 ? SplitEZTheme.positive : SplitEZTheme.negative)
                    .monospacedDigit()

                HStack(spacing: 2) {
                    Text(currency)
                        .font(.caption.weight(.medium))
                        .foregroundColor(SplitEZTheme.textTertiary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(SplitEZTheme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .background(SplitEZTheme.darkBg)
        .edgesIgnoringSafeArea(.top)
    }

    // MARK: – Content (white card area)

    private var contentSection: some View {
        VStack(spacing: 0) {
            // Filter pills
            filterPills
                .padding(.top, 20)
                .padding(.bottom, 16)

            // Groups & Trips
            sectionHeader(title: "Groups & trips", destination: AnyView(GroupsListView()))
                .padding(.horizontal, 20)

            if groups.isEmpty && trips.isEmpty {
                emptyRow("No groups or trips yet")
            } else {
                VStack(spacing: 0) {
                    ForEach(filteredGroups) { group in
                        NavigationLink(destination: GroupsListView()) {
                            GroupTripRow(
                                icon: "house",
                                name: group.name,
                                subtitle: "\(group.memberCount ?? 0) people · Group",
                                amount: groupBalance(group.id),
                                currency: currency
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    ForEach(filteredTrips) { trip in
                        NavigationLink(destination: TripsListView()) {
                            GroupTripRow(
                                icon: "paperplane",
                                name: trip.name,
                                subtitle: "\(trip.memberCount ?? 0) people · Trip",
                                amount: tripBalance(trip.id),
                                currency: currency
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Friends
            sectionHeader(title: "Friends", destination: AnyView(EmptyView()))
                .padding(.horizontal, 20)
                .padding(.top, 16)

            if filteredBalances.isEmpty {
                emptyRow("No friends added yet")
            } else {
                VStack(spacing: 0) {
                    ForEach(filteredBalances, id: \.userId) { balance in
                        FriendRow(balance: balance, currency: currency)
                    }
                }
            }

            Spacer().frame(height: 80) // room for fixed ad banner + tab bar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
                .ignoresSafeArea(edges: .bottom)
        )
        .offset(y: -16)
    }

    // MARK: – Filter Pills

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { activeFilter = filter }
                    } label: {
                        Text(filter)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(activeFilter == filter ? .white : SplitEZTheme.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(activeFilter == filter
                                          ? SplitEZTheme.darkBg
                                          : SplitEZTheme.pillInactive)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: – Section Header

    private func sectionHeader(title: String, destination: AnyView) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            NavigationLink(destination: destination) {
                Text("See all")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(SplitEZTheme.primary)
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: – Filtering

    private var filteredGroups: [ExpenseGroup] {
        switch activeFilter {
        case "Owed": return groups.filter { groupBalance($0.id) > 0 }
        case "You owe": return groups.filter { groupBalance($0.id) < 0 }
        case "Hide settled": return groups.filter { groupBalance($0.id) != 0 }
        default: return groups
        }
    }

    private var filteredTrips: [Trip] {
        switch activeFilter {
        case "Owed": return trips.filter { tripBalance($0.id) > 0 }
        case "You owe": return trips.filter { tripBalance($0.id) < 0 }
        case "Hide settled": return trips.filter { tripBalance($0.id) != 0 }
        default: return trips
        }
    }

    private var filteredBalances: [Balance] {
        switch activeFilter {
        case "Owed": return balances.filter { $0.amount > 0 }
        case "You owe": return balances.filter { $0.amount < 0 }
        case "Hide settled": return balances.filter { $0.amount != 0 }
        default: return balances
        }
    }

    private func groupBalance(_ groupId: String) -> Int {
        SampleData.groupBalances[groupId] ?? 0
    }

    private func tripBalance(_ tripId: String) -> Int { 0 }

    // MARK: – Empty state

    private func emptyRow(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(SplitEZTheme.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
    }

    // MARK: – Load data

    private func loadData() async {
        isLoading = true
        async let b: [Balance] = (try? api.get("/balances")) ?? []
        async let g: [ExpenseGroup] = (try? api.get("/groups")) ?? []
        async let t: [Trip] = (try? api.get("/trips")) ?? []
        async let p: [PromotionalBanner] = (try? api.get("/promos", query: ["screen": "home"])) ?? []
        async let d: [DashboardElement] = (try? api.get("/dashboard/elements", query: ["screen": "home"])) ?? []
        balances = await b
        groups = await g
        trips = await t
        banners = await p
        dashboardElements = await d

        // Use sample data when API returns nothing
        if balances.isEmpty { balances = SampleData.balances }
        if groups.isEmpty { groups = SampleData.groups }
        if trips.isEmpty { trips = SampleData.trips }

        isLoading = false
        await AdManager.shared.loadPlacements(screen: "home")
    }
}

// MARK: - Group / Trip Row

struct GroupTripRow: View {
    let icon: String
    let name: String
    let subtitle: String
    var amount: Int = 0
    var currency: String = "INR"

    var body: some View {
        HStack(spacing: 12) {
            // Icon circle
            Circle()
                .fill(SplitEZTheme.secondaryBackground)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(SplitEZTheme.primary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(SplitEZTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.textSecondary)
            }

            Spacer()

            if amount != 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(amount > 0 ? "owes you" : "you owe")
                        .font(.caption)
                        .foregroundColor(SplitEZTheme.textSecondary)
                    Text(formatAmount(abs(amount), currency: currency))
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(amount > 0 ? SplitEZTheme.positive : SplitEZTheme.negative)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

// MARK: - Friend Row

struct FriendRow: View {
    let balance: Balance
    var currency: String = "INR"

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let user = balance.user {
                AvatarView(user: user, size: 44)
            } else {
                Circle()
                    .fill(SplitEZTheme.pillInactive)
                    .frame(width: 44, height: 44)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(balance.user?.displayName ?? "Unknown")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(SplitEZTheme.textPrimary)
                if let phone = balance.user?.phone, !phone.isEmpty {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(SplitEZTheme.textSecondary)
                }
            }

            Spacer()

            if balance.amount == 0 {
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
                    Text(balance.amount > 0 ? "owes you" : "you owe")
                        .font(.caption)
                        .foregroundColor(SplitEZTheme.textSecondary)
                    Text(formatAmount(abs(balance.amount), currency: currency))
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(balance.amount > 0 ? SplitEZTheme.positive : SplitEZTheme.negative)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

// MARK: - Logo Mark (small circle logo)

/// Split Coin logo mark — one coin cut in two, light indigo left, deep indigo right.
/// Draws two half-circle arcs separated by a visible gap.
struct LogoMark: View {
    var size: CGFloat = 28

    private let lightIndigo = Color(red: 0x81/255, green: 0x8C/255, blue: 0xF8/255) // #818CF8
    private let deepIndigo  = Color(red: 0x43/255, green: 0x38/255, blue: 0xCA/255) // #4338CA

    var body: some View {
        let gap: CGFloat = size * 0.08  // gap between halves
        let r = size / 2                // radius

        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)

            // Left half — light indigo
            var leftPath = Path()
            leftPath.addArc(center: CGPoint(x: center.x - gap / 2, y: center.y),
                            radius: r, startAngle: .degrees(90), endAngle: .degrees(270),
                            clockwise: false)
            leftPath.closeSubpath()
            context.fill(leftPath, with: .color(lightIndigo))

            // Right half — deep indigo
            var rightPath = Path()
            rightPath.addArc(center: CGPoint(x: center.x + gap / 2, y: center.y),
                             radius: r, startAngle: .degrees(270), endAngle: .degrees(90),
                             clockwise: false)
            rightPath.closeSubpath()
            context.fill(rightPath, with: .color(deepIndigo))
        }
        .frame(width: size + size * 0.08, height: size)
    }
}
