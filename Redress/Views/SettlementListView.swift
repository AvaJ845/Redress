import SwiftUI
import SwiftData

struct SettlementListView: View {
    @Query(sort: \Settlement.claimDeadline) private var settlements: [Settlement]
    @Query private var claims: [Claim]
    @Environment(\.modelContext) private var context

    private var trackedSettlementIDs: Set<String> {
        Set(claims.map(\.settlementID))
    }

    var body: some View {
        NavigationStack {
            List(settlements, id: \.id) { settlement in
                NavigationLink {
                    SettlementDetailView(settlement: settlement)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(settlement.title).font(.headline)
                            if trackedSettlementIDs.contains(settlement.id) {
                                Label("Tracking", systemImage: "checkmark.circle.fill")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.green)
                            }
                        }
                        Text(settlement.brand)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Deadline: \(settlement.claimDeadline.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Open Settlements")
            .overlay {
                if settlements.isEmpty {
                    ContentUnavailableView(
                        "No settlements yet",
                        systemImage: "tray",
                        description: Text("Sample data will appear here once seeded.")
                    )
                }
            }
            .onAppear { SettlementCatalog.loadSeedIfNeeded(into: context) }
        }
    }
}
