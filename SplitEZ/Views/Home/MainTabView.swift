import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showAddExpense = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)

                GroupsListView()
                    .tag(1)

                // Placeholder for center Add button
                Color.clear
                    .tag(2)

                NotificationsListView()
                    .tag(3)

                SettingsView()
                    .tag(4)
            }

            // Custom tab bar
            ZStack {
                // Dark background bar
                HStack(spacing: 0) {
                    tabButton(icon: "house.fill", label: "Home", tag: 0)
                    tabButton(icon: "person.2.fill", label: "Friends", tag: 1)
                    // Spacer for floating button
                    Color.clear.frame(width: 60)
                    tabButton(icon: "bell.fill", label: "Activity", tag: 3)
                    tabButton(icon: "ellipsis", label: "More", tag: 4)
                }
                .frame(height: 56)
                .background(SplitEZTheme.darkBg)

                // Floating Add button
                Button {
                    showAddExpense = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(SplitEZTheme.primary)
                            .frame(width: 52, height: 52)
                            .shadow(color: SplitEZTheme.primary.opacity(0.4), radius: 8, y: 4)
                        Image(systemName: "plus")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.white)
                    }
                }
                .offset(y: -16)
            }
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: selectedTab) { _, tab in
            let screens = ["home", "friends", "add", "activity", "settings"]
            if tab != 2 {
                Task { await AnalyticsTracker.shared.trackScreen(screens[tab]) }
            }
        }
        .task {
            await AnalyticsTracker.shared.startSession()
            await AnalyticsTracker.shared.trackScreen("home")
        }
        .sheet(isPresented: $showAddExpense) {
            // Future: AddExpenseView()
            Text("Add Expense")
                .font(.title)
                .padding()
        }
    }

    private func tabButton(icon: String, label: String, tag: Int) -> some View {
        Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(selectedTab == tag ? SplitEZTheme.primaryLight : SplitEZTheme.muted)
            .frame(maxWidth: .infinity)
        }
    }
}
