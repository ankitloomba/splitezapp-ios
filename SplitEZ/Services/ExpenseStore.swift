import Foundation
import SwiftUI

@MainActor
class ExpenseStore: ObservableObject {
    static let shared = ExpenseStore()

    @Published var expenses: [Expense] = []
    @Published var balances: [Balance] = []
    @Published var activities: [Activity] = []

    private let api = APIClient.shared
    private init() {}

    // MARK: - Current user helper
    var currentUserSummary: UserSummary? {
        guard let u = AuthService.shared.currentUser else { return nil }
        return UserSummary(id: u.id, firstName: u.firstName, lastName: u.lastName,
                           phone: u.phone, profilePicture: u.profilePicture, avatar: u.avatar)
    }

    // MARK: - Reload from API
    func reload() async {
        async let fe: [Expense] = (try? await api.get("/expenses")) ?? []
        async let fb: [Balance] = (try? await api.get("/balances")) ?? []
        let (fetchedExpenses, fetchedBalances) = await (fe, fb)

        if !fetchedExpenses.isEmpty { expenses = fetchedExpenses }
        if !fetchedBalances.isEmpty { balances = fetchedBalances }

        // Activity feed
        struct FeedPage: Codable { let data: [Activity] }
        if let page: FeedPage = try? await api.get("/activity/feed") {
            if !page.data.isEmpty { activities = page.data }
        }
    }

    // MARK: - Expense mutations
    func updateExpense(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
        }
    }

    func addExpense(_ expense: Expense) {
        expenses.insert(expense, at: 0)
        // Reload balances and activity from server to stay in sync
        Task { await reload() }
    }

    // MARK: - Balance helpers
    func balanceForUser(_ userId: String) -> Int {
        balances.first(where: { $0.userId == userId })?.amount ?? 0
    }

    // MARK: - Settlement
    func recordSettlement(friendId: String, amount: Int, method: String) async {
        let _: SuccessResponse? = try? await api.post(
            "/settlements",
            body: CreateSettlementRequest(toUserId: friendId, amount: amount, note: method)
        )
        await reload()
    }
}
