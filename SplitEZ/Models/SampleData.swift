import Foundation

enum SampleData {

    // MARK: - Users

    static let currentUser = UserSummary(
        id: "u_me",
        firstName: "Ankit",
        lastName: "Loomba",
        phone: "+91 98765 43210",
        profilePicture: nil,
        avatar: AvatarData(initials: "AL", backgroundColor: "6366F1")
    )

    static let rahul = UserSummary(
        id: "u_rahul",
        firstName: "Rahul",
        lastName: "Sharma",
        phone: "+91 99887 76543",
        profilePicture: nil,
        avatar: AvatarData(initials: "RS", backgroundColor: "F59E0B")
    )

    static let anita = UserSummary(
        id: "u_anita",
        firstName: "Anita",
        lastName: "Verma",
        phone: "+91 88776 65432",
        profilePicture: nil,
        avatar: AvatarData(initials: "AV", backgroundColor: "EC4899")
    )

    static let priya = UserSummary(
        id: "u_priya",
        firstName: "Priya",
        lastName: "Patel",
        phone: "+91 77665 54321",
        profilePicture: nil,
        avatar: AvatarData(initials: "PP", backgroundColor: "16A34A")
    )

    static let sanjay = UserSummary(
        id: "u_sanjay",
        firstName: "Sanjay",
        lastName: "Kumar",
        phone: "+91 95544 33210",
        profilePicture: nil,
        avatar: AvatarData(initials: "SK", backgroundColor: "0EA5E9")
    )

    static let neha = UserSummary(
        id: "u_neha",
        firstName: "Neha",
        lastName: "Gupta",
        phone: "+91 91234 56789",
        profilePicture: nil,
        avatar: AvatarData(initials: "NG", backgroundColor: "8B5CF6")
    )

    static let vikram = UserSummary(
        id: "u_vikram",
        firstName: "Vikram",
        lastName: "Singh",
        phone: "+91 93456 78901",
        profilePicture: nil,
        avatar: AvatarData(initials: "VS", backgroundColor: "F87171")
    )

    static let deepa = UserSummary(
        id: "u_deepa",
        firstName: "Deepa",
        lastName: "Nair",
        phone: "+91 96789 01234",
        profilePicture: nil,
        avatar: AvatarData(initials: "DN", backgroundColor: "14B8A6")
    )

    // MARK: - Groups

    static let groups: [ExpenseGroup] = [
        ExpenseGroup(
            id: "g_flat402",
            name: "Flat 402",
            image: nil,
            description: "Monthly household expenses",
            memberCount: 4,
            members: [currentUser, rahul, anita, sanjay],
            createdAt: "2025-01-15T10:00:00Z"
        ),
        ExpenseGroup(
            id: "g_goatrip",
            name: "Goa Trip 2025",
            image: nil,
            description: "Beach vacation with friends",
            memberCount: 6,
            members: [currentUser, rahul, priya, neha, vikram, deepa],
            createdAt: "2025-03-20T08:30:00Z"
        ),
        ExpenseGroup(
            id: "g_officelunch",
            name: "Office Lunch Crew",
            image: nil,
            description: "Daily office lunch splits",
            memberCount: 5,
            members: [currentUser, sanjay, neha, vikram, anita],
            createdAt: "2025-02-10T12:00:00Z"
        ),
        ExpenseGroup(
            id: "g_weekendfoodies",
            name: "Weekend Foodies",
            image: nil,
            description: "Weekend restaurant and food adventures",
            memberCount: 4,
            members: [currentUser, priya, rahul, deepa],
            createdAt: "2025-04-05T18:00:00Z"
        ),
        ExpenseGroup(
            id: "g_roadtrip",
            name: "Mumbai Road Trip",
            image: nil,
            description: "Road trip expenses",
            memberCount: 3,
            members: [currentUser, vikram, sanjay],
            createdAt: "2025-06-01T07:00:00Z"
        ),
    ]

    // MARK: - Trips

