import SwiftUI

enum SplitEZTheme {
    // Core palette — aligned with design spec
    static let primary = Color(hex: "4338CA")       // Indigo
    static let primaryLight = Color(hex: "C7D2FE")  // Light indigo
    static let accent = Color(hex: "EEF0FF")        // Tinted surface
    static let darkBg = Color(hex: "10142A")         // Deep navy header
    static let destructive = Color(hex: "DC2626")    // Red
    static let positive = Color(hex: "4ADE80")       // Green
    static let negative = Color(hex: "DC2626")       // Red
    static let muted = Color(hex: "8792A8")          // Inactive/secondary

    // Surfaces
    static let cardBackground = Color(.systemBackground)
    static let secondaryBackground = Color(hex: "F1F5F9")
    static let pillActive = Color(hex: "4338CA")
    static let pillInactive = Color(hex: "F1F5F9")
    static let divider = Color(hex: "EEF0F4")

    // Text
    static let textSecondary = Color(hex: "64748B")
    static let textOnDark = Color.white
    static let balanceGreen = Color(hex: "16A34A")
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
