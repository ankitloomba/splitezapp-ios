import SwiftUI
import Observation

/// Manages server-driven ad placements. Fetches ad config from backend
/// so ads can be controlled without app updates.
@Observable
@MainActor
final class AdManager {
    static let shared = AdManager()

    var placements: [String: AdPlacement] = [:]
    var isAdFree = false  // Set true for premium users

    private let api = APIClient.shared

    /// Fetch ad placements for the current screen from the backend.
    func loadPlacements(screen: String) async {
        do {
            let items: [AdPlacement] = try await api.get(
                "/ads/placements",
                query: ["screen": screen, "platform": "ios"]
            )
            for item in items {
                placements[item.name] = item
            }
        } catch {
            // Non-critical — app works without ads
        }
    }

    /// Get the ad unit ID for a named placement, if it exists and user isn't ad-free.
    func adUnit(for name: String) -> String? {
        guard !isAdFree else { return nil }
        guard let placement = placements[name] else { return nil }
        if placement.adFreeSkip == true && isAdFree { return nil }
        return placement.adUnitIos
    }

    /// Check if a placement exists and should be shown.
    func shouldShow(_ name: String) -> Bool {
        guard !isAdFree else { return false }
        return placements[name] != nil
    }
}

/// Placeholder banner ad view. Replace the body with actual Google Mobile Ads
/// SDK (GADBannerView via UIViewRepresentable) once the SDK is integrated.
struct AdBannerView: View {
    let adUnitId: String

    var body: some View {
        Rectangle()
            .fill(SplitEZTheme.secondaryBackground)
            .frame(height: 50)
            .overlay(
                Text("Ad")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            )
            .cornerRadius(12)
    }
}

/// Convenience view that checks AdManager and shows/hides an ad banner.
struct AdBannerSlot: View {
    let placementName: String
    private var adManager = AdManager.shared

    var body: some View {
        if let adUnit = adManager.adUnit(for: placementName) {
            AdBannerView(adUnitId: adUnit)
                .padding(.horizontal)
        }
    }
}
