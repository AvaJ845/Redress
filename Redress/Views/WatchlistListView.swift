import SwiftUI
import SwiftData

struct WatchlistListView: View {
    @Query(sort: \WatchlistCase.dateFiled, order: .reverse) private var cases: [WatchlistCase]
    @Environment(\.modelContext) private var context

    var body: some View {
        List {
            Section {
                Text("These are lawsuits that were just filed — not settlements. There's no claim to file and nothing to submit here. They may or may not ever become a real settlement.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            ForEach(cases, id: \.id) { watchlistCase in
                NavigationLink {
                    WatchlistDetailView(watchlistCase: watchlistCase)
                } label: {
                    Card {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(watchlistCase.caseName).font(.headline)
                            Text(watchlistCase.company)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Filed \(watchlistCase.dateFiled.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.pageBackground)
        .overlay {
            if cases.isEmpty {
                ContentUnavailableView(
                    "Nothing on the watchlist",
                    systemImage: "eye",
                    description: Text("Recently filed lawsuits that might become settlements will show up here.")
                )
            }
        }
        .onAppear { WatchlistCatalog.loadIfNeeded(into: context) }
    }
}
