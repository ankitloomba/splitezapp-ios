import Foundation

enum APIError: Error, LocalizedError {
    case unauthorized
    case forbidden(String)
    case notFound
    case validation(String)
    case server(String)
    case network(Error)
    case decode(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Please log in again"
        case .forbidden(let m): return m
        case .notFound: return "Not found"
        case .validation(let m): return m
        case .server(let m): return m
        case .network(let e): return e.localizedDescription
        case .decode(let e): return "Data error: \(e.localizedDescription)"
        }
    }
}

actor APIClient {
    static let shared = APIClient()

    private let baseURL = "https://splitez-backend-production.up.railway.app/api"
    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        return e
    }()

    /// Build a full URL for opening in browser (e.g. export downloads).
    func buildURL(_ path: String, query: [String: String]? = nil) -> URL? {
        var components = URLComponents(string: "\(baseURL)/v1\(path)")
        if let query {
            components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        // Append auth token so the browser can download
        if let token = accessToken {
            var items = components?.queryItems ?? []
            items.append(URLQueryItem(name: "token", value: token))
            components?.queryItems = items
        }
        return components?.url
    }

    // MARK: - Token management
    private var accessToken: String? {
        get { KeychainHelper.get("accessToken") }
        set {
            if let v = newValue { KeychainHelper.set(v, for: "accessToken") }
            else { KeychainHelper.delete("accessToken") }
        }
    }
    private var refreshToken: String? {
        get { KeychainHelper.get("refreshToken") }
        set {
            if let v = newValue { KeychainHelper.set(v, for: "refreshToken") }
            else { KeychainHelper.delete("refreshToken") }
        }
    }

    var isLoggedIn: Bool { accessToken != nil }

    func setTokens(_ tokens: AuthTokens) {
        accessToken = tokens.accessToken
        refreshToken = tokens.refreshToken
    }

    func clearTokens() {
        accessToken = nil
        refreshToken = nil
    }

    // MARK: - Core request
    private func request<T: Codable>(
        _ method: String,
        _ path: String,
        body: (any Encodable)? = nil,
        query: [String: String]? = nil,
        auth: Bool = true
    ) async throws -> T {
        var urlString = "\(baseURL)\(path)"
        if let query, !query.isEmpty {
            let qs = query.compactMap { k, v in
                v.isEmpty ? nil : "\(k)=\(v.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? v)"
            }.joined(separator: "&")
            if !qs.isEmpty { urlString += "?\(qs)" }
        }

        guard let url = URL(string: urlString) else {
            throw APIError.server("Invalid URL")
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if auth, let token = accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            req.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.network(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.server("Invalid response")
        }

        switch http.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decode(error)
            }
        case 401:
            // Try token refresh once
            if auth, let rt = refreshToken {
                do {
                    let tokens: AuthTokens = try await request(
                        "POST", "/auth/refresh",
                        body: RefreshRequest(refreshToken: rt),
                        auth: false
                    )
                    setTokens(tokens)
                    // Retry original request
                    return try await request(method, path, body: body, query: query, auth: auth)
                } catch {
                    clearTokens()
                    throw APIError.unauthorized
                }
            }
            throw APIError.unauthorized
        case 403:
            let msg = (try? decoder.decode(ErrorResponse.self, from: data))?.message ?? "Forbidden"
            throw APIError.forbidden(msg)
        case 404:
            throw APIError.notFound
        case 400, 422:
            let msg = (try? decoder.decode(ErrorResponse.self, from: data))?.message ?? "Validation error"
            throw APIError.validation(msg)
        default:
            let msg = (try? decoder.decode(ErrorResponse.self, from: data))?.message ?? "Server error"
            throw APIError.server(msg)
        }
    }

    // Convenience methods
    func get<T: Codable>(_ path: String, query: [String: String]? = nil) async throws -> T {
        try await request("GET", path, query: query)
    }

    func post<T: Codable>(_ path: String, body: (any Encodable)? = nil, auth: Bool = true) async throws -> T {
        try await request("POST", path, body: body, auth: auth)
    }

    func put<T: Codable>(_ path: String, body: any Encodable) async throws -> T {
        try await request("PUT", path, body: body)
    }

    func patch<T: Codable>(_ path: String, body: (any Encodable)? = nil) async throws -> T {
        try await request("PATCH", path, body: body)
    }

    func delete<T: Codable>(_ path: String, body: (any Encodable)? = nil) async throws -> T {
        try await request("DELETE", path, body: body)
    }
}

// MARK: - Helpers
private struct ErrorResponse: Codable {
    let message: String?
    let statusCode: Int?
}

private struct AnyEncodable: Encodable {
    let wrapped: any Encodable
    init(_ wrapped: any Encodable) { self.wrapped = wrapped }
    func encode(to encoder: Encoder) throws { try wrapped.encode(to: encoder) }
}
