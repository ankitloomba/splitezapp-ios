import SwiftUI

struct FinancesView: View {
    @State private var summary: FinancialSummary?
    @State private var incomes: [Income] = []
    @State private var personalExpenses: [PersonalExpense] = []
    @State private var selectedTab = 0
    @State private var showAddIncome = false
    @State private var showAddExpense = false
    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary card
                if let s = summary {
                    VStack(spacing: 12) {
                        Text("This Month")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack(spacing: 24) {
                            StatItem(title: "Income", amount: s.totalIncome, color: SplitEZTheme.positive)
                            StatItem(title: "Expenses", amount: s.totalExpenses, color: SplitEZTheme.negative)
                            StatItem(title: "Savings", amount: s.netSavings,
                                     color: s.netSavings >= 0 ? SplitEZTheme.positive : SplitEZTheme.negative)
                        }
                    }
                    .padding()
                    .background(SplitEZTheme.secondaryBackground)
                    .cornerRadius(12)
                    .padding()
                }

                Picker("", selection: $selectedTab) {
                    Text("Income").tag(0)
                    Text("Expenses").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                List {
                    if selectedTab == 0 {
                        ForEach(incomes) { income in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(income.type).font(.subheadline.bold())
                                    if let note = income.note { Text(note).font(.caption).foregroundColor(.secondary) }
                                }
                                Spacer()
                                Text(formatAmount(income.amount))
                                    .foregroundColor(SplitEZTheme.positive)
                            }
                        }
                    } else {
                        ForEach(personalExpenses) { expense in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(expense.description).font(.subheadline.bold())
                                    if let cat = expense.category { Text(cat).font(.caption).foregroundColor(.secondary) }
                                }
                                Spacer()
                                Text(formatAmount(expense.amount))
                                    .foregroundColor(SplitEZTheme.negative)
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Finances")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if selectedTab == 0 { showAddIncome = true }
                        else { showAddExpense = true }
                    } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Menu {
                        Button { exportReport(format: "csv") } label: {
                            Label("Export CSV", systemImage: "tablecells")
                        }
                        Button { exportReport(format: "pdf") } label: {
                            Label("Export PDF", systemImage: "doc.richtext")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showAddIncome) {
                AddIncomeView { await loadData() }
            }
            .sheet(isPresented: $showAddExpense) {
                AddPersonalExpenseView { await loadData() }
            }
            .refreshable { await loadData() }
            .task { await loadData() }
        }
    }

    private func exportReport(format: String) {
        guard let url = api.buildURL("/exports/expenses/\(format)") else { return }
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #endif
    }

    private func loadData() async {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let month = formatter.string(from: now)

        summary = try? await api.get("/finances/summary", query: ["month": month])
        let incomeResp: PaginatedResponse<Income>? = try? await api.get("/finances/income")
        incomes = incomeResp?.items ?? []
        let expenseResp: PaginatedResponse<PersonalExpense>? = try? await api.get("/finances/expenses")
        personalExpenses = expenseResp?.items ?? []
    }
}

struct StatItem: View {
    let title: String
    let amount: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(formatAmount(abs(amount)))
                .font(.subheadline.bold())
                .foregroundColor(color)
        }
    }
}

struct AddIncomeView: View {
    @Environment(\.dismiss) var dismiss
    @State private var amountText = ""
    @State private var type = "Salary"
    @State private var note = ""
    @State private var isLoading = false
    let onCreated: () async -> Void
    private let api = APIClient.shared
    let incomeTypes = ["Salary", "Cash", "Pocket Money", "Bonus", "Freelance", "Refund", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Amount (e.g. 50000.00)", text: $amountText).keyboardType(.decimalPad)
                Picker("Type", selection: $type) {
                    ForEach(incomeTypes, id: \.self) { Text($0) }
                }
                TextField("Note (optional)", text: $note)
            }
            .navigationTitle("Add Income")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            guard let amt = Double(amountText) else { return }
                            isLoading = true
                            let _: Income? = try? await api.post("/finances/income", body: CreateIncomeRequest(
                                amount: Int(amt * 100), type: type, note: note.isEmpty ? nil : note))
                            await onCreated()
                            dismiss()
                        }
                    }.disabled(amountText.isEmpty || isLoading)
                }
            }
        }
    }
}

struct AddPersonalExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @State private var description = ""
    @State private var amountText = ""
    @State private var category = ""
    @State private var note = ""
    @State private var isLoading = false
    let onCreated: () async -> Void
    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            Form {
                TextField("Description", text: $description)
                TextField("Amount (e.g. 150.00)", text: $amountText).keyboardType(.decimalPad)
                TextField("Category (optional)", text: $category)
                TextField("Note (optional)", text: $note)
            }
            .navigationTitle("Add Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            guard let amt = Double(amountText) else { return }
                            isLoading = true
                            let _: PersonalExpense? = try? await api.post("/finances/expenses", body: CreatePersonalExpenseRequest(
                                amount: Int(amt * 100), description: description,
                                category: category.isEmpty ? nil : category, note: note.isEmpty ? nil : note))
                            await onCreated()
                            dismiss()
                        }
                    }.disabled(description.isEmpty || amountText.isEmpty || isLoading)
                }
            }
        }
    }
}
