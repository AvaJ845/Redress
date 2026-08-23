import SwiftUI

/// Distinct from Settlements/Watching on purpose: there's nothing here to
/// track. Unclaimed property is a per-person lookup against each state's
/// own database, not an open claims window anyone can browse — so unlike
/// the rest of the app, there's no "Start Claim" here, just a real link
/// to the real official site. Redress never searches on your behalf.
struct UnclaimedPropertyView: View {
    var body: some View {
        List {
            Section {
                Text("Unclaimed property is money a state is already holding for you — an old refund, a forgotten deposit, an uncashed check — separate from class-action settlements. Each state runs its own free, official search. Redress doesn't search on your behalf or store what you find; tap your state to search directly on its real government site.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            Section {
                ForEach(UnclaimedPropertyDirectory.sources) { source in
                    if let url = source.url {
                        Link(destination: url) {
                            HStack {
                                Text(source.state)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundStyle(.secondary)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isLink)
                        .accessibilityHint("Opens \(source.state)'s official unclaimed property search")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Unclaimed Property")
        .navigationBarTitleDisplayMode(.inline)
    }
}
