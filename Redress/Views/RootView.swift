import SwiftUI

enum RootSection: String, CaseIterable, Identifiable {
    case settlements, claims, account

    var id: String { rawValue }

    var title: String {
        switch self {
        case .settlements: return "Settlements"
        case .claims: return "My Claims"
        case .account: return "Account"
        }
    }

    var icon: String {
        switch self {
        case .settlements: return "magnifyingglass"
        case .claims: return "checklist"
        case .account: return "person.circle"
        }
    }
}

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                RootSplitView()
            } else {
                RootTabView()
            }
        }
        .sheet(isPresented: .constant(!hasSeenOnboarding)) {
            OnboardingView()
        }
    }
}

/// iPhone / compact width — a bottom tab bar, per HIG guidance for a small
/// number of top-level sections on a compact-width device.
private struct RootTabView: View {
    var body: some View {
        TabView {
            SettlementListView()
                .tabItem { Label(RootSection.settlements.title, systemImage: RootSection.settlements.icon) }
            ClaimListView()
                .tabItem { Label(RootSection.claims.title, systemImage: RootSection.claims.icon) }
            SettingsView()
                .tabItem { Label(RootSection.account.title, systemImage: RootSection.account.icon) }
        }
    }
}

/// iPad / regular width — a sidebar, per HIG guidance that a bottom tab bar
/// is an iPhone pattern, not an iPad one, for this many top-level sections.
private struct RootSplitView: View {
    @State private var selection: RootSection? = .settlements

    var body: some View {
        NavigationSplitView {
            List(RootSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.icon).tag(section)
            }
            .navigationTitle("Redress")
        } detail: {
            switch selection {
            case .settlements:
                SettlementListView()
            case .claims:
                ClaimListView()
            case .account:
                SettingsView()
            case .none:
                ContentUnavailableView("Select a section", systemImage: "sidebar.left")
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
