import SwiftUI
import SwiftData

struct ClaimListView: View {
    @Query(sort: \Claim.createdDate, order: .reverse) private var claims: [Claim]

    var body: some View {
        NavigationStack {
            List(claims, id: \.id) { claim in
                NavigationLink {
                    ClaimDetailView(claim: claim)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(claim.settlementTitle).font(.headline)
                        ClaimStatusBadge(status: claim.status)
                    }
                    .padding(.vertical, 4)
                }
            }
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
