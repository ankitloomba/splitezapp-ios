import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var showRegister = false
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 40)

                    // Logo
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [SplitEZTheme.primary, SplitEZTheme.accent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 72, height: 72)
                            Text("S₹")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("SplitEZ")
                            .font(.largeTitle.bold())
                        Text("Split expenses with ease")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer().frame(height: 20)

                    // Form
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .textFieldStyle(.roundedBorder)

                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .textFieldStyle(.roundedBorder)

                        if let error {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        Button {
                            Task { await login() }
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Log In")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SplitEZTheme.primary)
                        .disabled(email.isEmpty || password.isEmpty || isLoading)

                        Button("Forgot Password?") {
                            showForgotPassword = true
                        }
                        .font(.footnote)
                    }
                    .padding(.horizontal, 32)

                    Divider().padding(.horizontal, 32)

                    Button("Create Account") {
                        showRegister = true
                    }
                    .font(.headline)
                }
            }
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }

    private func login() async {
        isLoading = true
        error = nil
        do {
            try await auth.login(email: email, password: password)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct RegisterView: View {
    @EnvironmentObject var auth: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var showVerifyAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Create Account")
                    .font(.title.bold())
                    .padding(.top, 20)

                TextField("First Name", text: $firstName)
                    .textContentType(.givenName)
                    .textFieldStyle(.roundedBorder)

                TextField("Last Name (optional)", text: $lastName)
                    .textContentType(.familyName)
                    .textFieldStyle(.roundedBorder)

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(.roundedBorder)

                SecureField("Password (min 8 characters)", text: $password)
                    .textContentType(.newPassword)
                    .textFieldStyle(.roundedBorder)

                if !password.isEmpty {
                    PasswordStrengthView(password: password)
                }

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Button {
                    Task { await register() }
                } label: {
                    if isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Sign Up").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(SplitEZTheme.primary)
                .disabled(firstName.isEmpty || email.isEmpty || password.count < 8 || isLoading)
            }
            .padding(.horizontal, 32)
        }
        .alert("Check Your Email", isPresented: $showVerifyAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("We've sent a verification link to \(email). Please verify your email to activate your account.")
        }
    }

    private func register() async {
        isLoading = true
        error = nil
        do {
            try await auth.register(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName.isEmpty ? nil : lastName
            )
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var sent = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Reset Password")
                    .font(.title2.bold())

                Text("Enter your email and we'll send you a reset link.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task {
                        isLoading = true
                        try? await AuthService.shared.forgotPassword(email: email)
                        isLoading = false
                        sent = true
                    }
                } label: {
                    if isLoading { ProgressView().frame(maxWidth: .infinity) }
                    else { Text("Send Reset Link").frame(maxWidth: .infinity) }
                }
                .buttonStyle(.borderedProminent)
                .tint(SplitEZTheme.primary)
                .disabled(email.isEmpty || isLoading)

                if sent {
                    Text("If an account exists with that email, you'll receive a reset link.")
                        .font(.caption)
                        .foregroundColor(.green)
                }

                Spacer()
            }
            .padding(32)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Password Strength

private enum PasswordStrength: String {
    case weak = "Weak"
    case fair = "Fair"
    case good = "Good"
    case strong = "Strong"

    var color: Color {
        switch self {
        case .weak: return SplitEZTheme.destructive
        case .fair: return Color.orange
        case .good: return SplitEZTheme.primary
        case .strong: return SplitEZTheme.positive
        }
    }

    var fraction: CGFloat {
        switch self {
        case .weak: return 0.25
        case .fair: return 0.5
        case .good: return 0.75
        case .strong: return 1.0
        }
    }
}

private func evaluatePassword(_ password: String) -> PasswordStrength {
    var score = 0
    if password.count >= 8 { score += 1 }
    if password.count >= 12 { score += 1 }
    if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
    if password.range(of: "[a-z]", options: .regularExpression) != nil { score += 1 }
    if password.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
    if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { score += 1 }

    switch score {
    case 0...2: return .weak
    case 3: return .fair
    case 4...5: return .good
    default: return .strong
    }
}

private struct PasswordStrengthView: View {
    let password: String

    private var strength: PasswordStrength { evaluatePassword(password) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(strength.color)
                        .frame(width: geo.size.width * strength.fraction, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: strength.fraction)
                }
            }
            .frame(height: 6)

            HStack {
                Text(strength.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(strength.color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 3) {
                ruleRow("At least 8 characters", met: password.count >= 8)
                ruleRow("Uppercase letter", met: password.range(of: "[A-Z]", options: .regularExpression) != nil)
                ruleRow("Lowercase letter", met: password.range(of: "[a-z]", options: .regularExpression) != nil)
                ruleRow("Number", met: password.range(of: "[0-9]", options: .regularExpression) != nil)
                ruleRow("Special character", met: password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil)
            }
        }
    }

    private func ruleRow(_ text: String, met: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.caption2)
                .foregroundColor(met ? SplitEZTheme.positive : Color(.systemGray3))
            Text(text)
                .font(.caption2)
                .foregroundColor(met ? .primary : .secondary)
        }
    }
}
