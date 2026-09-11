import SwiftUI

// MARK: - Split Circle Logo (Brand Primary Mark)
// Light indigo (#818CF8) always left, deep indigo (#4338CA) always right

struct SplitEZLogo: View {
    var size: CGFloat = 64

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius = min(canvasSize.width, canvasSize.height) / 2

            // Left half — light indigo
            var leftPath = Path()
            leftPath.move(to: center)
            leftPath.addArc(center: center, radius: radius,
                           startAngle: .degrees(90), endAngle: .degrees(270),
                           clockwise: false)
            leftPath.closeSubpath()
            context.fill(leftPath, with: .color(SplitEZTheme.primaryLight))

            // Right half — deep indigo
            var rightPath = Path()
            rightPath.move(to: center)
            rightPath.addArc(center: center, radius: radius,
                            startAngle: .degrees(270), endAngle: .degrees(90),
                            clockwise: false)
            rightPath.closeSubpath()
            context.fill(rightPath, with: .color(SplitEZTheme.primary))

            // Diagonal divider — slightly rotated
            let dividerWidth: CGFloat = radius * 0.06
            var divider = Path()
            divider.addRoundedRect(in: CGRect(
                x: center.x - dividerWidth / 2,
                y: 0,
                width: dividerWidth,
                height: canvasSize.height
            ), cornerSize: .zero)

            let transform = CGAffineTransform(translationX: center.x, y: center.y)
                .rotated(by: .pi * -0.08)
                .translatedBy(x: -center.x, y: -center.y)
            let rotatedDivider = divider.applying(transform)

            // Clip divider to circle
            var clipCircle = Path()
            clipCircle.addEllipse(in: CGRect(x: 0, y: 0, width: canvasSize.width, height: canvasSize.height))

            context.clip(to: clipCircle)
            context.fill(rotatedDivider, with: .color(Color(hex: "10142A")))
        }
        .frame(width: size, height: size)
    }
}

struct SplitEZLogoSmall: View {
    var body: some View {
        SplitEZLogo(size: 28)
    }
}

// MARK: - Rounded Corner Helper

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Login Screen

struct LoginView: View {
    @EnvironmentObject var auth: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var error: String?
    @State private var showRegister = false
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    SplitEZTheme.darkBg.ignoresSafeArea()

                    VStack(spacing: 0) {
                        // Dark header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                SplitEZLogoSmall()
                                Text("SplitEZ")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 8)

                            Text("Welcome back")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("Sign in to manage your shared expenses")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 32)

                        // White card area
                        ScrollView {
                            VStack(spacing: 20) {
                                Spacer().frame(height: 8)

                                // Email
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("EMAIL")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(SplitEZTheme.primary)
                                        .tracking(1)
                                    TextField("you@email.com", text: $email)
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .padding(14)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(10)
                                }

                                // Password
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("PASSWORD")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(SplitEZTheme.primary)
                                        .tracking(1)
                                    HStack {
                                        if showPassword {
                                            TextField("••••••••", text: $password)
                                        } else {
                                            SecureField("••••••••", text: $password)
                                        }
                                        Button { showPassword.toggle() } label: {
                                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .textContentType(.password)
                                    .padding(14)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)

                                    HStack {
                                        Spacer()
                                        Button("Forgot password?") {
                                            showForgotPassword = true
                                        }
                                        .font(.caption)
                                        .foregroundColor(SplitEZTheme.primary)
                                    }
                                }

                                if let error {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }

                                Spacer().frame(height: 4)

                                // Sign In button (pill)
                                Button {
                                    Task { await login() }
                                } label: {
                                    if isLoading {
                                        ProgressView().tint(.white)
                                            .frame(maxWidth: .infinity, minHeight: 22)
                                    } else {
                                        Text("Sign In")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, minHeight: 22)
                                    }
                                }
                                .padding(.vertical, 14)
                                .background(SplitEZTheme.primary)
                                .clipShape(Capsule())
                                .disabled(email.isEmpty || password.isEmpty || isLoading)
                                .opacity(email.isEmpty || password.isEmpty ? 0.5 : 1)

                                // OR divider
                                HStack {
                                    Rectangle().fill(Color(.systemGray4)).frame(height: 1)
                                    Text("OR").font(.caption2).foregroundColor(.secondary)
                                    Rectangle().fill(Color(.systemGray4)).frame(height: 1)
                                }

                                // Social buttons
                                HStack(spacing: 12) {
                                    Button { } label: {
                                        HStack(spacing: 8) {
                                            Text("G").font(.title3.bold()).foregroundColor(.red)
                                            Text("Google").foregroundColor(.primary)
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color(.systemGray4), lineWidth: 1)
                                        )
                                    }

                                    Button { } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "apple.logo").foregroundColor(.primary)
                                            Text("Apple").foregroundColor(.primary)
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color(.systemGray4), lineWidth: 1)
                                        )
                                    }
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                // Sign up link
                                HStack(spacing: 4) {
                                    Text("Don't have an account?")
                                        .foregroundColor(.secondary)
                                    Button("Sign Up") { showRegister = true }
                                        .fontWeight(.bold)
                                        .foregroundColor(SplitEZTheme.primary)
                                }
                                .font(.subheadline)
                                .padding(.bottom, 16)
                            }
                            .padding(.horizontal, 28)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            Color(.systemBackground)
                                .clipShape(RoundedCorner(radius: 28, corners: [.topLeft, .topRight]))
                        )
                    }
                }
            }
            .navigationBarHidden(true)
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

// MARK: - Register Screen

