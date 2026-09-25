import SwiftUI

enum SplitEZTheme {
    // Core palette — matches brand guidelines
    static let primary = Color(hex: "4338CA")        // Deep indigo
    static let primaryLight = Color(hex: "818CF8")   // Light indigo
    static let accent = Color(hex: "818CF8")         // Light indigo (logo left)
    static let darkBg = Color(hex: "10142A")         // Deep navy (header/splash bg)
    static let darkBgLighter = Color(hex: "1A1E3A")  // Slightly lighter navy
    static let destructive = Color(hex: "EB5757")    // Red
    static let positive = Color(hex: "2EC770")       // Green
    static let negative = Color(hex: "EB5757")       // Red
    static let muted = Color(hex: "5A6B82")          // Inactive/secondary

    // Surfaces
    static let cardBackground = Color.white
    static let secondaryBackground = Color(hex: "F5F7FA")
    static let surfaceAlt = Color(hex: "EDF1F7")
    static let pillActive = Color(hex: "4F46E5")
    static let pillInactive = Color(hex: "E8EDF4")
    static let divider = Color(hex: "D8E0EB")

    // Text
    static let textPrimary = Color(hex: "1A2233")
    static let textSecondary = Color(hex: "5A6B82")
    static let textTertiary = Color(hex: "8D9BB0")
    static let textOnDark = Color.white
    static let balanceGreen = Color(hex: "2EC770")
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
