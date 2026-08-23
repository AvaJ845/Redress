import SwiftUI
import SwiftData

/// Grouped by status instead of a flat list, so an active claim needing
/// attention doesn't get buried under old paid/rejected ones sorted only
/// by date. Section order follows ClaimStatus.allCases' own declared
/// lifecycle order (discovered → filed → underReview → appealPeriod →
/// paid → rejected) — non-terminal states first, terminal ones last —
/// reusing the ordering already encoded in the model rather than
/// inventing a second one.
struct ClaimListView: View {
    @Query(sort: \Claim.createdDate, order: .reverse) private var claims: [Claim]

    private var groupedClaims: [(status: ClaimStatus, claims: [Claim])] {
        let byStatus = Dictionary(grouping: claims, by: \.status)
        return ClaimStatus.allCases.compactMap { status in
            guard let claimsForStatus = byStatus[status], !claimsForStatus.isEmpty else { return nil }
            return (status, claimsForStatus)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedClaims, id: \.status) { group in
                    Section {
                        ForEach(group.claims, id: \.id) { claim in
                            NavigationLink {
                                ClaimDetailView(claim: claim)
                            } label: {
                                Card {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(claim.settlementTitle).font(.headline)
                                        ClaimStatusBadge(status: claim.status)
                                    }
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    } header: {
                        Text(group.status.displayName)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Claims")
            .overlay {
                if claims.isEmpty {
                    ContentUnavailableView(
                        "No claims yet",
                        systemImage: "checklist",
                        description: Text("Start a claim from the Settlements tab.")
                    )
                }
            }
        }
    }
}
