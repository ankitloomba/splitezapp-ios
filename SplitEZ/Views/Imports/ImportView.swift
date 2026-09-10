import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @State private var showFilePicker = false
    @State private var selectedFileName: String?
    @State private var selectedFileData: Data?
    @State private var importing = false
    @State private var result: ImportResult?
    private let api = APIClient.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Import from file")
                    .font(.title2.bold())
                Text("Upload a CSV or Excel file to bulk import expenses. Supports Splitwise export format.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // File picker zone
                Button {
                    showFilePicker = true
                } label: {
                    VStack(spacing: 12) {
                        if let name = selectedFileName {
                            Image(systemName: "paperclip")
                                .font(.largeTitle)
                                .foregroundColor(SplitEZTheme.accent)
                            Text(name)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)
                            Text("Tap to change")
                                .font(.caption)
                                .foregroundColor(SplitEZTheme.primary)
                        } else {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(SplitEZTheme.primary.opacity(0.6))
                            Text("Tap to select a file")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(SplitEZTheme.primary)
                            Text("CSV, XLS, XLSX · Max 5 MB")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                selectedFileName != nil ? SplitEZTheme.accent : SplitEZTheme.primary.opacity(0.3),
                                style: StrokeStyle(lineWidth: 2, dash: selectedFileName == nil ? [8] : [])
                            )
                    )
                    .background(
                        (selectedFileName != nil ? SplitEZTheme.accent : SplitEZTheme.primary)
                            .opacity(0.03)
                            .cornerRadius(12)
                    )
                }
                .buttonStyle(.plain)

                // Supported formats
                VStack(alignment: .leading, spacing: 8) {
                    Text("Supported formats")
                        .font(.subheadline.weight(.semibold))
                    FormatRow(title: "Splitwise export", detail: "CSV from Splitwise → Settings → Export")
                    FormatRow(title: "Generic CSV", detail: "Columns: Date, Description, Amount, Category")
                    FormatRow(title: "Excel", detail: "XLS/XLSX with the same column layout")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

                // Import button
                Button {
                    Task { await uploadFile() }
                } label: {
                    HStack {
                        if importing {
                            ProgressView().tint(.white)
                        }
                        Text(importing ? "Importing…" : "Import Expenses")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(SplitEZTheme.primary)
                .disabled(selectedFileData == nil || importing)

                // Result
                if let result {
                    HStack(alignment: .top) {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.success ? SplitEZTheme.positive : SplitEZTheme.destructive)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.success ? "Import successful!" : "Import failed")
                                .font(.subheadline.weight(.semibold))
                            Text(result.message)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        (result.success ? SplitEZTheme.positive : SplitEZTheme.destructive)
                            .opacity(0.1)
                    )
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("Import Expenses")
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.commaSeparatedText, .spreadsheet, .data],
            allowsMultipleSelection: false
        ) { fileResult in
            switch fileResult {
            case .success(let urls):
                guard let url = urls.first else { return }
                selectedFileName = url.lastPathComponent
                result = nil
                if url.startAccessingSecurityScopedResource() {
                    selectedFileData = try? Data(contentsOf: url)
                    url.stopAccessingSecurityScopedResource()
                }
            case .failure:
                break
            }
        }
    }

    private func uploadFile() async {
        guard let data = selectedFileData, let name = selectedFileName else { return }
        importing = true
        defer { importing = false }

        guard let baseURL = api.buildURL("/imports/expenses") else {
            result = ImportResult(success: false, message: "Invalid URL")
            return
        }

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        if let token = api.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let mimeType: String
        if name.hasSuffix(".csv") { mimeType = "text/csv" }
        else if name.hasSuffix(".xlsx") { mimeType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }
        else if name.hasSuffix(".xls") { mimeType = "application/vnd.ms-excel" }
        else { mimeType = "application/octet-stream" }

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(name)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode < 300 {
                self.result = ImportResult(success: true, message: "Expenses imported successfully")
            } else {
                let msg = String(data: responseData, encoding: .utf8) ?? "Server error"
                self.result = ImportResult(success: false, message: msg)
            }
        } catch {
            self.result = ImportResult(success: false, message: error.localizedDescription)
        }
    }
}

private struct ImportResult {
    let success: Bool
    let message: String
}

private struct FormatRow: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption.weight(.medium))
                Text(detail).font(.caption2).foregroundColor(.secondary)
            }
        }
    }
}
