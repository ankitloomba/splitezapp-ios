import SwiftUI

// To enable interstitial ads: add the GoogleMobileAds SPM package in Xcode
// (File → Add Package Dependencies → https://github.com/googleads/swift-package-manager-google-mobile-ads)
// then change `ADS_ENABLED = false` to `true` below and uncomment the AdMob imports.

private let ADS_ENABLED = false

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@MainActor
final class InterstitialAdManager: NSObject, ObservableObject {
    static let shared = InterstitialAdManager()

    private let adUnitID = "ca-app-pub-2574042432872288/3272890896"

    private var showCount = 0
    private let maxShowsPerDay = Int.random(in: 1...3)
    private var lastResetDate: Date?

    private override init() { super.init() }

    func configure() {
        guard ADS_ENABLED else { return }
        #if canImport(GoogleMobileAds)
        GADMobileAds.sharedInstance().start { _ in }
        loadAd()
        #endif
    }

    func showIfReady() {
        guard ADS_ENABLED else { return }
        let today = Calendar.current.startOfDay(for: Date())
        if lastResetDate != today {
            showCount = 0
            lastResetDate = today
        }
        guard showCount < maxShowsPerDay else { return }
        #if canImport(GoogleMobileAds)
        showAd()
        #endif
    }

    #if canImport(GoogleMobileAds)
    private var interstitialAd: GADInterstitialAd?

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

    private func showAd() {
        guard let ad = interstitialAd,
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        var topVC = rootVC
        while let presented = topVC.presentedViewController { topVC = presented }
        ad.present(fromRootViewController: topVC)
        showCount += 1
    }
    #endif
}

#if canImport(GoogleMobileAds)
extension InterstitialAdManager: GADFullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in self.interstitialAd = nil; self.loadAd() }
    }
    nonisolated func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in self.interstitialAd = nil; self.loadAd() }
    }
}
#endif
