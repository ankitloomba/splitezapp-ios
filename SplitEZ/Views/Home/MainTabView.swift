import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            GroupsListView()
                .tabItem {
                    Label("Groups", systemImage: "person.3.fill")
                }
                .tag(1)

            TripsListView()
                .tabItem {
                    Label("Trips", systemImage: "airplane")
                }
                .tag(2)

            FinancesView()
                .tabItem {
                    Label("Finances", systemImage: "chart.bar.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("More", systemImage: "ellipsis")
                }
                .tag(4)
        }
        .tint(SplitEZTheme.primary)
    }
}
