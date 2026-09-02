import Foundation

// MARK: - Auth
struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let user: UserSummary?
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String?
    let phone: String?
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RefreshRequest: Codable {
    let refreshToken: String
}

struct VerifyEmailRequest: Codable {
    let token: String
}

struct ForgotPasswordRequest: Codable {
    let email: String
}

struct ResetPasswordRequest: Codable {
    let token: String
    let password: String
}

// MARK: - Users
struct UserSummary: Codable, Identifiable, Hashable {
    let id: String
    let firstName: String
    let lastName: String?
    let profilePicture: String?
    let avatar: AvatarData?

    var displayName: String {
        [firstName, lastName].compactMap { $0 }.joined(separator: " ")
    }
}

struct AvatarData: Codable, Hashable {
    let initials: String
    let backgroundColor: String
}

struct UserProfile: Codable, Identifiable {
    let id: String
    let email: String?
    let phone: String?
    let firstName: String
    let lastName: String?
    let profilePicture: String?
    let avatar: AvatarData?
    let currency: String
    let createdAt: String

    var displayName: String {
        [firstName, lastName].compactMap { $0 }.joined(separator: " ")
    }
}

struct UpdateUserRequest: Codable {
    var firstName: String?
    var lastName: String?
    var currency: String?
    var profilePicture: String?
}

// MARK: - Groups
struct Group: Codable, Identifiable {
    let id: String
    let name: String
    let image: String?
    let description: String?
    let memberCount: Int?
    let members: [UserSummary]?
    let createdAt: String
}

struct CreateGroupRequest: Codable {
    let name: String
    var description: String?
    var image: String?
    var memberIds: [String]?
}

// MARK: - Trips
struct Trip: Codable, Identifiable {
    let id: String
    let name: String
    let destination: String?
    let startDate: String?
    let endDate: String?
    let image: String?
    let memberCount: Int?
    let members: [UserSummary]?
    let createdAt: String
}

struct CreateTripRequest: Codable {
    let name: String
    var destination: String?
    var startDate: String?
    var endDate: String?
    var image: String?
    var memberIds: [String]?
}

// MARK: - Expenses
struct Expense: Codable, Identifiable {
    let id: String
    let description: String
    let amount: Int
    let currency: String
    let splitMethod: String
    let category: String?
    let note: String?
    let date: String
    let paidBy: UserSummary?
    let createdBy: UserSummary?
    let splits: [ExpenseSplit]?
    let groupId: String?
    let tripId: String?
    let idempotencyKey: String?
    let createdAt: String

    var amountFormatted: String {
        formatAmount(amount, currency: currency)
    }
}

struct ExpenseSplit: Codable {
    let userId: String?
    let user: UserSummary?
    let shareAmount: Int
    let percentageBps: Int?
}

struct SplitParticipant: Codable {
    let userId: String
    var shareAmount: Int?
    var percentageBps: Int?
}

struct CreateExpenseRequest: Codable {
    let description: String
    let amount: Int
    var currency: String?
    var splitMethod: String?
    var category: String?
    var note: String?
    var date: String?
    var paidById: String?
    var groupId: String?
    var tripId: String?
    var participants: [SplitParticipant]
    var idempotencyKey: String?
}

// MARK: - Balances
struct Balance: Codable {
    let userId: String
    let user: UserSummary?
    let amount: Int
}

struct SimplifiedDebt: Codable {
    let from: UserSummary
    let to: UserSummary
    let amount: Int
}

// MARK: - Settlements
struct Settlement: Codable, Identifiable {
    let id: String
    let amount: Int
    let currency: String
    let status: String
    let groupId: String?
    let note: String?
    let idempotencyKey: String?
    let from: UserSummary?
    let to: UserSummary?
    let createdAt: String
    let updatedAt: String?

    var amountFormatted: String {
        formatAmount(amount, currency: currency)
    }
}

struct CreateSettlementRequest: Codable {
    let toId: String
    let amount: Int
    var currency: String?
    var groupId: String?
    var note: String?
    var idempotencyKey: String?
}

// MARK: - Activity
struct Activity: Codable, Identifiable {
    let id: String
    let type: String
    let entityType: String?
    let entityId: String?
    let metadata: [String: AnyCodable]?
    let user: UserSummary?
    let createdAt: String
}

// MARK: - Notifications
struct AppNotification: Codable, Identifiable {
    let id: String
    let title: String
    let body: String
    let type: String
    let data: [String: AnyCodable]?
    let isRead: Bool
    let createdAt: String
}

struct NotificationListResponse: Codable {
    let items: [AppNotification]
    let nextCursor: String?
    let unreadCount: Int
}

struct RegisterDeviceRequest: Codable {
    let token: String
    let platform: String
}

// MARK: - Finances
struct Income: Codable, Identifiable {
    let id: String
    let amount: Int
    let type: String
    let date: String
    let note: String?
    let createdAt: String?
}

struct CreateIncomeRequest: Codable {
    let amount: Int
    let type: String
    var date: String?
    var note: String?
}

struct PersonalExpense: Codable, Identifiable {
    let id: String
    let amount: Int
    let description: String
    let category: String?
    let date: String
    let note: String?
    let createdAt: String?
}

struct CreatePersonalExpenseRequest: Codable {
    let amount: Int
    let description: String
    var category: String?
    var date: String?
    var note: String?
}

struct FinancialSummary: Codable {
    let totalIncome: Int
    let totalExpenses: Int
    let netSavings: Int
    let month: String?
}

// MARK: - Categories
struct Category: Codable, Identifiable {
    let id: String
    let name: String
    let icon: String?
    let isSystem: Bool
}

// MARK: - Promos
struct PromotionalBanner: Codable, Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let image: String?
    let cta: String?
    let destination: String?
    let targetScreen: String
    let priority: Int
}

// MARK: - Dashboard Elements
struct DashboardElement: Codable, Identifiable {
    let id: String
    let type: String        // greeting | banner | card | announcement | tip | spotlight
    let title: String?
    let subtitle: String?
    let body: String?
    let image: String?
    let cta: String?
    let destination: String?
    let targetScreen: String
    let position: Int
    let config: [String: AnyCodable]?
    let startDate: String?
    let endDate: String?
    let status: String
}

// MARK: - Generic
struct SuccessResponse: Codable {
    let success: Bool
}

struct PaginatedResponse<T: Codable>: Codable {
    let items: [T]
    let nextCursor: String?
}

// MARK: - Helpers
struct AnyCodable: Codable, Hashable {
    let value: Any

    init(_ value: Any) { self.value = value }
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) { value = s }
        else if let i = try? container.decode(Int.self) { value = i }
        else if let d = try? container.decode(Double.self) { value = d }
        else if let b = try? container.decode(Bool.self) { value = b }
        else { value = "" }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let s = value as? String { try container.encode(s) }
        else if let i = value as? Int { try container.encode(i) }
        else if let d = value as? Double { try container.encode(d) }
        else if let b = value as? Bool { try container.encode(b) }
    }
    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        String(describing: lhs.value) == String(describing: rhs.value)
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(String(describing: value))
    }
}

func formatAmount(_ minorUnits: Int, currency: String = "INR") -> String {
    let major = Double(minorUnits) / 100.0
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency
    return formatter.string(from: NSNumber(value: major)) ?? "\(currency) \(major)"
}
