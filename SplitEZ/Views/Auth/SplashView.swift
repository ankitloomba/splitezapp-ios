import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(hex: "#10142A").ignoresSafeArea()
            VStack(spacing: 24) {
                SplitEZLogo(size: 72)
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color(hex: "#818CF8"))
                    .scaleEffect(1.2)
            }
        }
    }
}
