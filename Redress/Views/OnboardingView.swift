import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "shield.checkerboard")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text("Redress")
                .font(.largeTitle.bold())

            Text(AppLegal.privacyPolicySummary)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Spacer()

            Button {
                hasSeenOnboarding = true
                dismiss()
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .interactiveDismissDisabled()
    }
}
