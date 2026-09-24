import Foundation
import SwiftUI

@MainActor
class ExpenseStore: ObservableObject {
    static let shared = ExpenseStore()

    @Published var expenses: [Expense] = []
    @Published var balances: [Balance] = []
    @Published var activities: [Activity] = []

    private let api = APIClient.shared

    private init() {
        expenses = SampleData.recentExpenses
        balances = SampleData.balances
        activities = SampleData.activities
    }

    func reload() async {
        let fetchedExpenses: [Expense] = (try? await api.get("/expenses")) ?? []
        let fetchedBalances: [Balance] = (try? await api.get("/balances")) ?? []
        let fetchedActivities: [Activity] = (try? await api.get("/activities")) ?? []

        if !fetchedExpenses.isEmpty { expenses = fetchedExpenses }
        if !fetchedBalances.isEmpty { balances = fetchedBalances }
        if !fetchedActivities.isEmpty { activities = fetchedActivities }
    }

    func updateExpense(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
        }
    }

    func addExpense(_ expense: Expense) {
        expenses.insert(expense, at: 0)

        // Update balances based on the new expense
        let participantIds = expense.splits?.compactMap(\.userId) ?? []
        let paidById = expense.paidBy?.id ?? SampleData.currentUser.id
        let splitCount = max(participantIds.count, 1)
        let perPersonShare = expense.amount / splitCount

        for pid in participantIds {
            if pid == paidById { continue }
            // paidBy is owed money by each participant
            if paidById == SampleData.currentUser.id {
                // Current user paid — others owe us
                updateBalance(userId: pid, delta: perPersonShare)
            } else if pid == SampleData.currentUser.id {
                // Someone else paid — we owe them
                updateBalance(userId: paidById, delta: -perPersonShare)
            }
        }

        // Add activity
        let activity = Activity(
            id: "a_\(UUID().uuidString.prefix(8))",
            type: "expense_created",
            entityType: "expense",
            entityId: expense.id,
            metadata: [
                "description": AnyCodable(expense.description),
                "amount": AnyCodable(expense.amount),
                "groupName": AnyCodable(groupName(for: expense.groupId))
            ],
            user: SampleData.currentUser,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        activities.insert(activity, at: 0)
    }

    func balanceForUser(_ userId: String) -> Int {
        balances.first(where: { $0.userId == userId })?.amount ?? 0
    }

    func recordSettlement(friendId: String, amount: Int, method: String) {
        // Reduce balance toward zero
        if let index = balances.firstIndex(where: { $0.userId == friendId }) {
            let old = balances[index]
            let newAmount: Int
            if old.amount > 0 {
                newAmount = max(0, old.amount - amount)
            } else {
                newAmount = min(0, old.amount + amount)
            }
            balances[index] = Balance(userId: old.userId, user: old.user, amount: newAmount)
        }

        let activity = Activity(
            id: "a_\(UUID().uuidString.prefix(8))",
            type: "settlement_created",
            entityType: "settlement",
            entityId: "s_\(UUID().uuidString.prefix(8))",
            metadata: [
                "amount": AnyCodable(amount),
                "method": AnyCodable(method)
            ],
            user: SampleData.currentUser,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        activities.insert(activity, at: 0)
    }

    private func updateBalance(userId: String, delta: Int) {
        if let index = balances.firstIndex(where: { $0.userId == userId }) {
            let old = balances[index]
            balances[index] = Balance(
                userId: old.userId,
                user: old.user,
                amount: old.amount + delta
            )
        }
    }

    private func groupName(for groupId: String?) -> String {
        guard let gid = groupId else { return "" }
        return SampleData.groups.first(where: { $0.id == gid })?.name ?? ""
    }
}
