import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            GroupsListView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Groups")
                }
                .tag(1)

            TripsListView()
                .tabItem {
                    Image(systemName: "airplane")
                    Text("Trips")
                }
                .tag(2)

            FinancesView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Finances")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Image(systemName: "ellipsis")
                    Text("More")
                }
                .tag(4)
        }
        .tint(SplitEZTheme.primary)
        .onChange(of: selectedTab) { _, tab in
            let screens = ["home", "groups", "trips", "finances", "settings"]
            Task { await AnalyticsTracker.shared.trackScreen(screens[tab]) }
        }
        .task {
            await AnalyticsTracker.shared.startSession()
            await AnalyticsTracker.shared.trackScreen("home")
        }
    }
}