    static let trips: [Trip] = [
        Trip(
            id: "t_manali",
            name: "Manali Adventure",
            destination: "Manali, Himachal Pradesh",
            startDate: "2025-12-20",
            endDate: "2025-12-26",
            image: nil,
            memberCount: 5,
            members: [currentUser, rahul, priya, anita, vikram],
            createdAt: "2025-11-01T10:00:00Z"
        ),
        Trip(
            id: "t_kerala",
            name: "Kerala Backwaters",
            destination: "Alleppey, Kerala",
            startDate: "2026-01-10",
            endDate: "2026-01-15",
            image: nil,
            memberCount: 4,
            members: [currentUser, deepa, neha, sanjay],
            createdAt: "2025-12-01T14:00:00Z"
        ),
    ]

    // MARK: - Balances (friend-level, amounts in paise)

    static let balances: [Balance] = [
        Balance(userId: "u_rahul", user: rahul, amount: 145000),
        Balance(userId: "u_priya", user: priya, amount: -32000),
        Balance(userId: "u_anita", user: anita, amount: 78500),
        Balance(userId: "u_sanjay", user: sanjay, amount: -15000),
        Balance(userId: "u_neha", user: neha, amount: 0),
        Balance(userId: "u_vikram", user: vikram, amount: 52000),
        Balance(userId: "u_deepa", user: deepa, amount: -9500),
    ]

    // MARK: - Group balances (amounts in paise)

    static let groupBalances: [String: Int] = [
        "g_flat402": 85000,
        "g_goatrip": -32000,
        "g_officelunch": 12500,
        "g_weekendfoodies": 45000,
        "g_roadtrip": -8000,
    ]

    // MARK: - Friends

    static let friends: [Friend] = [
        Friend(id: "u_rahul", firstName: "Rahul", lastName: "Sharma", phone: "+91 99887 76543", email: "rahul.sharma@gmail.com", profilePicture: nil, avatar: AvatarData(initials: "RS", backgroundColor: "F59E0B"), isRegistered: true, groupCount: 3, lastActiveAt: "2026-09-16T14:30:00Z"),
        Friend(id: "u_anita", firstName: "Anita", lastName: "Verma", phone: "+91 88776 65432", email: "anita.verma@gmail.com", profilePicture: nil, avatar: AvatarData(initials: "AV", backgroundColor: "EC4899"), isRegistered: true, groupCount: 2, lastActiveAt: "2026-09-17T09:15:00Z"),
        Friend(id: "u_priya", firstName: "Priya", lastName: "Patel", phone: "+91 77665 54321", email: "priya.patel@gmail.com", profilePicture: nil, avatar: AvatarData(initials: "PP", backgroundColor: "16A34A"), isRegistered: true, groupCount: 2, lastActiveAt: "2026-09-15T20:00:00Z"),
        Friend(id: "u_sanjay", firstName: "Sanjay", lastName: "Kumar", phone: "+91 95544 33210", email: "sanjay.k@gmail.com", profilePicture: nil, avatar: AvatarData(initials: "SK", backgroundColor: "0EA5E9"), isRegistered: true, groupCount: 2, lastActiveAt: "2026-09-16T11:00:00Z"),
        Friend(id: "u_neha", firstName: "Neha", lastName: "Gupta", phone: "+91 91234 56789", email: "neha.gupta@gmail.com", profilePicture: nil, avatar: AvatarData(initials: "NG", backgroundColor: "8B5CF6"), isRegistered: true, groupCount: 2, lastActiveAt: "2026-09-14T16:45:00Z"),
        Friend(id: "u_vikram", firstName: "Vikram", lastName: "Singh", phone: "+91 93456 78901", email: "vikram.s@gmail.com", profilePicture: nil, avatar: AvatarData(initials: "VS", backgroundColor: "F87171"), isRegistered: true, groupCount: 2, lastActiveAt: "2026-09-17T08:30:00Z"),
        Friend(id: "u_deepa", firstName: "Deepa", lastName: "Nair", phone: "+91 96789 01234", email: "deepa.nair@gmail.com", profilePicture: nil, avatar: AvatarData(initials: "DN", backgroundColor: "14B8A6"), isRegistered: true, groupCount: 1, lastActiveAt: "2026-09-13T22:00:00Z"),
    ]

    // MARK: - Recent Expenses

