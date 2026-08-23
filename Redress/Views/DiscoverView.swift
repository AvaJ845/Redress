import SwiftUI

/// "New settlements and opportunities" — merges what used to be two
/// separate top-level tabs (Open Settlements, Watching) into one, since
/// they're the same activity from the user's point of view: looking for
/// something new. A segmented control switches between them instead of
/// spending a second tab-bar slot on a screen that's structurally "the
/// same kind of browsing, earlier in the pipeline."
struct DiscoverView: View {
    private enum Segment: String, CaseIterable, Identifiable {
        case settlements = "Settlements"
        case watching = "Watching"
        var id: String { rawValue }
    }

    @State private var segment: Segment = .settlements

    var body: some View {
        NavigationStack {
            Group {
                switch segment {
                case .settlements:
                    SettlementListView()
                case .watching:
                    WatchlistListView()
                }
            }
            .navigationTitle("Discover")
            .profileToolbarButton()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Section", selection: $segment) {
                        ForEach(Segment.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 260)
                }
            }
        }
    }
}
