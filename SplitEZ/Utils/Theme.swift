import SwiftUI

enum SplitEZTheme {
    // Core palette — aligned with artifact design
    static let primary = Color(hex: "3890F5")        // Blue
    static let primaryLight = Color(hex: "5BA8F7")   // Light blue
    static let accent = Color(hex: "22D4A6")         // Teal
    static let darkBg = Color(hex: "1A2233")         // Dark surface (cards in dark mode)
    static let destructive = Color(hex: "EB5757")    // Red
    static let positive = Color(hex: "2EC770")       // Green
    static let negative = Color(hex: "EB5757")       // Red
    static let muted = Color(hex: "5A6B82")          // Inactive/secondary

    // Surfaces
    static let cardBackground = Color(.systemBackground)
    static let secondaryBackground = Color(hex: "F5F7FA")
    static let surfaceAlt = Color(hex: "EDF1F7")
    static let pillActive = Color(hex: "3890F5")
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
