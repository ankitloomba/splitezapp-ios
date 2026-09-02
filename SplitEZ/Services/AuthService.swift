import Foundation

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isLoggedIn = false
    @Published var currentUser: UserProfile?

    private let api = APIClient.shared

    func checkAuth() async {
        let loggedIn = await api.isLoggedIn
        if loggedIn {
            do {
                currentUser = try await api.get("/users/me")
                isLoggedIn = true
            } catch {
                isLoggedIn = false
            }
        }
    }

    func register(email: String, password: String, firstName: String, lastName: String?) async throws {
        let req = RegisterRequest(email: email, password: password, firstName: firstName, lastName: lastName, phone: nil)
        let tokens: AuthTokens = try await api.post("/auth/register", body: req, auth: false)
        await api.setTokens(tokens)
        currentUser = try await api.get("/users/me")
        isLoggedIn = true
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
