import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @State private var showAddSheet = false
    @State private var showMoreSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                FriendsTabView()
                    .tag(0)

                NavigationStack {
                    GroupsListView()
                }
                .tag(1)

                ActivityTabView()
                    .tag(2)
            }

            // Bottom bar: floating + button, ad banner, tab bar
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        showAddSheet = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(SplitEZTheme.primary)
                                .frame(width: 56, height: 56)
                                .shadow(color: SplitEZTheme.primary.opacity(0.3), radius: 10, y: 4)
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 8)
                }

                SponsoredBannerView()
                customTabBar
            }
        }
        .onAppear {
            UITabBar.appearance().isHidden = true
        }
        .fullScreenCover(isPresented: $showAddSheet) {
            AddExpenseSheet()
        }
        .sheet(isPresented: $showMoreSheet) {
            MoreOverlaySheet()
                .presentationDetents([.height(380), .large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: selectedTab) { oldTab, tab in
            let screens = ["friends", "groups", "activity"]
            if tab < screens.count {
                previousTab = oldTab
                Task { await AnalyticsTracker.shared.trackScreen(screens[tab]) }
            }
        }
        .task {
            await AnalyticsTracker.shared.startSession()
            await AnalyticsTracker.shared.trackScreen("friends")
        }
    }

    // MARK: – Custom Tab Bar (light background, indigo active circle)

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(activeIcon: "person.2.fill", inactiveIcon: "person.2", label: "Friends", tag: 0)
            tabButton(activeIcon: "person.3.fill", inactiveIcon: "person.3", label: "Groups", tag: 1)
            tabButton(activeIcon: "arrow.triangle.branch", inactiveIcon: "arrow.triangle.branch", label: "Activity", tag: 2)

            // More button — opens sheet overlay
            Button {
                showMoreSheet = true
            } label: {
                VStack(spacing: 4) {
                    ZStack {
                        if showMoreSheet {
                            Circle()
                                .fill(SplitEZTheme.primary)
                                .frame(width: 36, height: 36)
                        }
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18))
                            .foregroundColor(showMoreSheet ? .white : SplitEZTheme.textTertiary)
                    }
                    .frame(height: 36)
                    Text("More")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(showMoreSheet ? SplitEZTheme.primary : SplitEZTheme.textTertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(activeIcon: String, inactiveIcon: String, label: String, tag: Int) -> some View {
        let isActive = selectedTab == tag
        return Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isActive {
                        Circle()
                            .fill(SplitEZTheme.primary)
                            .frame(width: 36, height: 36)
                    }
                    Image(systemName: isActive ? activeIcon : inactiveIcon)
                        .font(.system(size: 18))
                        .foregroundColor(isActive ? .white : SplitEZTheme.textTertiary)
                }
                .frame(height: 36)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isActive ? SplitEZTheme.primary : SplitEZTheme.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Friends Tab

struct FriendsTabView: View {
    @ObservedObject private var store = ExpenseStore.shared
    @State private var friends: [Friend] = []
    @State private var pendingRequests: [FriendRequest] = []
    private var balances: [Balance] { store.balances }
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var showSortPicker = false
    @State private var sortOption = "name"
    @State private var showAddFriend = false
    @State private var showQRCode = false
    @State private var addFriendPhone = ""
    @State private var addFriendError: String?
    @State private var isAddingFriend = false
    @State private var activeFilter = "All"
    private let filterOptions = ["All", "Owes you", "You owe", "Settled"]
    private let api = APIClient.shared

    private var filteredFriends: [Friend] {
        var result = friends
        if !searchText.isEmpty {
            result = result.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
        }
        switch activeFilter {
        case "Owes you":
            result = result.filter { balanceFor($0.id) > 0 }
        case "You owe":
            result = result.filter { balanceFor($0.id) < 0 }
        case "Settled":
            result = result.filter { balanceFor($0.id) == 0 }
        default: break
        }
        switch sortOption {
        case "balance":
            return result.sorted { abs(balanceFor($0.id)) > abs(balanceFor($1.id)) }
        case "recent":
            return result.sorted { ($0.lastActiveAt ?? "") > ($1.lastActiveAt ?? "") }
        default:
            return result.sorted { $0.displayName < $1.displayName }
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
                                Button { showSortPicker = true } label: {
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
            .confirmationDialog("Sort friends", isPresented: $showSortPicker) {
                Button("Name (A–Z)") { sortOption = "name" }
                Button("Highest balance") { sortOption = "balance" }
                Button("Recently active") { sortOption = "recent" }
            }
            .sheet(isPresented: $showAddFriend) {
                addFriendSheet
            }
            .sheet(isPresented: $showQRCode) {
                qrCodeSheet
            }
        }
    }

    // MARK: – Add Friend Sheet

    private var addFriendSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Add a friend by phone number")
                    .font(.subheadline)
                    .foregroundColor(SplitEZTheme.textSecondary)

                TextField("+91 98765 43210", text: $addFriendPhone)
                    .keyboardType(.phonePad)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.systemGray6))
                    )

                if let error = addFriendError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(SplitEZTheme.negative)
                }

                Button {
                    Task { await sendFriendRequest() }
                } label: {
                    if isAddingFriend {
                        ProgressView().tint(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                    } else {
                        Text("Send friend request")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(addFriendPhone.isEmpty ? SplitEZTheme.primary.opacity(0.4) : SplitEZTheme.primary)
                )
                .disabled(addFriendPhone.isEmpty || isAddingFriend)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddFriend = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var qrCodeSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "qrcode")
                    .font(.system(size: 120))
                    .foregroundColor(SplitEZTheme.primary)

                Text("Share your QR code")
                    .font(.headline)

                Text("Friends can scan this to add you on SplitEZ")
                    .font(.subheadline)
                    .foregroundColor(SplitEZTheme.textSecondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding(20)
            .padding(.top, 40)
            .navigationTitle("My QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showQRCode = false }
                }
            }
        }
    }

    private func sendFriendRequest() async {
        isAddingFriend = true
        addFriendError = nil
        struct AddFriendReq: Codable { let phone: String }
        do {
            let _: AnyCodable = try await api.post("/friend-requests", body: AddFriendReq(phone: addFriendPhone))
            showAddFriend = false
            addFriendPhone = ""
            await loadData()
        } catch {
            addFriendError = "Could not send request. Check the phone number."
        }
        isAddingFriend = false
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
                Button { showQRCode = true } label: {
                    Image(systemName: "qrcode")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.trailing, 12)
                Button { showAddFriend = true } label: {
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

            // Filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filterOptions, id: \.self) { option in
                        Button {
                            activeFilter = option
                        } label: {
                            Text(option)
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(activeFilter == option ? SplitEZTheme.primary : Color.white.opacity(0.12))
                                )
                                .foregroundColor(activeFilter == option ? .white : .white.opacity(0.7))
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

    // MARK: – Actions

    private func loadData() async {
        isLoading = true
        async let f: [Friend] = (try? api.get("/people")) ?? []
        async let r: [FriendRequest] = (try? api.get("/friend-requests", query: ["status": "pending"])) ?? []
        friends = await f
        pendingRequests = await r
        if friends.isEmpty { friends = SampleData.friends }
        await store.reload()
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
    @ObservedObject private var store = ExpenseStore.shared
    private var activities: [Activity] { store.activities }
    @State private var activeSort = "Date"
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var showExportShare = false
    private let api = APIClient.shared
    private let sortOptions = ["Date", "Name", "Type", "Amount"]

    private var sortedActivities: [Activity] {
        var result = activities
        if !searchText.isEmpty {
            result = result.filter { activity in
                let desc = (activity.metadata?["description"]?.value as? String) ?? ""
                let name = activity.user?.firstName ?? ""
                let groupName = (activity.metadata?["groupName"]?.value as? String) ?? ""
                let query = searchText.lowercased()
                return desc.lowercased().contains(query) || name.lowercased().contains(query) || groupName.lowercased().contains(query) || activity.type.lowercased().contains(query)
            }
        }
        switch activeSort {
        case "Name":
            return result.sorted { ($0.user?.firstName ?? "") < ($1.user?.firstName ?? "") }
        case "Type":
            return result.sorted { $0.type < $1.type }
        case "Amount":
            return result.sorted {
                let a = ($0.metadata?["amount"]?.value as? Int) ?? 0
                let b = ($1.metadata?["amount"]?.value as? Int) ?? 0
                return abs(a) > abs(b)
            }
        default:
            return result.sorted { $0.createdAt > $1.createdAt }
        }
    }

    /// Group activities by day label (TODAY, YESTERDAY, or date)
    private var groupedActivities: [(String, [Activity])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        var groups: [String: [Activity]] = [:]
        var order: [String] = []

        for activity in sortedActivities {
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
                                        if let expense = store.expenses.first(where: { $0.id == activity.entityId }) {
                                            NavigationLink(destination: ExpenseDetailView(expense: expense)) {
                                                ActivityRow(activity: activity)
                                            }
                                            .buttonStyle(.plain)
                                        } else {
                                            ActivityRow(activity: activity)
                                        }
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
                await store.reload()
            }
            .sheet(isPresented: $showExportShare) {
                ShareSheetView(items: [exportActivityText()])
            }
        }
    }

    private func exportActivityText() -> String {
        var text = "SplitEZ Activity Export\n\n"
        for (label, items) in groupedActivities {
            text += "\(label)\n"
            for activity in items {
                let name = activity.user?.firstName ?? "Someone"
                let desc = (activity.metadata?["description"]?.value as? String) ?? activity.type
                let amt = activity.metadata?["amount"]?.value as? Int
                let amtStr = amt != nil ? " — \(formatAmount(abs(amt!)))" : ""
                text += "  \(name): \(desc)\(amtStr)\n"
            }
            text += "\n"
        }
        return text
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
                Button { withAnimation { showSearch.toggle(); if !showSearch { searchText = "" } } } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.trailing, 12)
                Button { showExportShare = true } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
            }

            if showSearch {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(SplitEZTheme.textTertiary)
                    TextField("Search activity", text: $searchText)
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
    let prefillFriend: Friend?
    let editExpense: Expense?
    let editingId: String?

    @Environment(\.dismiss) var dismiss
    @State private var amountText: String
    @State private var description: String
    @State private var selectedCurrency: String
    @State private var selectedCategory: ExpenseCategory
    @State private var showCategoryPicker = false
    @State private var splitMethod: String
    @State private var note: String
    @State private var expenseDate: Date
    @State private var showDatePicker = false
    @State private var showNotesField: Bool
    @State private var showSplitBreakdown = false
    @State private var isLoading = false
    @State private var error: String?
    @State private var showCurrencyPicker = false
    @State private var showValidation = false
    @State private var showSplitMethodPicker = false

    // Group & member selection
    @State private var groups: [ExpenseGroup] = []
    @State private var selectedGroupIndex: Int? = nil
    @State private var showGroupPicker = false
    @State private var paidByUserId: String
    @State private var showPaidByPicker = false
    @State private var selectedParticipantIds: Set<String>
    @State private var showParticipantPicker = false
    @State private var participantSearchText = ""

    init(prefillFriend: Friend? = nil, expense: Expense? = nil) {
        self.prefillFriend = prefillFriend
        self.editExpense = expense
        self.editingId = expense?.id

        if let exp = expense {
            _amountText = State(initialValue: String(format: "%.2f", Double(exp.amount) / 100.0))
            _description = State(initialValue: exp.description)
            _selectedCurrency = State(initialValue: exp.currency)
            _selectedCategory = State(initialValue: ExpenseCategory(rawValue: exp.category ?? "other") ?? .other)
            _splitMethod = State(initialValue: exp.splitMethod)
            _note = State(initialValue: exp.note ?? "")
            _showNotesField = State(initialValue: exp.note != nil && !exp.note!.isEmpty)
            let iso = ISO8601DateFormatter()
            _expenseDate = State(initialValue: iso.date(from: exp.createdAt) ?? Date())
            _paidByUserId = State(initialValue: exp.paidBy?.id ?? SampleData.currentUser.id)
            let splitIds = Set(exp.splits?.compactMap(\.userId) ?? [])
            let participantIds = splitIds.isEmpty ? Set([SampleData.currentUser.id, exp.paidBy?.id ?? SampleData.currentUser.id]) : splitIds
            _selectedParticipantIds = State(initialValue: participantIds)
        } else {
            _amountText = State(initialValue: "")
            _description = State(initialValue: "")
            _selectedCurrency = State(initialValue: "INR")
            _selectedCategory = State(initialValue: .food)
            _splitMethod = State(initialValue: "EQUAL")
            _note = State(initialValue: "")
            _showNotesField = State(initialValue: false)
            _expenseDate = State(initialValue: Date())
            _paidByUserId = State(initialValue: SampleData.currentUser.id)
            if let friend = prefillFriend {
                _selectedParticipantIds = State(initialValue: [SampleData.currentUser.id, friend.id])
            } else {
                _selectedParticipantIds = State(initialValue: [])
            }
        }
    }

    // For exact/percentage splits
    @State private var exactAmounts: [String: String] = [:]
    @State private var percentages: [String: String] = [:]

    private let api = APIClient.shared

    private let currencies = ["INR", "USD", "EUR", "GBP"]
    private let currencySymbols: [String: String] = ["INR": "₹", "USD": "$", "EUR": "€", "GBP": "£"]
    private let splitMethods = ["EQUAL", "EXACT", "PERCENTAGE"]

    private var selectedGroup: ExpenseGroup? {
        guard let index = selectedGroupIndex, !groups.isEmpty, index < groups.count else { return nil }
        return groups[index]
    }

    private var allPeople: [UserSummary] {
        var seen = Set<String>()
        var result: [UserSummary] = []
        result.append(SampleData.currentUser)
        seen.insert(SampleData.currentUser.id)
        for friend in SampleData.friends {
            if seen.insert(friend.id).inserted {
                result.append(UserSummary(
                    id: friend.id, firstName: friend.firstName, lastName: friend.lastName,
                    phone: friend.phone, profilePicture: friend.profilePicture, avatar: friend.avatar
                ))
            }
        }
        for group in groups {
            for member in group.members ?? [] {
                if seen.insert(member.id).inserted {
                    result.append(member)
                }
            }
        }
        return result
    }

    private var members: [UserSummary] {
        if let group = selectedGroup {
            return group.members ?? []
        }
        return allPeople
    }

    private var participants: [UserSummary] {
        return allPeople.filter { selectedParticipantIds.contains($0.id) }
    }

    private var paidByUser: UserSummary? {
        allPeople.first { $0.id == paidByUserId }
    }

    private var currSymbol: String {
        currencySymbols[selectedCurrency] ?? "₹"
    }

    private var amountMinor: Int {
        Int((Double(amountText) ?? 0) * 100)
    }

    private var perPersonAmount: String {
        guard participants.count > 0, let amount = Double(amountText), amount > 0 else {
            return "\(currSymbol)0"
        }
        let share = amount / Double(participants.count)
        return "\(currSymbol)\(String(format: "%.0f", share))"
    }

    private func avatarColor(for user: UserSummary) -> Color {
        if let hex = user.avatar?.backgroundColor {
            return Color(hex: hex)
        }
        return SplitEZTheme.primary
    }

    private func avatarInitials(for user: UserSummary) -> String {
        user.avatar?.initials ?? String(user.firstName.prefix(1))
    }

    private func displayName(for user: UserSummary) -> String {
        user.id == SampleData.currentUser.id ? "You" : user.firstName
    }

    var body: some View {
        VStack(spacing: 0) {
            // Dark header – pinned, not in scroll
            VStack(spacing: 16) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text(editExpense != nil ? "Edit expense" : "New expense")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 24)
                }

                HStack(alignment: .center, spacing: 4) {
                    Text(currSymbol)
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
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(SplitEZTheme.darkBg.ignoresSafeArea(edges: .top))
            .fixedSize(horizontal: false, vertical: true)

            // Content – scrollable with save button
            ZStack(alignment: .bottom) {
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

                        // Paid By + Split participants
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("PAID BY")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundColor(SplitEZTheme.textTertiary)
                                    .tracking(0.5)

                                Button { showPaidByPicker = true } label: {
                                    HStack(spacing: 8) {
                                        if let user = paidByUser {
                                            miniAvatar(initial: avatarInitials(for: user), color: avatarColor(for: user))
                                            Text(displayName(for: user))
                                                .font(.subheadline.weight(.medium))
                                                .foregroundColor(SplitEZTheme.textPrimary)
                                        }
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

                            VStack(alignment: .leading, spacing: 8) {
                                Text("SPLIT")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundColor(SplitEZTheme.textTertiary)
                                    .tracking(0.5)

                                Button { showParticipantPicker = true } label: {
                                    HStack(spacing: -6) {
                                        ForEach(Array(participants.prefix(2)), id: \.id) { user in
                                            miniAvatar(initial: avatarInitials(for: user), color: avatarColor(for: user))
                                        }
                                        if participants.count > 2 {
                                            Text("+\(participants.count - 2)")
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

                        // Split method + Group picker
                        HStack(spacing: 12) {
                            Button { showSplitMethodPicker = true } label: {
                                HStack(spacing: 6) {
                                    Text(splitMethodLabel)
                                        .font(.subheadline.weight(.semibold))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(SplitEZTheme.primary)
                                )
                            }

                            Button { showGroupPicker = true } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.2")
                                        .font(.system(size: 14, weight: .medium))
                                    Text(selectedGroup?.name ?? "Select")
                                        .font(.subheadline.weight(.medium))
                                        .lineLimit(1)
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

                        // Each person pays – expandable
                        VStack(spacing: 0) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showSplitBreakdown.toggle()
                                }
                            } label: {
                                HStack {
                                    Text("EACH PERSON PAYS")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundColor(SplitEZTheme.textTertiary)
                                        .tracking(0.5)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(SplitEZTheme.textTertiary)
                                        .rotationEffect(.degrees(showSplitBreakdown ? 180 : 0))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }

                            if showSplitBreakdown {
                                ForEach(Array(participants.enumerated()), id: \.element.id) { index, user in
                                    if index > 0 {
                                        Divider().padding(.leading, 52)
                                    }
                                    HStack(spacing: 10) {
                                        miniAvatar(initial: avatarInitials(for: user), color: avatarColor(for: user))
                                        Text(displayName(for: user))
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(SplitEZTheme.textPrimary)
                                        Spacer()

                                        if splitMethod == "EXACT" {
                                            HStack(spacing: 2) {
                                                Text(currSymbol)
                                                    .font(.caption.weight(.medium))
                                                    .foregroundColor(SplitEZTheme.textTertiary)
                                                TextField("0", text: exactBinding(for: user.id))
                                                    .font(.subheadline.weight(.bold))
                                                    .foregroundColor(SplitEZTheme.textPrimary)
                                                    .keyboardType(.numberPad)
                                                    .multilineTextAlignment(.trailing)
                                                    .frame(width: 60)
                                            }
                                        } else if splitMethod == "PERCENTAGE" {
                                            HStack(spacing: 2) {
                                                TextField("0", text: percentBinding(for: user.id))
                                                    .font(.subheadline.weight(.bold))
                                                    .foregroundColor(SplitEZTheme.textPrimary)
                                                    .keyboardType(.numberPad)
                                                    .multilineTextAlignment(.trailing)
                                                    .frame(width: 40)
                                                Text("%")
                                                    .font(.caption.weight(.medium))
                                                    .foregroundColor(SplitEZTheme.textTertiary)
                                            }
                                        } else {
                                            Text(perPersonAmount)
                                                .font(.subheadline.weight(.bold))
                                                .foregroundColor(SplitEZTheme.textPrimary)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))

                                if splitMethod == "EXACT" {
                                    exactSplitWarning
                                } else if splitMethod == "PERCENTAGE" {
                                    percentageSplitWarning
                                }

                                Spacer().frame(height: 8)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemGray6))
                        )

                        // Date, Notes, Receipt row
                        HStack(spacing: 0) {
                            Button { showDatePicker.toggle() } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 14))
                                    Text(dateLabel)
                                        .font(.subheadline)
                                }
                                .foregroundColor(SplitEZTheme.textSecondary)
                            }

                            Divider().frame(height: 20).padding(.horizontal, 16)

                            Button { showNotesField.toggle() } label: {
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

                        if let msg = showValidation ? validationMessage : nil {
                            Text(msg)
                                .font(.caption)
                                .foregroundColor(SplitEZTheme.negative)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let error {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(SplitEZTheme.negative)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Spacer().frame(height: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
                .background(Color(.systemBackground))

                // Save button
                VStack(spacing: 0) {
                    Button {
                        if canSave {
                            Task { await saveExpense() }
                        } else {
                            withAnimation { showValidation = true }
                        }
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
                    .disabled(isLoading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea(edges: .bottom)
                )
            } // ZStack for scroll + save
        } // outer VStack
        .task { await loadGroups() }
        .confirmationDialog("Select Currency", isPresented: $showCurrencyPicker) {
            ForEach(currencies, id: \.self) { currency in
                Button("\(currencySymbols[currency] ?? "") \(currency)") {
                    selectedCurrency = currency
                }
            }
        }
        .confirmationDialog("Select Category", isPresented: $showCategoryPicker) {
            ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                Button(cat.label) { selectedCategory = cat }
            }
        }
        .sheet(isPresented: $showSplitMethodPicker) {
            splitMethodSheet
        }
        .confirmationDialog("Select Group", isPresented: $showGroupPicker) {
            Button("None (no group)") {
                selectedGroupIndex = nil
            }
            ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                Button(group.name) { selectGroup(index) }
            }
        }
        .confirmationDialog("Paid By", isPresented: $showPaidByPicker) {
            ForEach(participants, id: \.id) { user in
                Button(displayName(for: user)) { paidByUserId = user.id }
            }
        }
        .sheet(isPresented: $showParticipantPicker) {
            participantPickerSheet
        }
    }

    // MARK: – Split method label

    private var splitMethodLabel: String {
        switch splitMethod {
        case "EXACT": return "Exact"
        case "PERCENTAGE": return "Percentage"
        default: return "Equally"
        }
    }

    // MARK: – Exact/Percentage bindings

    private func exactBinding(for userId: String) -> Binding<String> {
        Binding(
            get: { exactAmounts[userId] ?? "" },
            set: { exactAmounts[userId] = $0 }
        )
    }

    private func percentBinding(for userId: String) -> Binding<String> {
        Binding(
            get: { percentages[userId] ?? "" },
            set: { percentages[userId] = $0 }
        )
    }

    // MARK: – Split warnings

    @ViewBuilder
    private var exactSplitWarning: some View {
        let total = participants.reduce(0.0) { $0 + (Double(exactAmounts[$1.id] ?? "0") ?? 0) }
        let target = Double(amountText) ?? 0
        if target > 0 && abs(total - target) > 0.01 {
            HStack {
                Image(systemName: total > target ? "exclamationmark.triangle" : "info.circle")
                    .font(.caption)
                Text(total > target
                     ? "Total exceeds by \(currSymbol)\(String(format: "%.0f", total - target))"
                     : "\(currSymbol)\(String(format: "%.0f", target - total)) remaining")
                    .font(.caption)
            }
            .foregroundColor(total > target ? SplitEZTheme.negative : SplitEZTheme.textTertiary)
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
        }
    }

    @ViewBuilder
    private var percentageSplitWarning: some View {
        let total = participants.reduce(0.0) { $0 + (Double(percentages[$1.id] ?? "0") ?? 0) }
        if abs(total - 100) > 0.01 {
            HStack {
                Image(systemName: total > 100 ? "exclamationmark.triangle" : "info.circle")
                    .font(.caption)
                Text(total > 100
                     ? "Total exceeds 100% by \(String(format: "%.0f", total - 100))%"
                     : "\(String(format: "%.0f", 100 - total))% remaining")
                    .font(.caption)
            }
            .foregroundColor(total > 100 ? SplitEZTheme.negative : SplitEZTheme.textTertiary)
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
        }
    }

    // MARK: – Participant picker sheet

    private var searchFilteredPeople: [UserSummary] {
        let query = participantSearchText.trimmingCharacters(in: .whitespaces)
        if query.isEmpty { return allPeople }
        return allPeople.filter { $0.displayName.localizedCaseInsensitiveContains(query) || ($0.phone ?? "").contains(query) }
    }

    private var selectedPeople: [UserSummary] {
        allPeople.filter { selectedParticipantIds.contains($0.id) }
    }

    private var participantPickerSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Selected chips
                if !selectedPeople.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(selectedPeople, id: \.id) { user in
                                HStack(spacing: 6) {
                                    miniAvatar(initial: avatarInitials(for: user), color: avatarColor(for: user))
                                    Text(user.firstName)
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(SplitEZTheme.textPrimary)
                                    Button {
                                        selectedParticipantIds.remove(user.id)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(SplitEZTheme.textTertiary)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(SplitEZTheme.secondaryBackground)
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    Divider()
                }

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(SplitEZTheme.textTertiary)
                    TextField("Search by name or phone", text: $participantSearchText)
                        .font(.subheadline)
                        .autocorrectionDisabled()
                    if !participantSearchText.isEmpty {
                        Button { participantSearchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(SplitEZTheme.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))

                // People list
                List {
                    ForEach(searchFilteredPeople, id: \.id) { user in
                        Button {
                            if selectedParticipantIds.contains(user.id) {
                                selectedParticipantIds.remove(user.id)
                            } else {
                                selectedParticipantIds.insert(user.id)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                miniAvatar(initial: avatarInitials(for: user), color: avatarColor(for: user))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(displayName(for: user))
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(SplitEZTheme.textPrimary)
                                    if let phone = user.phone, !phone.isEmpty {
                                        Text(phone)
                                            .font(.caption)
                                            .foregroundColor(SplitEZTheme.textTertiary)
                                    }
                                }
                                Spacer()
                                if selectedParticipantIds.contains(user.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(SplitEZTheme.primary)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(Color(.systemGray3))
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Split with")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        participantSearchText = ""
                        showParticipantPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: – Split method sheet

    private var splitMethodSheet: some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            VStack(alignment: .leading, spacing: 4) {
                Text("How was this split?")
                    .font(.title3.weight(.bold))
                    .foregroundColor(SplitEZTheme.textPrimary)
                Text("Tap to select · amount updates live")
                    .font(.subheadline)
                    .foregroundColor(SplitEZTheme.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            VStack(spacing: 10) {
                splitOptionCard(
                    method: "EQUAL",
                    title: "You paid, split equally",
                    subtitle: splitOptionSubtitle(payer: "you", method: "EQUAL"),
                    leftUser: SampleData.currentUser.id,
                    rightUser: otherParticipantId
                )

                splitOptionCard(
                    method: "EXACT",
                    title: "Split by exact amounts",
                    subtitle: "Enter how much each person owes",
                    leftUser: SampleData.currentUser.id,
                    rightUser: otherParticipantId
                )

                splitOptionCard(
                    method: "PERCENTAGE",
                    title: "Split by percentage",
                    subtitle: "Assign each person a percentage",
                    leftUser: SampleData.currentUser.id,
                    rightUser: otherParticipantId
                )
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .presentationDetents([.medium])
    }

    private var otherParticipantId: String? {
        participants.first(where: { $0.id != SampleData.currentUser.id })?.id
    }

    private func splitOptionSubtitle(payer: String, method: String) -> String {
        guard let amount = Double(amountText), amount > 0 else {
            return "Enter an amount first"
        }
        let otherName = participants.first(where: { $0.id != SampleData.currentUser.id })?.firstName ?? "Other"
        let share = amount / max(Double(participants.count), 1)
        return "\(otherName) owes you \(currSymbol)\(String(format: "%.0f", share))"
    }

    private func splitOptionCard(method: String, title: String, subtitle: String, leftUser: String, rightUser: String?) -> some View {
        Button {
            splitMethod = method
            if method != "EQUAL" { showSplitBreakdown = true }
            showSplitMethodPicker = false
        } label: {
            HStack(spacing: 14) {
                // Overlapping avatars
                ZStack {
                    if let left = members.first(where: { $0.id == leftUser }) {
                        miniAvatar(initial: avatarInitials(for: left), color: avatarColor(for: left))
                    }
                    if let rId = rightUser, let right = members.first(where: { $0.id == rId }) {
                        miniAvatar(initial: avatarInitials(for: right), color: avatarColor(for: right).opacity(0.6))
                            .offset(x: 16)
                    }
                }
                .frame(width: 48, alignment: .leading)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(SplitEZTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(splitMethod == method ? SplitEZTheme.positive : SplitEZTheme.textSecondary)
                }

                Spacer()

                if splitMethod == method {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(SplitEZTheme.primary)
                } else {
                    Circle()
                        .stroke(Color(.systemGray4), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(splitMethod == method ? SplitEZTheme.primary : Color(.systemGray5), lineWidth: splitMethod == method ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: – Helpers

    private var dateLabel: String {
        if Calendar.current.isDateInToday(expenseDate) { return "Today" }
        if Calendar.current.isDateInYesterday(expenseDate) { return "Yesterday" }
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM"
        return fmt.string(from: expenseDate)
    }

    private var validationMessage: String? {
        let amt = Double(amountText) ?? 0
        if amt <= 0 { return "Enter an amount" }
        if description.trimmingCharacters(in: .whitespaces).isEmpty { return "Add a description" }
        if paidByUser == nil { return "Select who paid" }
        if participants.isEmpty { return "Select who to split with" }
        if splitMethod == "EXACT" {
            let total = participants.reduce(0.0) { $0 + (Double(exactAmounts[$1.id] ?? "0") ?? 0) }
            if abs(total - amt) >= 0.01 { return "Exact amounts must add up to \(currSymbol)\(amountText)" }
        }
        if splitMethod == "PERCENTAGE" {
            let total = participants.reduce(0.0) { $0 + (Double(percentages[$1.id] ?? "0") ?? 0) }
            if abs(total - 100) >= 0.01 { return "Percentages must add up to 100%" }
        }
        return nil
    }

    private var canSave: Bool { validationMessage == nil }

    // MARK: – Data loading

    private func loadGroups() async {
        var loaded: [ExpenseGroup] = (try? await api.get("/groups")) ?? []
        if loaded.isEmpty { loaded = SampleData.groups }
        groups = loaded

        if editExpense != nil {
            if let gid = editExpense?.groupId, let idx = groups.firstIndex(where: { $0.id == gid }) {
                selectedGroupIndex = idx
            }
        }
        // prefillFriend and default: already initialized in init, don't override
    }

    private func selectGroup(_ index: Int) {
        selectedGroupIndex = index
        guard index < groups.count, let group = groups[safe: index] else { return }
        var memberIds = Set((group.members ?? []).map(\.id))
        if let friend = prefillFriend {
            memberIds.insert(friend.id)
            memberIds.insert(SampleData.currentUser.id)
        }
        selectedParticipantIds = memberIds
        if let firstMember = group.members?.first(where: { $0.id == SampleData.currentUser.id }) {
            paidByUserId = firstMember.id
        } else if let first = group.members?.first {
            paidByUserId = first.id
        }
        exactAmounts = [:]
        percentages = [:]
    }

    // MARK: – Save

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

        let participantList: [SplitParticipant] = participants.map { user in
            switch splitMethod {
            case "EXACT":
                let share = Int((Double(exactAmounts[user.id] ?? "0") ?? 0) * 100)
                return SplitParticipant(userId: user.id, shareAmount: share)
            case "PERCENTAGE":
                let pct = Int((Double(percentages[user.id] ?? "0") ?? 0) * 100)
                return SplitParticipant(userId: user.id, percentageBps: pct)
            default:
                let share = amount / participants.count
                return SplitParticipant(userId: user.id, shareAmount: share)
            }
        }

        let req = CreateExpenseRequest(
            description: description,
            amount: amount,
            currency: selectedCurrency,
            splitMethod: splitMethod,
            category: selectedCategory.label,
            note: note.isEmpty ? nil : note,
            date: dateFmt.string(from: expenseDate),
            paidById: paidByUserId,
            groupId: selectedGroup?.id,
            participants: participantList
        )

        var savedExpense: Expense?
        do {
            savedExpense = try await api.post("/expenses", body: req)
        } catch {
            // API unavailable — build local expense for demo mode
            let splits = participantList.map { p in
                ExpenseSplit(
                    userId: p.userId,
                    user: allPeople.first(where: { $0.id == p.userId }),
                    shareAmount: p.shareAmount ?? (amount / participants.count),
                    percentageBps: p.percentageBps
                )
            }
            savedExpense = Expense(
                id: editingId ?? "e_\(UUID().uuidString.prefix(8))",
                description: description,
                amount: amount,
                currency: selectedCurrency,
                splitMethod: splitMethod.lowercased(),
                category: selectedCategory.label,
                note: note.isEmpty ? nil : note,
                date: dateFmt.string(from: expenseDate),
                paidBy: paidByUser,
                createdBy: SampleData.currentUser,
                splits: splits,
                groupId: selectedGroup?.id,
                tripId: nil,
                idempotencyKey: nil,
                createdAt: ISO8601DateFormatter().string(from: Date())
            )
        }
        if let expense = savedExpense {
            if editingId != nil {
                ExpenseStore.shared.updateExpense(expense)
            } else {
                ExpenseStore.shared.addExpense(expense)
            }
        }
        isLoading = false
        dismiss()
    }

    private func miniAvatar(initial: String, color: Color) -> some View {
        Text(initial)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 28, height: 28)
            .background(Circle().fill(color))
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
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
        let type = activity.type.lowercased()
        var bold = AttributedString(name)
        bold.font = .subheadline.weight(.bold)
        switch type {
        case "expense_created":
            let desc = activity.metadata?["description"]
            let expName = (desc?.value as? String) ?? "an expense"
            result = bold + AttributedString(" added \(expName)")
        case "settlement_created", "settlement_completed":
            let toName = (activity.metadata?["toName"]?.value as? String) ?? "someone"
            result = bold + AttributedString(" settled up with \(toName)")
        case "group_created":
            let groupName = (activity.metadata?["name"]?.value as? String) ?? "a group"
            result = bold + AttributedString(" created \(groupName)")
        case "friend_added":
            let friendName = (activity.metadata?["name"]?.value as? String) ?? "a friend"
            result = bold + AttributedString(" added \(friendName)")
        default:
            result = bold + AttributedString(" updated an activity")
        }
        return result
    }

    private var activitySubtitle: String {
        let groupName = (activity.metadata?["groupName"]?.value as? String)
            ?? (activity.metadata?["tripName"]?.value as? String)
            ?? ""
        let type = activity.type.lowercased()
        switch type {
        case "settlement_completed", "settlement_created":
            return groupName.isEmpty ? "settlement" : "\(groupName) · settlement"
        case "expense_created":
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

struct MoreOverlaySheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Title + close
                HStack {
                    Text("More")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(SplitEZTheme.textPrimary)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(SplitEZTheme.textTertiary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color(.systemGray5)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 16)

                // Menu items
                VStack(spacing: 0) {
                    moreMenuRow(icon: "person.crop.circle", iconColor: SplitEZTheme.primary, label: "Account") {
                        EditProfileView()
                    }
                    Divider().padding(.leading, 68)
                    moreMenuRow(icon: "gearshape", iconColor: SplitEZTheme.primary, label: "Settings") {
                        SettingsView()
                    }
                    Divider().padding(.leading, 68)
                    moreMenuRow(icon: "questionmark.circle", iconColor: SplitEZTheme.primary, label: "Help") {
                        HelpView()
                    }
                    Divider().padding(.leading, 68)
                    moreMenuRow(icon: "text.bubble", iconColor: SplitEZTheme.primary, label: "FAQ") {
                        FAQView()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func moreMenuRow<Destination: View>(icon: String, iconColor: Color, label: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle().fill(iconColor.opacity(0.1))
                    )

                Text(label)
                    .font(.body.weight(.medium))
                    .foregroundColor(SplitEZTheme.textPrimary)

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

// MARK: - Help & FAQ placeholder views

struct HelpView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                SplitEZTheme.darkBg.frame(height: 120)
                Color(.systemBackground)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Text("Help")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .background(SplitEZTheme.darkBg)

                    VStack(spacing: 16) {
                        helpRow(icon: "envelope", title: "Contact Support", subtitle: "Get help from our team")
                        helpRow(icon: "shield", title: "Privacy Policy", subtitle: "How we handle your data")
                        helpRow(icon: "doc.text", title: "Terms of Service", subtitle: "Usage terms and conditions")
                        helpRow(icon: "info.circle", title: "About SplitEZ", subtitle: "Version 1.0.0")
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    .offset(y: -16)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func helpRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(SplitEZTheme.primary)
                .frame(width: 36, height: 36)
                .background(Circle().fill(SplitEZTheme.primary.opacity(0.1)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(SplitEZTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.textTertiary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(SplitEZTheme.textTertiary)
        }
        .padding(.vertical, 4)
    }
}

struct FAQView: View {
    @Environment(\.dismiss) var dismiss

    private let faqs: [(q: String, a: String)] = [
        ("How do I add an expense?", "Tap the + button on any screen to add a new expense. Enter the amount, description, and choose how to split it."),
        ("How do I settle up?", "Go to a friend's ledger and tap 'Settle up'. You can record a payment via UPI, bank transfer, or cash."),
        ("Can I split expenses unequally?", "Yes! When adding an expense, tap the split method to choose between equal, percentage, or exact amounts."),
        ("How do I create a group?", "Go to the Groups tab and tap the + button. Add a name and invite your friends."),
        ("Is my data secure?", "Yes, all data is encrypted in transit and at rest. We never share your financial data with third parties."),
    ]

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                SplitEZTheme.darkBg.frame(height: 120)
                Color(.systemBackground)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Text("FAQ")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .background(SplitEZTheme.darkBg)

                    VStack(spacing: 0) {
                        ForEach(Array(faqs.enumerated()), id: \.offset) { index, faq in
                            if index > 0 { Divider() }
                            DisclosureGroup {
                                Text(faq.a)
                                    .font(.subheadline)
                                    .foregroundColor(SplitEZTheme.textSecondary)
                                    .padding(.top, 4)
                                    .padding(.bottom, 8)
                            } label: {
                                Text(faq.q)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(SplitEZTheme.textPrimary)
                            }
                            .tint(SplitEZTheme.primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }
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
    }
}

// MARK: - Sponsored Banner (persistent above tab bar on all screens)

struct SponsoredBannerView: View {
    var body: some View {
        HStack(spacing: 10) {
            Text("AD")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(SplitEZTheme.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(.systemGray5))
                )

            VStack(alignment: .leading, spacing: 1) {
                Text("Sponsored")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(SplitEZTheme.textPrimary)
                Text("Remove ads · ₹99/mo")
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.textSecondary)
            }
            Spacer()
            Button("Go Plus") {}
                .font(.caption.weight(.semibold))
                .foregroundColor(SplitEZTheme.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .stroke(SplitEZTheme.primary, lineWidth: 1.2)
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 4, y: -1)
        )
    }
}
