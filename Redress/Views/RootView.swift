import SwiftUI

enum RootSection: String, CaseIterable, Identifiable {
    case home, claims, discover, account

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .claims: return "Claims"
        case .discover: return "Discover"
        case .account: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .claims: return "checklist"
        case .discover: return "magnifyingglass"
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

/// iPhone / compact width — a bottom tab bar with just the three things
/// that are actually the product. Settings lives behind a toolbar icon
/// on each tab instead of taking a fourth slot: it isn't "the product,"
/// so it shouldn't get equal billing with Home, Claims, and Discover in
/// the one piece of chrome that's always on screen.
private struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label(RootSection.home.title, systemImage: RootSection.home.icon) }
            ClaimListView()
                .tabItem { Label(RootSection.claims.title, systemImage: RootSection.claims.icon) }
            DiscoverView()
                .tabItem { Label(RootSection.discover.title, systemImage: RootSection.discover.icon) }
        }
    }
}

/// iPad / regular width — a sidebar, per HIG guidance that a bottom tab
/// bar is an iPhone pattern, not an iPad one. Settings keeps its own
/// sidebar row here since a sidebar isn't as space-constrained as a
/// four-icon tab bar — the "stay out of the way" pressure that pushed
/// Settings into a toolbar button on iPhone doesn't apply the same way.
private struct RootSplitView: View {
    @State private var selection: RootSection? = .home

    var body: some View {
        NavigationSplitView {
            List(RootSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.icon).tag(section)
            }
            .navigationTitle("Redress")
        } detail: {
            switch selection {
            case .home:
                HomeView()
            case .claims:
                ClaimListView()
            case .discover:
                DiscoverView()
            case .account:
                SettingsView()
            case .none:
                ContentUnavailableView("Select a section", systemImage: "sidebar.left")
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
