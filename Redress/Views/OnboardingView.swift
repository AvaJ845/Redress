import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        VStack(spacing: 0) {
            // The privacy text must never be allowed to clip or truncate —
            // it's the one thing this screen exists to actually convey. A
            // fixed Spacer()-based layout looked fine at normal text sizes
            // but silently truncated it ("protected by iO…") at large
            // accessibility sizes, since there was no ScrollView to fall
            // back on when the content simply doesn't fit the screen.
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 24)

                    Image(systemName: "shield.checkerboard")
                        .font(.system(size: 56))
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)

                    Text("Redress")
                        .font(.largeTitle.bold())

                    Text(AppLegal.privacyPolicySummary)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    Spacer(minLength: 24)
                }
                .padding(.top, 24)
            }

            Button {
                hasSeenOnboarding = true
                dismiss()
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .padding(.vertical, 16)
        }
        .interactiveDismissDisabled()
    }
}
