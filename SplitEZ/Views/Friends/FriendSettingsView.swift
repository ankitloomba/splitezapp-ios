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
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .foregroundColor(SplitEZTheme.primary.opacity(0.6))
                        .frame(width: 68, height: 68)
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
            ZStack(alignment: .trailing) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Get SplitEZ Ad Free")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("No ads · priority support · exports")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 80)

                Text("₹99/mo")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.75, blue: 0.3), Color(red: 0.85, green: 0.65, blue: 0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.3, green: 0.25, blue: 0.7),
                                Color(red: 0.45, green: 0.35, blue: 0.85)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
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

                ForEach(Array(commonGroups.enumerated()), id: \.element.id) { index, group in
                    NavigationLink(destination: EmptyView()) {
                        groupRow(group)
                    }
                    .buttonStyle(.plain)
                    if index < commonGroups.count - 1 {
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

    private static let groupStyles: [(icon: String, color: Color)] = [
        ("house", Color(hex: "6366F1")),
        ("clock", Color(hex: "F59E0B")),
        ("person.3", Color(hex: "16A34A")),
        ("fork.knife", Color(hex: "F87171")),
        ("suitcase", Color(hex: "8B5CF6")),
        ("cart", Color(hex: "0EA5E9")),
    ]

    private func groupRow(_ group: ExpenseGroup) -> some View {
        let styleIndex = abs(group.name.hashValue) % Self.groupStyles.count
        let style = Self.groupStyles[styleIndex]
        return HStack(spacing: 14) {
            Image(systemName: style.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(style.color)
                .frame(width: 40, height: 40)
                .background(style.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
