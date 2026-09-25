import SwiftUI

enum SplitEZTheme {
    // Core palette
    static let primary      = Color(hex: "4338CA")
    static let primaryLight = Color(hex: "818CF8")
    static let accent       = Color(hex: "818CF8")
    static let darkBg       = Color(hex: "10142A")   // deep navy header
    static let darkBgLighter = Color(hex: "1A1E3A")  // slightly lighter navy
    static let destructive  = Color(hex: "EB5757")
    static let positive     = Color(hex: "2EC770")
    static let negative     = Color(hex: "EB5757")
    static let muted        = Color(hex: "5A6B82")
    static let balanceGreen = Color(hex: "2EC770")

    static let pillActive = Color(hex: "4F46E5")
    static let textOnDark = Color.white

    // Adaptive surfaces — resolved at render time via UIScreen trait collection
    static var isDark: Bool {
        UIScreen.main.traitCollection.userInterfaceStyle == .dark
    }

    static var cardBg: Color        { isDark ? Color(hex: "1A1E3A") : .white }
    static var pageBg: Color        { isDark ? Color(hex: "10142A") : Color(red: 0.95, green: 0.95, blue: 0.97) }
    static var rowAltBg: Color      { isDark ? Color(hex: "1E2448") : Color(red: 0.98, green: 0.98, blue: 0.99) }
    static var divider: Color       { isDark ? Color(hex: "2A2E50") : Color(red: 0.85, green: 0.87, blue: 0.90) }
    static var pillInactive: Color  { isDark ? Color(hex: "262B4A") : Color(red: 0.91, green: 0.93, blue: 0.96) }
    static var surfaceAlt: Color    { isDark ? Color(hex: "1E2448") : Color(hex: "EDF1F7") }

    // Adaptive text
    static var textPrimary: Color   { isDark ? .white : Color(hex: "1A2233") }
    static var textSecondary: Color { isDark ? Color(hex: "8892B4") : Color(hex: "5A6B82") }
    static var textTertiary: Color  { isDark ? Color(hex: "555E80") : Color(hex: "8D9BB0") }

    // Legacy aliases
    static var cardBackground: Color    { cardBg }
    static var secondaryBackground: Color { pageBg }
}

struct AvatarView: View {
    let user: UserSummary
    var size: CGFloat = 40

    var body: some View {
        if let pic = user.profilePicture, let url = URL(string: pic) {
            AsyncImage(url: url) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                initialsView
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            initialsView
        }
    }

    private var initialsView: some View {
        Circle()
            .fill(avatarColor)
            .frame(width: size, height: size)
            .overlay(
                Text(user.avatar?.initials ?? String(user.firstName.prefix(1)).uppercased())
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(.white)
            )
    }

    private var avatarColor: Color {
        if let bg = user.avatar?.backgroundColor {
            return Color(hex: bg)
        }
        return SplitEZTheme.primary
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255.0
        let g = CGFloat((int >> 8) & 0xFF) / 255.0
        let b = CGFloat(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - Swipe-back gesture fix

/// Embed as .background(SwipeBackEnabler()) on any view that uses
/// .navigationBarBackButtonHidden(true). It walks the responder chain
/// after layout to find the UINavigationController and re-enables
/// interactivePopGestureRecognizer, which SwiftUI disables when the
/// back button is hidden.
struct SwipeBackEnabler: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.backgroundColor = .clear
        v.isUserInteractionEnabled = false
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            guard let nav = uiView.parentNavigationController else { return }
            nav.interactivePopGestureRecognizer?.isEnabled = true
            nav.interactivePopGestureRecognizer?.delegate = context.coordinator
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let nav = gestureRecognizer.view?.parentNavigationController else { return true }
            return nav.viewControllers.count > 1
        }
    }
}

extension UIView {
    var parentNavigationController: UINavigationController? {
        var responder: UIResponder? = self
        while let r = responder {
            if let nav = r as? UINavigationController { return nav }
            responder = r.next
        }
        return nil
    }
}

extension View {
    /// Re-enables swipe-back on screens with a custom nav bar.
    func enableSwipeBack() -> some View {
        self.background(SwipeBackEnabler())
    }
}
