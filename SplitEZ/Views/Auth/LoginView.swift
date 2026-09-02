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
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(SplitEZTheme.primary)
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
