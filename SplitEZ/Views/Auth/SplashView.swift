import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(hex: "#10142A").ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                SplitEZLogo(size: 60)
                Spacer().frame(height: 20)
                Text("SplitEZ")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                Text("Split smarter. Settle faster.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(hex: "#818CF8"))
                    .padding(.top, 6)
                Spacer()
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color(hex: "#818CF8"))
                    .scaleEffect(1.2)
                    .padding(.bottom, 60)
            }
        }
    }
}
