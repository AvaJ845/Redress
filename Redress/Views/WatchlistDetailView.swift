import SwiftUI

struct WatchlistDetailView: View {
    let watchlistCase: WatchlistCase

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label("Just filed — not a settlement", systemImage: "exclamationmark.triangle")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)

                Text(watchlistCase.caseName).font(.title2.bold())
                Text(watchlistCase.company).foregroundStyle(.secondary)

                GroupBox("Court") {
                    Text("\(watchlistCase.court) — \(watchlistCase.docketNumber)")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                GroupBox("Filed") {
                    Text(watchlistCase.dateFiled.formatted(date: .long, time: .omitted))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text(watchlistCase.summary)
                    .font(.body)

                if let sourceURL = watchlistCase.sourceURL {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Link(destination: sourceURL) {
                            Text("Source: \(watchlistCase.sourceName)")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if let docketURL = watchlistCase.docketURL {
                    Link(destination: docketURL) {
                        Label("View the real court docket", systemImage: "arrow.up.right.square")
                    }
                    .padding(.top, 4)
                }

                GroupBox {
                    Text("There is nothing to claim yet. No settlement, administrator, deadline, or claim form exists for this case. If that changes, Redress will only show it as an actual settlement once it's been verified against the administrator's official site — never before.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Watching")
        .navigationBarTitleDisplayMode(.inline)
    }
}
