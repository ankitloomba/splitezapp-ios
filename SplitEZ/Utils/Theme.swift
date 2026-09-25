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

    // Adaptive colors — use UIColor(dynamicProvider:) so the closure receives the
    // VIEW's trait collection, which correctly reflects overrideUserInterfaceStyle
    // and preferredColorScheme. Never read UIScreen.main.traitCollection here.
    static let textPrimary   = Color(UIColor { t in t.userInterfaceStyle == .dark ? .white                    : UIColor(hex: "1A2233") })
    static let textSecondary = Color(UIColor { t in t.userInterfaceStyle == .dark ? UIColor(hex: "7D8EAE")   : UIColor(hex: "5A6B82") })
    static let textTertiary  = Color(UIColor { t in t.userInterfaceStyle == .dark ? UIColor(hex: "4A5573")   : UIColor(hex: "8D9BB0") })
    static let cardBg        = Color(UIColor { t in t.userInterfaceStyle == .dark ? UIColor(hex: "141929")   : .white })
    static let pageBg        = Color(UIColor { t in t.userInterfaceStyle == .dark ? UIColor(hex: "0E1222")   : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1) })
    static let rowAltBg      = Color(UIColor { t in t.userInterfaceStyle == .dark ? UIColor(hex: "1A1F3A")   : UIColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1) })
    static let divider       = Color(UIColor { t in t.userInterfaceStyle == .dark ? UIColor(hex: "1E2544")   : UIColor(red: 0.85, green: 0.87, blue: 0.90, alpha: 1) })
    static let pillInactive  = Color(UIColor { t in t.userInterfaceStyle == .dark ? UIColor(hex: "1C2340")   : UIColor(red: 0.91, green: 0.93, blue: 0.96, alpha: 1) })
    static let surfaceAlt    = Color(UIColor { t in t.userInterfaceStyle == .dark ? UIColor(hex: "1A1F3A")   : UIColor(hex: "EDF1F7") })

    // Legacy aliases
    static let cardBackground: Color       = cardBg
    static let secondaryBackground: Color  = pageBg
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
