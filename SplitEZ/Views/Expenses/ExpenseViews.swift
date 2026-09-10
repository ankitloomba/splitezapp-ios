import SwiftUI

struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(expense.description)
                    .font(.subheadline.bold())
                Text("Paid by \(expense.paidBy?.firstName ?? "Unknown")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(expense.amountFormatted)
                    .font(.subheadline.bold())
                Text(expense.splitMethod)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct CreateExpenseView: View {
    @Environment(\.dismiss) var dismiss
    let groupId: String?
    let tripId: String?
    let members: [UserSummary]
    let onCreated: () async -> Void

    @State private var description = ""
    @State private var amountText = ""
    @State private var splitMethod = "EQUAL"
    @State private var selectedCategory: Category?
    @State private var note = ""
    @State private var selectedMembers: Set<String> = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var categories: [Category] = []

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Description", text: $description)
                    TextField("Amount (e.g. 150.00)", text: $amountText)
                        .keyboardType(.decimalPad)
                    Picker("Split Method", selection: $splitMethod) {
                        Text("Equal").tag("EQUAL")
                        Text("Exact").tag("EXACT")
                        Text("Percentage").tag("PERCENTAGE")
                    }
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(Optional<Category>.none)
                        ForEach(categories) { cat in
                            HStack {
                                Text(cat.icon ?? "📦")
                                Text(cat.name)
                            }.tag(Optional(cat))
                        }
                    }
                    TextField("Note (optional)", text: $note)
                }

                Section("Split With") {
                    ForEach(members) { member in
                        HStack {
                            AvatarView(user: member, size: 28)
                            Text(member.displayName)
                            Spacer()
                            if selectedMembers.contains(member.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(SplitEZTheme.primary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedMembers.contains(member.id) {
                                selectedMembers.remove(member.id)
                            } else {
                                selectedMembers.insert(member.id)
                            }
                        }
                    }
                }

                if let error {
                    Section {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Add Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(description.isEmpty || amountText.isEmpty || selectedMembers.isEmpty || isLoading)
                }
            }
        }
        .onAppear {
            selectedMembers = Set(members.map(\.id))
        }
        .task {
            do {
                categories = try await api.get("/categories")
            } catch { /* use empty list */ }
        }
    }

    private func save() async {
        guard let amountDouble = Double(amountText) else {
            error = "Invalid amount"
            return
        }
        let amount = Int(amountDouble * 100) // Convert to minor units
        isLoading = true
        error = nil

        let participants = selectedMembers.map { SplitParticipant(userId: $0) }
        let req = CreateExpenseRequest(
            description: description,
            amount: amount,
            splitMethod: splitMethod,
            category: selectedCategory?.name,
            note: note.isEmpty ? nil : note,
            groupId: groupId,
            tripId: tripId,
            participants: participants,
            idempotencyKey: UUID().uuidString
        )

        do {
            let _: Expense = try await api.post("/expenses", body: req)
            await onCreated()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
