import SwiftUI

struct FriendSettingsView: View {
    let friend: Friend
    @Environment(\.dismiss) var dismiss
    @State private var showRemoveConfirm = false
    @State private var showBlockConfirm = false

    private var commonGroups: [ExpenseGroup] {
        SampleData.groups.filter { group in
            group.members?.contains(where: { $0.id == friend.id }) == true
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                SplitEZTheme.darkBg.frame(height: 200)
                Color(.systemBackground)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    header
                    content
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Remove \(friend.firstName)?", isPresented: $showRemoveConfirm) {
            Button("Remove", role: .destructive) { dismiss() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove \(friend.firstName) from your friends list. You can add them back later.")
        }
        .alert("Block \(friend.firstName)?", isPresented: $showBlockConfirm) {
            Button("Block", role: .destructive) { dismiss() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Blocked users cannot see your profile or send you friend requests.")
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            // Nav bar
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("Friend Settings")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Color.clear.frame(width: 28)
            }

            // Friend info
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(avatarColor(for: friend.firstName))
                        .frame(width: 56, height: 56)
                    Text(initials(for: friend))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.displayName)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                    if let phone = friend.phone {
                        Text(phone)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }

    private var content: some View {
        VStack(spacing: 0) {
            // Ad-free upgrade card
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Go Ad-Free")
                        .font(.subheadline.weight(.semibold))
                    Text("Remove ads · ₹99/mo")
                        .font(.caption)
                        .foregroundColor(SplitEZTheme.textSecondary)
                }
                Spacer()
                Button("Upgrade") {}
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(SplitEZTheme.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(SplitEZTheme.primary, lineWidth: 1.5)
                    )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.orange.opacity(0.08))
            )
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            // Actions
            sectionLabel("ACTIONS")

            actionRow(icon: "person.crop.circle.badge.minus", title: "Remove \(friend.firstName) from list", color: SplitEZTheme.negative) {
                showRemoveConfirm = true
            }
            rowDivider
            actionRow(icon: "hand.raised", title: "Block \(friend.firstName)", color: SplitEZTheme.negative) {
                showBlockConfirm = true
            }
            rowDivider
            actionRow(icon: "exclamationmark.triangle", title: "Report \(friend.firstName)", color: SplitEZTheme.negative) {
            }

            // Groups in common
            if !commonGroups.isEmpty {
                sectionLabel("GROUPS IN COMMON")

                ForEach(commonGroups, id: \.id) { group in
                    NavigationLink(destination: EmptyView()) {
                        groupRow(group)
                    }
                    .buttonStyle(.plain)
                    if group.id != commonGroups.last?.id {
                        rowDivider
                    }
                }
            }

            Spacer().frame(height: 40)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }

    private func actionRow(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .frame(width: 22)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(color)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(SplitEZTheme.textTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
    }

    private func groupRow(_ group: ExpenseGroup) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(SplitEZTheme.primary.opacity(0.12))
                    .frame(width: 40, height: 40)
                Text("🏠")
                    .font(.system(size: 18))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.subheadline.weight(.medium))
                if let count = group.memberCount {
                    Text("\(count) member\(count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(SplitEZTheme.textSecondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(SplitEZTheme.textTertiary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundColor(SplitEZTheme.primary)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }

    private var rowDivider: some View {
        Divider().padding(.leading, 56)
    }

    private func initials(for friend: Friend) -> String {
        let first = friend.firstName.prefix(1).uppercased()
        let last = (friend.lastName ?? "").prefix(1).uppercased()
        return first + last
    }

    private func avatarColor(for name: String) -> Color {
        let colors: [Color] = [.red, .orange, .green, .blue, .purple, .pink, .teal]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }
}
