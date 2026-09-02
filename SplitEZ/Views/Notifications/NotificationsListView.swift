import SwiftUI

struct NotificationsListView: View {
    @State private var notifications: [AppNotification] = []
    @State private var unreadCount = 0
    private let api = APIClient.shared

    var body: some View {
        List {
            ForEach(notifications) { n in
                HStack {
                    Circle()
                        .fill(n.isRead ? Color.clear : SplitEZTheme.primary)
                        .frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(n.title).font(.subheadline.bold())
                        Text(n.body).font(.caption).foregroundColor(.secondary)
                        Text(String(n.createdAt.prefix(10)))
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }
                .onTapGesture {
                    Task {
                        let _: SuccessResponse? = try? await api.patch("/notifications/\(n.id)/read")
                        await load()
                    }
                }
            }
        }
        .overlay {
            if notifications.isEmpty {
                ContentUnavailableView("No Notifications", systemImage: "bell.slash")
            }
        }
        .navigationTitle("Notifications")
        .toolbar {
            if unreadCount > 0 {
                Button("Read All") {
                    Task {
                        let _: SuccessResponse? = try? await api.patch("/notifications/read-all")
                        await load()
                    }
                }
            }
        }
        .refreshable { await load() }
        .task { await load() }
    }

    private func load() async {
        let resp: NotificationListResponse? = try? await api.get("/notifications")
        notifications = resp?.items ?? []
        unreadCount = resp?.unreadCount ?? 0
    }
}
