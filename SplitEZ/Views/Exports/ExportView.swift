import SwiftUI

struct ExportView: View {
    @State private var exporting = false
    @State private var message: String?
    private let api = APIClient.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Export your expenses")
                    .font(.title2.bold())
                Text("Download your data as CSV or PDF report")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                exportCard(
                    icon: "doc.text",
                    title: "CSV Spreadsheet",
                    description: "Export all expenses as a CSV file. Opens in Excel, Numbers, or Google Sheets.",
                    buttonText: "Export CSV"
                ) {
                    await exportFile(format: "csv")
                }

                exportCard(
                    icon: "chart.bar.doc.horizontal",
                    title: "PDF Report",
                    description: "Generate a formatted PDF report with summaries, ready to share or print.",
                    buttonText: "Export PDF"
                ) {
                    await exportFile(format: "pdf")
                }

                if let message {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(SplitEZTheme.positive)
                        Text(message)
                            .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SplitEZTheme.positive.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("Export Data")
    }

    @ViewBuilder
    private func exportCard(
        icon: String,
        title: String,
        description: String,
        buttonText: String,
        action: @escaping () async -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(SplitEZTheme.primary)
                Text(title)
                    .font(.headline)
            }
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            Button {
                Task { await action() }
            } label: {
                HStack {
                    if exporting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(buttonText)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(SplitEZTheme.primary)
            .disabled(exporting)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func exportFile(format: String) async {
        exporting = true
        defer { exporting = false }
        // Opens the download URL — in a real app, use URLSession to download + share sheet
        if let url = await api.buildURL("/exports/expenses?format=\(format)") {
            await MainActor.run {
                UIApplication.shared.open(url)
                message = "\(format.uppercased()) download started"
            }
        }
    }
}
