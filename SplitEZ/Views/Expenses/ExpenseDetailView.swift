import SwiftUI

struct ExpenseDetailView: View {
    let expense: Expense

    var body: some View {
        AddExpenseSheet(expense: expense)
    }
}
