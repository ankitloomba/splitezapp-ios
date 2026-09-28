import Foundation

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    // Start from Keychain so there's no flash to login on cold start
    @Published var isLoggedIn: Bool
    @Published var isCheckingAuth = false
    @Published var currentUser: UserProfile?

    private let api = APIClient.shared

    init() {
        // Synchronously read Keychain — if token exists, treat as logged in immediately
        isLoggedIn = KeychainHelper.get("accessToken") != nil
    }

    func checkAuth() async {
        let hasToken = await api.isLoggedIn
        guard hasToken else {
            isLoggedIn = false
            return
        }
        isCheckingAuth = true
        do {
            currentUser = try await api.get("/users/me")
            isLoggedIn = true
        } catch {
            // Network/server error — keep logged in if token still exists (offline support).
            // A 401 response will have cleared the token already via APIClient.
            let stillHasToken = await api.isLoggedIn
            if !stillHasToken { isLoggedIn = false }
        }
        isCheckingAuth = false
    }

    /// Returns `true` if email verification is needed (user should check inbox)
    @discardableResult
    func register(email: String, password: String, firstName: String, lastName: String?, phone: String? = nil) async throws -> Bool {
        let req = RegisterRequest(email: email, password: password, firstName: firstName, lastName: lastName, phone: phone?.isEmpty == true ? nil : phone)
        let resp: RegisterResponse = try await api.post("/auth/register", body: req, auth: false)

        if let access = resp.accessToken, let refresh = resp.refreshToken {
            // Auto-verified — log in immediately
            let tokens = AuthTokens(accessToken: access, refreshToken: refresh, user: resp.user)
            await api.setTokens(tokens)
            currentUser = try await api.get("/users/me")
            isLoggedIn = true
            return false
        }

        // Needs email verification
        return true
    }

    func login(email: String, password: String) async throws {
        let req = LoginRequest(email: email, password: password)
        let tokens: AuthTokens = try await api.post("/auth/login", body: req, auth: false)
        await api.setTokens(tokens)
        currentUser = try await api.get("/users/me")
        isLoggedIn = true
    }

    func logout() async {
        let _: SuccessResponse? = try? await api.post("/auth/logout")
        await api.clearTokens()
        currentUser = nil
        isLoggedIn = false
    }

    func forgotPassword(email: String) async throws {
        let _: SuccessResponse = try await api.post("/auth/forgot-password", body: ForgotPasswordRequest(email: email), auth: false)
    }

    func resetPassword(token: String, password: String) async throws {
        let _: SuccessResponse = try await api.post("/auth/reset-password", body: ResetPasswordRequest(token: token, password: password), auth: false)
    }

    func verifyEmail(token: String) async throws {
        let _: SuccessResponse = try await api.post("/auth/verify-email", body: VerifyEmailRequest(token: token), auth: false)
    }
}