    static let recentExpenses: [Expense] = [
        Expense(id: "e1", description: "Grocery – Big Bazaar", amount: 235000, currency: "INR", splitMethod: "equal", category: "groceries", note: nil, date: "2026-09-17", paidBy: currentUser, createdBy: currentUser, splits: nil, groupId: "g_flat402", tripId: nil, idempotencyKey: nil, createdAt: "2026-09-17T10:30:00Z"),
        Expense(id: "e2", description: "Uber to Airport", amount: 85000, currency: "INR", splitMethod: "equal", category: "transport", note: nil, date: "2026-09-16", paidBy: rahul, createdBy: rahul, splits: nil, groupId: "g_goatrip", tripId: nil, idempotencyKey: nil, createdAt: "2026-09-16T06:00:00Z"),
        Expense(id: "e3", description: "Pizza Hut lunch", amount: 124000, currency: "INR", splitMethod: "equal", category: "food", note: "Friday treat", date: "2026-09-15", paidBy: currentUser, createdBy: currentUser, splits: nil, groupId: "g_officelunch", tripId: nil, idempotencyKey: nil, createdAt: "2026-09-15T13:00:00Z"),
        Expense(id: "e4", description: "Electricity bill – Sep", amount: 340000, currency: "INR", splitMethod: "equal", category: "utilities", note: nil, date: "2026-09-14", paidBy: anita, createdBy: anita, splits: nil, groupId: "g_flat402", tripId: nil, idempotencyKey: nil, createdAt: "2026-09-14T18:00:00Z"),
        Expense(id: "e5", description: "Café Mocha – Starbucks", amount: 45000, currency: "INR", splitMethod: "equal", category: "food", note: nil, date: "2026-09-13", paidBy: priya, createdBy: priya, splits: nil, groupId: "g_weekendfoodies", tripId: nil, idempotencyKey: nil, createdAt: "2026-09-13T16:30:00Z"),
        Expense(id: "e6", description: "Petrol – HP pump", amount: 200000, currency: "INR", splitMethod: "equal", category: "transport", note: "Full tank", date: "2026-09-12", paidBy: vikram, createdBy: vikram, splits: nil, groupId: "g_roadtrip", tripId: nil, idempotencyKey: nil, createdAt: "2026-09-12T09:00:00Z"),
    ]

    // MARK: - Activities

    static let activities: [Activity] = [
        Activity(id: "a1", type: "expense_created", entityType: "expense", entityId: "e1", metadata: ["description": AnyCodable("Grocery – Big Bazaar"), "amount": AnyCodable(2350), "groupName": AnyCodable("Flat 402")], user: currentUser, createdAt: "2026-09-17T10:30:00Z"),
        Activity(id: "a2", type: "expense_created", entityType: "expense", entityId: "e2", metadata: ["description": AnyCodable("Uber to Airport"), "amount": AnyCodable(850), "groupName": AnyCodable("Goa Trip 2025")], user: rahul, createdAt: "2026-09-16T06:00:00Z"),
        Activity(id: "a3", type: "settlement_created", entityType: "settlement", entityId: "s1", metadata: ["amount": AnyCodable(500), "toName": AnyCodable("Priya Patel")], user: currentUser, createdAt: "2026-09-16T14:00:00Z"),
        Activity(id: "a4", type: "expense_created", entityType: "expense", entityId: "e3", metadata: ["description": AnyCodable("Pizza Hut lunch"), "amount": AnyCodable(1240), "groupName": AnyCodable("Office Lunch Crew")], user: currentUser, createdAt: "2026-09-15T13:00:00Z"),
        Activity(id: "a5", type: "group_created", entityType: "group", entityId: "g_weekendfoodies", metadata: ["name": AnyCodable("Weekend Foodies")], user: priya, createdAt: "2026-09-15T09:00:00Z"),
        Activity(id: "a6", type: "expense_created", entityType: "expense", entityId: "e4", metadata: ["description": AnyCodable("Electricity bill – Sep"), "amount": AnyCodable(3400), "groupName": AnyCodable("Flat 402")], user: anita, createdAt: "2026-09-14T18:00:00Z"),
        Activity(id: "a7", type: "friend_added", entityType: "user", entityId: "u_deepa", metadata: ["name": AnyCodable("Deepa Nair")], user: deepa, createdAt: "2026-09-13T22:00:00Z"),
        Activity(id: "a8", type: "expense_created", entityType: "expense", entityId: "e5", metadata: ["description": AnyCodable("Café Mocha – Starbucks"), "amount": AnyCodable(450), "groupName": AnyCodable("Weekend Foodies")], user: priya, createdAt: "2026-09-13T16:30:00Z"),
    ]
}
