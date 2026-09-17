import SwiftUI

struct TripsListView: View {
    @State private var trips: [Trip] = []
    @State private var isLoading = true
    @State private var showCreate = false
    @Environment(\.dismiss) var dismiss
    private let api = APIClient.shared

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                SplitEZTheme.darkBg.frame(height: 120)
                Color(.systemBackground)
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Dark header
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Text("Trips")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Button { showCreate = true } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .background(SplitEZTheme.darkBg)

                    // Content card
                    VStack(spacing: 0) {
                        if trips.isEmpty && !isLoading {
                            VStack(spacing: 12) {
                                Image(systemName: "airplane")
                                    .font(.system(size: 40))
                                    .foregroundColor(SplitEZTheme.textTertiary)
                                Text("No Trips")
                                    .font(.headline)
                                    .foregroundColor(SplitEZTheme.textPrimary)
                                Text("Plan a trip and track expenses")
                                    .font(.subheadline)
                                    .foregroundColor(SplitEZTheme.textTertiary)
                            }
                            .padding(.vertical, 60)
                        } else {
                            ForEach(Array(trips.enumerated()), id: \.element.id) { index, trip in
                                if index > 0 {
                                    Divider().padding(.leading, 76)
                                }
                                NavigationLink(destination: TripDetailView(trip: trip)) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "paperplane.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.orange)
                                            .frame(width: 44, height: 44)
                                            .background(Color.orange.opacity(0.1))
                                            .clipShape(Circle())
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(trip.name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(SplitEZTheme.textPrimary)
                                            if let dest = trip.destination {
                                                Text("\(dest) · Trip")
                                                    .font(.caption)
                                                    .foregroundColor(SplitEZTheme.textSecondary)
                                            } else {
                                                Text("\(trip.members?.count ?? 0) people · Trip")
                                                    .font(.caption)
                                                    .foregroundColor(SplitEZTheme.textSecondary)
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(SplitEZTheme.textTertiary)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Spacer().frame(height: 80)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    .offset(y: -16)
                }
            }
        }
        .navigationBarHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showCreate) {
            CreateTripView { await loadTrips() }
        }
        .task { await loadTrips() }
    }

    private func loadTrips() async {
        isLoading = true
        trips = (try? await api.get("/trips")) ?? []
        if trips.isEmpty { trips = SampleData.trips }
        isLoading = false
    }
}

struct TripDetailView: View {
    let trip: Trip
    @State private var expenses: [Expense] = []
    @State private var balances: [Balance] = []
    @State private var showAddExpense = false
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    private let api = APIClient.shared

