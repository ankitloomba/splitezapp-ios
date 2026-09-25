import SwiftUI

struct ExportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedFormat: ExportFormat = .excel
    @State private var exporting = false
    @State private var errorMessage: String?
    @State private var shareURL: URL?
    @State private var showShareSheet = false
    private let api = APIClient.shared

    enum ExportFormat: String, CaseIterable {
        case excel = "xlsx"
        case pdf   = "pdf"
        case csv   = "csv"

        var label: String {
            switch self {
            case .excel: return "Excel"
            case .pdf:   return "PDF"
            case .csv:   return "CSV"
            }
        }

        var icon: String {
            switch self {
            case .excel: return "tablecells"
            case .pdf:   return "chart.bar.doc.horizontal"
            case .csv:   return "doc.plaintext"
            }
        }

        var color: Color {
            switch self {
            case .excel: return Color(red: 0.13, green: 0.53, blue: 0.25)
            case .pdf:   return Color(red: 0.82, green: 0.17, blue: 0.17)
            case .csv:   return Color(red: 0.22, green: 0.40, blue: 0.82)
            }
        }

        var description: String {
            switch self {
            case .excel: return "Opens in Excel, Numbers, or Google Sheets"
            case .pdf:   return "Formatted report, ready to share or print"
            case .csv:   return "Plain text — import into any spreadsheet app"
            }
        }
    }

    // Sample preview rows from SampleData
    private var previewExpenses: [Expense] {
        Array(SampleData.expenses.prefix(6))
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                SplitEZTheme.darkBg
                Color.white
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    Spacer()
                    Text("Export Data")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 16)
                .background(SplitEZTheme.darkBg.ignoresSafeArea(edges: .top))

                ScrollView {
                    VStack(spacing: 20) {
                        // Format picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose format")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(SplitEZTheme.textPrimary)
                                .padding(.horizontal, 20)

                            HStack(spacing: 12) {
                                ForEach(ExportFormat.allCases, id: \.self) { fmt in
                                    FormatCard(fmt: fmt, isSelected: selectedFormat == fmt)
                                        .onTapGesture { selectedFormat = fmt }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 20)

                        // Export & Share button
                        Button {
                            Task { await exportFile() }
                        } label: {
                            HStack(spacing: 10) {
                                if exporting {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                Text(exporting ? "Exporting…" : "Export & Share \(selectedFormat.label)")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(selectedFormat.color)
                            )
                        }
                        .disabled(exporting)
                        .padding(.horizontal, 20)

                        if let err = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(SplitEZTheme.negative)
                                Text(err)
                                    .font(.caption)
                                    .foregroundColor(SplitEZTheme.negative)
                            }
                            .padding(.horizontal, 20)
                        }

                        // Data preview table
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Data preview")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(SplitEZTheme.textPrimary)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 12)

                            // Table
                            VStack(spacing: 0) {
                                tableHeader
                                ForEach(Array(previewExpenses.enumerated()), id: \.element.id) { i, expense in
                                    tableRow(expense: expense, isEven: i % 2 == 0)
                                    if i < previewExpenses.count - 1 {
                                        Divider().padding(.leading, 20)
                                    }
                                }
                                if SampleData.expenses.count > 6 {
                                    HStack {
                                        Image(systemName: "ellipsis")
                                            .font(.caption)
                                            .foregroundColor(SplitEZTheme.textTertiary)
                                        Text("+ \(SampleData.expenses.count - 6) more rows in export")
                                            .font(.caption)
                                            .foregroundColor(SplitEZTheme.textTertiary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                }
                            }
                            .background(SplitEZTheme.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color(red: 0.88, green: 0.88, blue: 0.90), lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                        }

                        Spacer().frame(height: 40)
                    }
                }
                .background(SplitEZTheme.cardBg)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 24, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 24, style: .continuous))
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .enableSwipeBack()
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ShareSheet(url: url)
            }
        }
    }

    // MARK: - Table components

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("Date")
                .frame(width: 70, alignment: .leading)
            Text("Description")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Category")
                .frame(width: 80, alignment: .leading)
            Text("Amount")
                .frame(width: 70, alignment: .trailing)
        }
        .font(.caption.weight(.semibold))
        .foregroundColor(SplitEZTheme.textSecondary)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(SplitEZTheme.pageBg)
    }

    private func tableRow(expense: Expense, isEven: Bool) -> some View {
        HStack(spacing: 0) {
            Text(shortDate(expense.date))
                .frame(width: 70, alignment: .leading)
            Text(expense.description)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(expense.category?.capitalized ?? "—")
                .lineLimit(1)
                .frame(width: 80, alignment: .leading)
            Text(formattedAmount(expense.amount))
                .frame(width: 70, alignment: .trailing)
                .foregroundColor(SplitEZTheme.textPrimary)
        }
        .font(.caption)
        .foregroundColor(SplitEZTheme.textSecondary)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(isEven ? Color.white : SplitEZTheme.rowAltBg)
    }

    // MARK: - Export

    private func exportFile() async {
        exporting = true
        errorMessage = nil
        defer { exporting = false }

        guard let url = await api.buildURL("/exports/expenses", query: ["format": selectedFormat.rawValue]) else {
            errorMessage = "Could not build export URL"
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode < 300 else {
                errorMessage = "Export failed — server error"
                return
            }

            let fileName = "splitez_expenses.\(selectedFormat.rawValue)"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try data.write(to: tempURL)

            await MainActor.run {
                shareURL = tempURL
                showShareSheet = true
            }
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    private func shortDate(_ date: Date?) -> String {
        guard let d = date else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f.string(from: d)
    }

    private func formattedAmount(_ amount: Double?) -> String {
        guard let a = amount else { return "—" }
        return "₹\(Int(a))"
    }
}

// MARK: - Format card

private struct FormatCard: View {
    let fmt: ExportView.ExportFormat
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: fmt.icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(isSelected ? .white : fmt.color)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? fmt.color : fmt.color.opacity(0.1))
                )
            Text(fmt.label)
                .font(.caption.weight(.semibold))
                .foregroundColor(isSelected ? fmt.color : SplitEZTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? fmt.color.opacity(0.08) : SplitEZTheme.pageBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? fmt.color : Color.clear, lineWidth: 1.5)
        )
    }
}

// MARK: - Share sheet wrapper

private struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
