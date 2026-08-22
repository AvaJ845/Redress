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
                    SettlementRow(settlement: settlement, isTracking: trackedSettlementIDs.contains(settlement.id))
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
            .listStyle(.plain)
            .navigationTitle("Open Settlements")
            .overlay {
                if settlements.isEmpty {
                    ContentUnavailableView(
                        "No settlements yet",
                        systemImage: "tray",
                        description: Text("Real, verified settlements will appear here as they're reviewed.")
                    )
                }
            }
            .onAppear { SettlementCatalog.loadSeedIfNeeded(into: context) }
        }
    }
}

private struct SettlementRow: View {
    let settlement: Settlement
    let isTracking: Bool

    private var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: settlement.claimDeadline).day ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(settlement.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                if isTracking {
                    Label("Tracking", systemImage: "checkmark.circle.fill")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.green)
                        .labelStyle(.iconOnly)
                        .accessibilityLabel("Tracking")
                }
            }

            Text(settlement.brand)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !settlement.payoutText.isEmpty {
                Label(settlement.payoutText, systemImage: "dollarsign.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.accentColor)
                    .lineLimit(2)
            }

            HStack(spacing: 4) {
                Image(systemName: "calendar")
                Text(settlement.claimDeadline.formatted(date: .abbreviated, time: .omitted))
                Text("·")
                Text(daysRemaining > 0 ? "\(daysRemaining) days left" : "closing soon")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
    }
}
