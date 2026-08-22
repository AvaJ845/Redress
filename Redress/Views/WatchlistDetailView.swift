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

                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        detailRow(title: "Court", systemImage: "building.columns", text: "\(watchlistCase.court) — \(watchlistCase.docketNumber)")
                        Divider()
                        detailRow(title: "Filed", systemImage: "calendar", text: watchlistCase.dateFiled.formatted(date: .long, time: .omitted))
                    }
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

                Card {
                    Text("There is nothing to claim yet. No settlement, administrator, deadline, or claim form exists for this case. If that changes, Redress will only show it as an actual settlement once it's been verified against the administrator's official site — never before.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Watching")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func detailRow(title: String, systemImage: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