struct RegisterView: View {
    @EnvironmentObject var auth: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var agreedToTerms = false
    @State private var isLoading = false
    @State private var error: String?
    @State private var showVerifyAlert = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                SplitEZTheme.darkBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Button { dismiss() } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .foregroundColor(.white)
                            }
                            Spacer()
                            SplitEZLogoSmall()
                        }
                        .padding(.top, 8)

                        Text("Create account")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("Start splitting expenses in seconds")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 32)

                    // White card
                    ScrollView {
                        VStack(spacing: 18) {
                            Spacer().frame(height: 4)

                            // Full Name
                            VStack(alignment: .leading, spacing: 6) {
                                Text("FULL NAME")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(SplitEZTheme.primary)
                                    .tracking(1)
                                TextField("Enter your name", text: $fullName)
                                    .textContentType(.name)
                                    .padding(14)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                            }

                            // Email
                            VStack(alignment: .leading, spacing: 6) {
                                Text("EMAIL")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(SplitEZTheme.primary)
                                    .tracking(1)
                                TextField("you@email.com", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding(14)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                            }

                            // Phone
                            VStack(alignment: .leading, spacing: 6) {
                                Text("PHONE")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(SplitEZTheme.primary)
                                    .tracking(1)
                                HStack(spacing: 8) {
                                    HStack(spacing: 4) {
                                        Text("🇮🇳")
                                        Text("+91").foregroundColor(.primary)
                                    }
                                    .padding(14)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)

                                    TextField("Phone number", text: $phone)
                                        .keyboardType(.phonePad)
                                        .padding(14)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(10)
                                }
                            }

                            // Password
                            VStack(alignment: .leading, spacing: 6) {
                                Text("PASSWORD")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(SplitEZTheme.primary)
                                    .tracking(1)
                                HStack {
                                    if showPassword {
                                        TextField("Create a password", text: $password)
                                    } else {
                                        SecureField("Create a password", text: $password)
                                    }
                                    Button { showPassword.toggle() } label: {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .textContentType(.newPassword)
                                .padding(14)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)

                                if !password.isEmpty {
                                    PasswordStrengthView(password: password)
                                }
                            }

                            if let error {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }

                            // Terms
                            HStack(alignment: .top, spacing: 10) {
                                Button { agreedToTerms.toggle() } label: {
                                    Image(systemName: agreedToTerms ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(agreedToTerms ? SplitEZTheme.primary : .gray)
                                }
                                (Text("I agree to the ")
                                 + Text("Terms of Service").foregroundColor(SplitEZTheme.primary)
                                 + Text(" and ")
                                 + Text("Privacy Policy").foregroundColor(SplitEZTheme.primary))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            // Create Account button (pill)
                            Button {
                                Task { await register() }
                            } label: {
                                if isLoading {
                                    ProgressView().tint(.white)
                                        .frame(maxWidth: .infinity, minHeight: 22)
                                } else {
                                    Text("Create Account")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, minHeight: 22)
                                }
                            }
                            .padding(.vertical, 14)
                            .background(SplitEZTheme.primary)
                            .clipShape(Capsule())
                            .disabled(fullName.isEmpty || email.isEmpty || password.count < 8 || !agreedToTerms || isLoading)
                            .opacity(fullName.isEmpty || email.isEmpty || password.count < 8 || !agreedToTerms ? 0.5 : 1)

                            // OR divider
                            HStack {
                                Rectangle().fill(Color(.systemGray4)).frame(height: 1)
                                Text("OR").font(.caption2).foregroundColor(.secondary)
                                Rectangle().fill(Color(.systemGray4)).frame(height: 1)
                            }

                            // Social buttons
                            HStack(spacing: 12) {
                                Button { } label: {
                                    HStack(spacing: 8) {
                                        Text("G").font(.title3.bold()).foregroundColor(.red)
                                        Text("Google").foregroundColor(.primary)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                                }

                                Button { } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "apple.logo").foregroundColor(.primary)
                                        Text("Apple").foregroundColor(.primary)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                                }
                            }
                            .buttonStyle(.plain)

                            Spacer().frame(height: 20)
                        }
                        .padding(.horizontal, 28)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        Color(.systemBackground)
                            .clipShape(RoundedCorner(radius: 28, corners: [.topLeft, .topRight]))
                    )
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Check Your Email", isPresented: $showVerifyAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("We've sent a verification link to \(email). Please verify your email to activate your account.")
        }
    }

    private func register() async {
        isLoading = true
        error = nil
        let parts = fullName.split(separator: " ", maxSplits: 1)
        let firstName = String(parts.first ?? "")
        let lastName = parts.count > 1 ? String(parts[1]) : nil
        do {
            try await auth.register(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName
            )
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Forgot Password

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
                    .padding(14)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                Button {
                    Task {
                        isLoading = true
                        try? await AuthService.shared.forgotPassword(email: email)
                        isLoading = false
                        sent = true
                    }
                } label: {
                    if isLoading { ProgressView().tint(.white).frame(maxWidth: .infinity) }
                    else { Text("Send Reset Link").font(.headline).foregroundColor(.white).frame(maxWidth: .infinity) }
                }
                .padding(.vertical, 14)
                .background(SplitEZTheme.primary)
                .clipShape(Capsule())
                .disabled(email.isEmpty || isLoading)
                .opacity(email.isEmpty ? 0.5 : 1)

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
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(strength.color)
                        .frame(width: geo.size.width * strength.fraction, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: strength.fraction)
                }
            }
            .frame(height: 4)

            Text("Use 8+ characters with a mix of letters & numbers")
                .font(.caption2)
                .foregroundColor(SplitEZTheme.primary)
        }
    }
}