    private var totalSpend: Int {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var yourShare: Int {
        expenses.reduce(0) { total, expense in
            let splits = expense.splits ?? []
            let perPerson = splits.isEmpty ? expense.amount / max(memberNames.count, 1) : 0
            let myShare = splits.first(where: { $0.user?.firstName == "You" || $0.userId == nil })?.shareAmount ?? perPerson
            return total + myShare
        }
    }

    private var youAreOwed: Int {
        balances.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
    }

    private var memberNames: [String] {
        let members = trip.members ?? []
        if members.isEmpty { return ["You"] }
        return ["You"] + members.map { $0.firstName }
    }

    private var dateRange: String {
        guard let start = trip.startDate, let end = trip.endDate else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        if let s = fmt.date(from: String(start.prefix(10))),
           let e = fmt.date(from: String(end.prefix(10))) {
            let sFmt = DateFormatter()
            sFmt.dateFormat = "d"
            let eFmt = DateFormatter()
            eFmt.dateFormat = "d MMM"
            return "\(sFmt.string(from: s))–\(eFmt.string(from: e))"
        }
        return ""
    }

    private var categoryBreakdown: [(name: String, percentage: Double, color: Color)] {
        guard totalSpend > 0 else { return [] }
        var catTotals: [String: Int] = [:]
        for expense in expenses {
            let cat = expense.category ?? "Other"
            catTotals[cat, default: 0] += expense.amount
        }
        let colorMap: [String: Color] = [
            "Stay": .green, "Accommodation": .green, "stay": .green,
            "Food": Color(hex: "6366F1"), "food": Color(hex: "6366F1"), "Dining": Color(hex: "6366F1"),
            "Travel": .teal, "travel": .teal, "Transport": .teal, "transport": .teal,
        ]
        return catTotals.sorted { $0.value > $1.value }.map { cat, amount in
            let pct = Double(amount) / Double(totalSpend) * 100
            let color = colorMap[cat] ?? Color.gray.opacity(0.4)
            return (name: cat.capitalized, percentage: pct, color: color)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    tripHeader
                    contentCard
                }
            }
        }
        .navigationBarHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAddExpense) {
            CreateExpenseView(
                groupId: nil,
                tripId: trip.id,
                members: trip.members ?? [],
                onCreated: { await loadData() }
            )
        }
        .task { await loadData() }
    }

    private var tripHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.trailing, 8)
                Button(action: {}) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.trailing, 8)
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            }

            HStack(spacing: 0) {
                Text("TRIP")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color.white.opacity(0.5))
                    .tracking(0.5)
                if !dateRange.isEmpty {
                    Text(" · \(dateRange.uppercased())")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color.white.opacity(0.5))
                        .tracking(0.5)
                }
            }
            .padding(.top, 8)

            Text(trip.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text(memberNames.joined(separator: " · "))
                .font(.caption)
                .foregroundColor(Color.white.opacity(0.5))
                .padding(.bottom, 4)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total spend")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.5))
                    Text(formatAmount(totalSpend))
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Your share")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.5))
                    Text(formatAmount(yourShare))
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("You are owed")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.5))
                    Text(formatAmount(youAreOwed))
                        .font(.title3.weight(.bold))
                        .foregroundColor(SplitEZTheme.positive)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if hasMultiCurrency {
                Text(multiCurrencyNote)
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.positive.opacity(0.8))
                    .padding(.top, 2)
            }

            HStack(spacing: 12) {
                Button(action: {}) {
                    Text("Remind all")
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
                    Text("Export")
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
            .padding(.top, 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(SplitEZTheme.darkBg)
    }

    private var contentCard: some View {
        VStack(spacing: 0) {
            if !categoryBreakdown.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SPEND BY CATEGORY")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(SplitEZTheme.primary)
                        .tracking(0.5)

                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            ForEach(categoryBreakdown, id: \.name) { cat in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(cat.color)
                                    .frame(width: max(geo.size.width * cat.percentage / 100 - 2, 4))
                            }
                        }
                    }
                    .frame(height: 10)

                    HStack(spacing: 0) {
                        ForEach(categoryBreakdown, id: \.name) { cat in
                            Text("\(cat.name) \(Int(cat.percentage))%")
                                .font(.caption2)
                                .foregroundColor(SplitEZTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 16)
            }

            HStack {
                Text("Expenses")
                    .font(.headline)
                    .foregroundColor(SplitEZTheme.textPrimary)
                Spacer()
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.caption)
                        Text("Filter")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundColor(SplitEZTheme.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)

            if expenses.isEmpty && !isLoading {
                Text("No expenses yet")
                    .font(.subheadline)
                    .foregroundColor(SplitEZTheme.textTertiary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 40)
            } else {
                ForEach(Array(expenses.enumerated()), id: \.element.id) { index, expense in
                    if index > 0 {
                        Divider().padding(.leading, 72)
                    }
                    tripExpenseRow(expense)
                }
            }

            Spacer().frame(height: 80)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .offset(y: -16)
    }

    private func tripExpenseRow(_ expense: Expense) -> some View {
        HStack(spacing: 12) {
            let icon = iconForCategory(expense.category)
            Image(systemName: icon.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(icon.color)
                .frame(width: 44, height: 44)
                .background(icon.color.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.description)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(SplitEZTheme.textPrimary)
                Text(tripExpenseSubtitle(expense))
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.textSecondary)
            }

            Spacer()

            let share = expenseUserShare(expense)
            VStack(alignment: .trailing, spacing: 2) {
                Text(share >= 0 ? "owed to you" : "you owe")
                    .font(.caption)
                    .foregroundColor(SplitEZTheme.textSecondary)
                Text(formatAmount(abs(share)))
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(share >= 0 ? SplitEZTheme.positive : SplitEZTheme.negative)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func tripExpenseSubtitle(_ expense: Expense) -> String {
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "d MMM"
        var dateStr = ""
        if let date = ISO8601DateFormatter().date(from: expense.date) {
            dateStr = dateFmt.string(from: date)
        } else {
            dateStr = String(expense.date.prefix(6))
        }
        let payer = expense.paidBy?.firstName ?? "Someone"
        let splitCount = expense.splits?.count ?? (trip.members?.count ?? 1)
        return "\(dateStr) · \(payer) paid \(expense.amountFormatted) · ÷\(splitCount)"
    }

    private func expenseUserShare(_ expense: Expense) -> Int {
        let splitCount = expense.splits?.count ?? max(trip.members?.count ?? 1, 1)
        return expense.amount / splitCount
    }

    private func iconForCategory(_ category: String?) -> (name: String, color: Color) {
        switch category?.lowercased() {
        case "stay", "accommodation", "hotel": return ("house.fill", Color(hex: "6366F1"))
        case "food", "dining": return ("fork.knife", .orange)
        case "travel", "transport", "cab": return ("car.fill", Color(hex: "6366F1").opacity(0.7))
        case "shopping": return ("bag.fill", .pink)
        default: return ("fork.knife", .orange)
        }
    }

    private var hasMultiCurrency: Bool {
        Set(expenses.map { $0.currency }).count > 1
    }

    private var multiCurrencyNote: String {
        let currencies = Set(expenses.map { $0.currency }).subtracting(["INR"])
        guard let foreign = currencies.first else { return "" }
        let foreignTotal = expenses.filter { $0.currency == foreign }.reduce(0) { $0 + $1.amount }
        return "Includes \(formatAmount(foreignTotal, currency: foreign)) converted at ₹83.40 · 29 Aug rate"
    }

    private func loadData() async {
        isLoading = true
        async let e: [Expense] = (try? api.get("/expenses", query: ["tripId": trip.id])) ?? []
        async let b: [Balance] = (try? api.get("/balances", query: ["tripId": trip.id])) ?? []
        expenses = await e
        balances = await b
        isLoading = false
    }
}

struct CreateTripView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var destination = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 3)
    @State private var showDates = false
    @State private var isLoading = false
    let onCreated: () async -> Void
    private let api = APIClient.shared
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Info") {
                    TextField("Trip Name", text: $name)
                    TextField("Destination (optional)", text: $destination)
                }
                Section("Dates") {
                    Toggle("Set dates", isOn: $showDates)
                    if showDates {
                        DatePicker("Start", selection: $startDate, displayedComponents: .date)
                        DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Trip")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isLoading = true
                            let _: Trip? = try? await api.post("/trips", body: CreateTripRequest(
                                name: name,
                                destination: destination.isEmpty ? nil : destination,
                                startDate: showDates ? dateFormatter.string(from: startDate) : nil,
                                endDate: showDates ? dateFormatter.string(from: endDate) : nil
                            ))
                            await onCreated()
                            isLoading = false
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || isLoading)
                }
            }
        }
    }
}
