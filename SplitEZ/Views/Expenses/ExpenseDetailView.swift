import SwiftUI

struct ExpenseDetailView: View {
    let expense: Expense
    @Environment(\.dismiss) var dismiss

    private var groupName: String {
        guard let gid = expense.groupId else { return "" }
        return SampleData.groups.first(where: { $0.id == gid })?.name ?? ""
    }

    private var categoryIcon: (name: String, color: Color) {
        switch expense.category?.lowercased() {
        case "food": return ("fork.knife", .orange)
        case "transport": return ("car.fill", .blue)
        case "groceries": return ("cart.fill", .green)
        case "utilities": return ("bolt.fill", .yellow)
        case "entertainment": return ("film", .purple)
        case "shopping": return ("bag.fill", .pink)
        default: return ("creditcard", .gray)
        }
    }

    private var formattedDate: String {
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: expense.createdAt) {
            let fmt = DateFormatter()
            fmt.dateFormat = "d MMMM yyyy, h:mm a"
            return fmt.string(from: date)
        }
        return expense.date
    }

    private var splitMethodLabel: String {
        switch expense.splitMethod.uppercased() {
        case "EQUAL": return "Split equally"
        case "EXACT": return "Split by exact amounts"
        case "PERCENTAGE": return "Split by percentage"
        default: return expense.splitMethod
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    header
                    detailCard
                }
            }
        }
        .navigationBarHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("Expense")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Color.clear.frame(width: 24)
            }
            .padding(.horizontal, 20)

            // Amount
            VStack(spacing: 6) {
                let icon = categoryIcon
                Image(systemName: icon.name)
                    .font(.system(size: 28))
                    .foregroundColor(icon.color)
                    .frame(width: 56, height: 56)
                    .background(icon.color.opacity(0.15))
                    .clipShape(Circle())

                Text(expense.description)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(expense.amountFormatted)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .monospacedDigit()

                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.textTertiary)
            }
        }
        .padding(.bottom, 28)
        .background(SplitEZTheme.darkBg)
    }

    // MARK: - Detail Card

    private var detailCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Paid by
            detailRow(label: "Paid by", value: expense.paidBy?.displayName ?? "Unknown")
            Divider().padding(.leading, 20)

            // Group
            if !groupName.isEmpty {
                detailRow(label: "Group", value: groupName)
                Divider().padding(.leading, 20)
            }

            // Category
            if let cat = expense.category, !cat.isEmpty {
                detailRow(label: "Category", value: cat.capitalized)
                Divider().padding(.leading, 20)
            }

            // Split method
            detailRow(label: "Split method", value: splitMethodLabel)
            Divider().padding(.leading, 20)

            // Note
            if let note = expense.note, !note.isEmpty {
                detailRow(label: "Note", value: note)
                Divider().padding(.leading, 20)
            }

            // Split breakdown
            if let splits = expense.splits, !splits.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Split breakdown")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(SplitEZTheme.textPrimary)
                        .padding(.top, 16)

                    ForEach(Array(splits.enumerated()), id: \.offset) { _, split in
                        HStack(spacing: 12) {
                            if let user = split.user {
                                AvatarView(user: user, size: 32)
                            } else {
                                Circle()
                                    .fill(SplitEZTheme.pillInactive)
                                    .frame(width: 32, height: 32)
                            }
                            Text(split.user?.displayName ?? "Unknown")
                                .font(.subheadline)
                                .foregroundColor(SplitEZTheme.textPrimary)
                            Spacer()
                            Text(formatAmount(split.shareAmount, currency: expense.currency))
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(SplitEZTheme.textPrimary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            } else {
                // No splits data — show equal split estimate
                let splitCount = max((expense.splits?.count ?? 2), 2)
                let perPerson = expense.amount / splitCount
                detailRow(label: "Per person (est.)", value: formatAmount(perPerson, currency: expense.currency))
            }

            // Created by
            if let creator = expense.createdBy {
                Divider().padding(.leading, 20)
                detailRow(label: "Added by", value: creator.displayName)
            }

            Spacer().frame(height: 40)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .offset(y: -16)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(SplitEZTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(SplitEZTheme.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
