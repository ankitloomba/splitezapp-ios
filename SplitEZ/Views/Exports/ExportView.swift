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

        guard let url = await api.buildURL("/exports/expenses", query: ["format": format]) else {
            message = "Could not build export URL"
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode < 300 else {
                message = "Export failed — server error"
                return
            }

            // Write to a temp file and present share sheet
            let fileName = "splitez_expenses.\(format)"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try data.write(to: tempURL)

            await MainActor.run {
                let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let root = scene.windows.first?.rootViewController {
                    root.present(activityVC, animated: true)
                }
                message = "\(format.uppercased()) exported successfully"
            }
        } catch {
            message = "Export failed: \(error.localizedDescription)"
        }
    }
}
