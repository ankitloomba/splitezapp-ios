import SwiftUI
import GoogleMobileAds

@MainActor
final class InterstitialAdManager: NSObject, ObservableObject {
    static let shared = InterstitialAdManager()

    // TODO: Replace with your production interstitial ad unit ID
    private let adUnitID = "ca-app-pub-3940256099942544/4411468910" // Test ID

    private var interstitialAd: GADInterstitialAd?
    private var showCount = 0
    private let maxShowsPerDay = Int.random(in: 1...3)
    private var lastResetDate: Date?

    private override init() {
        super.init()
    }

    func configure() {
        GADMobileAds.sharedInstance().start { _ in }
        loadAd()
    }

    private func loadAd() {
        GADInterstitialAd.load(withAdUnitID: adUnitID, request: GADRequest()) { [weak self] ad, error in
            guard let self else { return }
            if let error {
                print("Interstitial ad failed to load: \(error.localizedDescription)")
                return
            }
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
        }
    }

    func showIfReady() {
        let today = Calendar.current.startOfDay(for: Date())
        if lastResetDate != today {
            showCount = 0
            lastResetDate = today
        }

        guard showCount < maxShowsPerDay else { return }
        guard let ad = interstitialAd else { return }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        ad.present(fromRootViewController: topVC)
        showCount += 1
    }
}

extension InterstitialAdManager: GADFullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in
            self.interstitialAd = nil
            self.loadAd()
        }
    }

    nonisolated func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            self.interstitialAd = nil
            self.loadAd()
        }
    }
}
