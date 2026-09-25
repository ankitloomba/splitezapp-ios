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

    // Set synchronously at the top of SplitEZApp.body before any child views render.
    // SplitEZApp reads @Environment(\.colorScheme) and appSettings.themeMode
    // then calls SplitEZTheme.updateIsDark(_:) before the Group that holds MainTabView.
    static var _isDark: Bool = false

    static func updateIsDark(colorScheme: ColorScheme, themeMode: Int) {
        switch themeMode {
        case 0: _isDark = true
        case 1: _isDark = false
        default: _isDark = (colorScheme == .dark)
        }
    }

    // Adaptive colors — read _isDark which is set before every render pass
    static var textPrimary:   Color { _isDark ? .white                            : Color(hex: "1A2233") }
    static var textSecondary: Color { _isDark ? Color(hex: "7D8EAE")              : Color(hex: "5A6B82") }
    static var textTertiary:  Color { _isDark ? Color(hex: "4A5573")              : Color(hex: "8D9BB0") }
    static var cardBg:        Color { _isDark ? Color(hex: "141929")              : .white }
    static var pageBg:        Color { _isDark ? Color(hex: "0E1222")              : Color(red: 0.95, green: 0.95, blue: 0.97) }
    static var rowAltBg:      Color { _isDark ? Color(hex: "1A1F3A")             : Color(red: 0.98, green: 0.98, blue: 0.99) }
    static var divider:       Color { _isDark ? Color(hex: "1E2544")              : Color(red: 0.85, green: 0.87, blue: 0.90) }
    static var pillInactive:  Color { _isDark ? Color(hex: "1C2340")              : Color(red: 0.91, green: 0.93, blue: 0.96) }
    static var surfaceAlt:    Color { _isDark ? Color(hex: "1A1F3A")             : Color(hex: "EDF1F7") }

    // Legacy aliases
    static var cardBackground:       Color { cardBg }
    static var secondaryBackground:  Color { pageBg }
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
