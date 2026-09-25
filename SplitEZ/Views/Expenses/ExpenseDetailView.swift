import SwiftUI

struct ExpenseDetailView: View {
    let expense: Expense
    @State private var showSheet = true
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Color.clear
            .fullScreenCover(isPresented: $showSheet, onDismiss: { dismiss() }) {
                AddExpenseSheet(expense: expense)
            }
    }
}
