import SwiftUI

/// Shared "person.circle" toolbar button presenting Settings as a sheet —
/// used on Home, Claims, and Discover so Profile is reachable from every
/// tab without needing its own tab-bar slot (Apple's own guidance:
/// settings isn't "the product," so it shouldn't get equal billing with
/// Home/Claims/Discover in the tab bar).
private struct ProfileToolbarButton: ViewModifier {
    @State private var showingProfile = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingProfile = true
                    } label: {
                        Image(systemName: "person.circle")
                    }
                    .accessibilityLabel("Profile")
                }
            }
            .sheet(isPresented: $showingProfile) {
                SettingsView()
            }
    }
}

extension View {
    func profileToolbarButton() -> some View {
        modifier(ProfileToolbarButton())
    }
}
