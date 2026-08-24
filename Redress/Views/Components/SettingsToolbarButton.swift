import SwiftUI

/// Shared "person.circle" toolbar button presenting Settings as a sheet —
/// used on Home, Claims, and Discover so it's reachable from every tab
/// without needing its own tab-bar slot (Apple's own guidance: settings
/// isn't "the product," so it shouldn't get equal billing with
/// Home/Claims/Discover in the tab bar). Named "Settings" throughout —
/// this button, the iPad sidebar row, and the sheet's own navigation
/// title (SettingsView.swift) all present the exact same screen, so they
/// must all call it the same thing.
private struct SettingsToolbarButton: ViewModifier {
    @State private var showingSettings = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "person.circle")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
    }
}

extension View {
    func settingsToolbarButton() -> some View {
        modifier(SettingsToolbarButton())
    }
}
