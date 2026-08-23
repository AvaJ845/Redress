import SwiftUI

/// Grouped surface used for primary content blocks — one consistent style
/// across the app instead of the ad hoc RoundedRectangle/background calls
/// that had accumulated per-view. Same shape and convention as Hummingbird's
/// Card component — a shared portfolio pattern, not reinvented per app.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.cardBackground)
            )
            .accessibilityElement(children: .contain)
    }
}
