import SwiftUI

struct FriendLedgerView: View {
    let friend: Friend
    @State private var expenses: [Expense] = []
    @State private var settlements: [Settlement] = []
    @State private var balance: Int = 0
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    private let api = APIClient.shared

    private var allEntries: [(id: String, date: String, view: AnyView)] {
        var entries: [(id: String, date: String, view: AnyView)] = []
        for expense in expenses {
            entries.append((
                id: expense.id,
                date: expense.createdAt,
                view: AnyView(expenseRow(expense))
            ))
        }
        for settlement in settlements {
            entries.append((
                id: settlement.id,
                date: settlement.createdAt,
                view: AnyView(settlementRow(settlement))
            ))
        }
        return entries.sorted { $0.date > $1.date }
    }

    private var groupedEntries: [(key: String, entries: [(id: String, date: String, view: AnyView)])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        let grouped = Dictionary(grouping: allEntries) { entry -> String in
            if let date = ISO8601DateFormatter().date(from: entry.date) {
                return formatter.string(from: date).uppercased()
            }
            return "UNKNOWN"
        }
        return grouped.sorted { $0.key > $1.key }.map { (key: $0.key, entries: $0.value) }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    ledgerHeader
                    contentCard
                }
            }
        }
        .navigationBarHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task { await loadData() }
    }

    // MARK: - Header

    private var ledgerHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Nav bar
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
                Button(action: {}) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.trailing, 8)
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
            }

            // Friend info
            HStack(spacing: 14) {
                friendAvatar(size: 56)
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.displayName)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                    if let phone = friend.phone, !phone.isEmpty {
                        Text(phone)
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                }
            }

            // Balance
            HStack(spacing: 8) {
                Text(balance > 0 ? "Owes you" : balance < 0 ? "You owe" : "Settled up")
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.6))
                Text(formatAmount(abs(balance)))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(balance >= 0 ? SplitEZTheme.positive : SplitEZTheme.negative)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: {}) {
                    Text("Send reminder")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(SplitEZTheme.primary)
                        )
                }
                Button(action: {}) {
                    Text("Settle up")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(SplitEZTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color(.systemBackground))
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(SplitEZTheme.darkBg)
    }

    // MARK: - Content

    private var contentCard: some View {
        VStack(spacing: 0) {
            // Shared expenses header
            HStack {
                Text("Shared expenses")
                    .font(.headline)
                    .foregroundColor(SplitEZTheme.textPrimary)
                Spacer()
                Button(action: {}) {
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
            .padding(.top, 20)
            .padding(.bottom, 12)

            if allEntries.isEmpty && !isLoading {
                Text("No shared expenses yet")
                    .font(.subheadline)
                    .foregroundColor(SplitEZTheme.textTertiary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 40)
            } else {
                ForEach(groupedEntries, id: \.key) { group in
                    // Date header
                    Text(group.key)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(SplitEZTheme.primary)
                        .tracking(0.5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    ForEach(Array(group.entries.enumerated()), id: \.element.id) { index, entry in
                        if index > 0 {
                            Divider().padding(.leading, 72)
                        }
                        entry.view
                    }
                }
            }

            // Net balance
            if !allEntries.isEmpty {
                Divider().padding(.top, 12)
                HStack {
                    Text("Net balance")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(SplitEZTheme.textPrimary)
                    Spacer()
                    Text(formatAmount(abs(balance)))
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(balance >= 0 ? SplitEZTheme.positive : SplitEZTheme.negative)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }

            Spacer().frame(height: 80)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .offset(y: -16)
    }

    // MARK: - Expense Row

    private func expenseRow(_ expense: Expense) -> some View {
        HStack(spacing: 12) {
            let icon = iconForCategory(expense.category)
            Image(systemName: icon.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(icon.color)
                .frame(width: 40, height: 40)
                .background(icon.color.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.description)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(SplitEZTheme.textPrimary)
                Text(expenseSubtitle(expense))
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.textSecondary)
            }

            Spacer()

            let myShare = expenseShareAmount(expense)
            VStack(alignment: .trailing, spacing: 2) {
                Text(myShare > 0 ? "owes you" : "you owe")
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.textSecondary)
                Text(formatAmount(abs(myShare)))
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(myShare > 0 ? SplitEZTheme.positive : SplitEZTheme.negative)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func expenseSubtitle(_ expense: Expense) -> String {
        let payer = expense.paidBy?.displayName ?? "Someone"
        let splitCount = expense.splits?.count ?? 0
        return "\(payer) paid \(expense.amountFormatted) · split \(splitCount) ways"
    }

    private func expenseShareAmount(_ expense: Expense) -> Int {
        if let split = expense.splits?.first(where: { $0.userId == friend.id }) {
            return split.shareAmount
        }
        return expense.amount / max(expense.splits?.count ?? 1, 1)
    }

    // MARK: - Settlement Row

    private func settlementRow(_ settlement: Settlement) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.up")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(SplitEZTheme.positive)
                .frame(width: 40, height: 40)
                .background(SplitEZTheme.positive.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("\(friend.displayName) paid you back")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(SplitEZTheme.textPrimary)
                Text(settlementSubtitle(settlement))
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("received")
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.textSecondary)
                Text("– \(settlement.amountFormatted)")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(SplitEZTheme.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func settlementSubtitle(_ settlement: Settlement) -> String {
        var parts: [String] = []
        parts.append("UPI")
        if settlement.status == "partial" {
            parts.append("settled partly")
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Helpers

    @ViewBuilder
    private func friendAvatar(size: CGFloat) -> some View {
        if let avatar = friend.avatar {
            Circle()
                .fill(Color(hex: avatar.backgroundColor))
                .frame(width: size, height: size)
                .overlay(
                    Text(avatar.initials)
                        .font(.system(size: size * 0.38, weight: .bold))
                        .foregroundColor(.white)
                )
        } else {
            Circle()
                .fill(SplitEZTheme.positive)
                .frame(width: size, height: size)
                .overlay(
                    Text(friend.firstName.prefix(1).uppercased() + (friend.lastName?.prefix(1).uppercased() ?? ""))
                        .font(.system(size: size * 0.38, weight: .bold))
                        .foregroundColor(.white)
                )
        }
    }

    private func iconForCategory(_ category: String?) -> (name: String, color: Color) {
        switch category?.lowercased() {
        case "food", "dining": return ("fork.knife", .orange)
        case "transport", "travel", "cab": return ("car.fill", Color(hex: "6366F1"))
        case "shopping": return ("bag.fill", .pink)
        case "entertainment": return ("tv.fill", .purple)
        case "utilities": return ("bolt.fill", .yellow)
        default: return ("fork.knife", .orange)
        }
    }

    private func loadData() async {
        isLoading = true
        async let e: [Expense] = (try? api.get("/expenses", query: ["friendId": friend.id])) ?? []
        async let s: [Settlement] = (try? api.get("/settlements", query: ["friendId": friend.id])) ?? []
        async let b: [Balance] = (try? api.get("/balances", query: ["friendId": friend.id])) ?? []
        expenses = await e
        settlements = await s
        let balances = await b
        balance = balances.first?.amount ?? 0
        isLoading = false
    }
}
