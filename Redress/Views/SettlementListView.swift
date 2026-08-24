import SwiftUI
import SwiftData

/// Purely a client-side view filter over data already on-device — no
/// dollar totals are ever computed here. `payoutText` is deliberately
/// free text (settlements without a fixed amount say so, e.g.
/// "no fixed amount, no cap stated"), so summing across settlements would
/// mean guessing numbers out of ranges and conditionals. Counting
/// settlements is honest; adding up their payouts wouldn't be.
private enum SettlementFilter: String, CaseIterable, Identifiable {
    case all, noProofRequired, proofRequired, deadlineSoon

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .noProofRequired: "No proof required"
        case .proofRequired: "Proof required"
        case .deadlineSoon: "Deadline soon"
        }
    }

    func matches(_ settlement: Settlement) -> Bool {
        switch self {
        case .all:
            return true
        case .noProofRequired:
            return settlement.proofRequirement == .none || settlement.proofRequirement == .selfCertify
        case .proofRequired:
            return settlement.proofRequirement == .flexibleProof || settlement.proofRequirement == .strictProof
        case .deadlineSoon:
            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: settlement.claimDeadline).day ?? Int.max
            return daysRemaining <= 30
        }
    }
}

struct SettlementListView: View {
    @Query(sort: \Settlement.claimDeadline) private var settlements: [Settlement]
    @Query private var claims: [Claim]
    @Environment(\.modelContext) private var context
    @State private var filter: SettlementFilter = .all

    private var trackedSettlementIDs: Set<String> {
        Set(claims.map(\.settlementID))
    }

    private var filteredSettlements: [Settlement] {
        settlements.filter(filter.matches)
    }

    private var summaryText: String {
        let count = filteredSettlements.count
        let noun = count == 1 ? "open settlement" : "open settlements"
        guard filter != .all else { return "\(count) \(noun)" }
        return "\(count) \(noun) · \(filter.title.lowercased())"
    }

    var body: some View {
        List {
            if !settlements.isEmpty {
                Section {
                    Text(summaryText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            ForEach(filteredSettlements, id: \.id) { settlement in
                NavigationLink {
                    SettlementDetailView(settlement: settlement)
                } label: {
                    SettlementRow(settlement: settlement, isTracking: trackedSettlementIDs.contains(settlement.id))
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.pageBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Filter", selection: $filter) {
                        ForEach(SettlementFilter.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                } label: {
                    Label(
                        "Filter",
                        systemImage: filter == .all
                            ? "line.3.horizontal.decrease.circle"
                            : "line.3.horizontal.decrease.circle.fill"
                    )
                }
                .accessibilityLabel(filter == .all ? "Filter settlements" : "Filter settlements, \(filter.title) active")
            }
        }
        .overlay {
            if settlements.isEmpty {
                ContentUnavailableView(
                    "No settlements yet",
                    systemImage: "tray",
                    description: Text("Real, verified settlements will appear here as they're reviewed.")
                )
            } else if filteredSettlements.isEmpty {
                ContentUnavailableView(
                    "No matches",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("No open settlements match this filter right now.")
                )
            }
        }
        .onAppear { SettlementCatalog.loadSeedIfNeeded(into: context) }
    }
}

private struct SettlementRow: View {
    let settlement: Settlement
    let isTracking: Bool

    private var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: settlement.claimDeadline).day ?? 0
    }

    /// Icon + weight + color together, never color alone, matching the
    /// same pairing rule ClaimStatusBadge already enforces elsewhere in
    /// this app. A week is close enough to matter but not so wide that
    /// most rows end up flagged.
    private var isUrgent: Bool {
        (0...7).contains(daysRemaining)
    }

    private var category: SettlementCategory {
        SettlementCategory.classify(
            title: settlement.title,
            brand: settlement.brand,
            description: settlement.settlementDescription
        )
    }

    var body: some View {
        Card {
            HStack(alignment: .top, spacing: 12) {
                CategoryIconBadge(category: category)

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

                    if !settlement.isFullyVerified {
                        Label("Pending review", systemImage: "clock.badge.questionmark")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.orange)
                    }

                    if !settlement.payoutText.isEmpty {
                        Label(settlement.payoutText, systemImage: "dollarsign.circle.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.accentColor)
                            .lineLimit(2)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: isUrgent ? "exclamationmark.triangle.fill" : "calendar")
                        Text(settlement.claimDeadline.formatted(date: .abbreviated, time: .omitted))
                        Text("·")
                        Text(daysRemaining > 0 ? "\(daysRemaining) days left" : "closing soon")
                    }
                    .font(.caption.weight(isUrgent ? .semibold : .regular))
                    .foregroundStyle(isUrgent ? .orange : .secondary)
                }
            }
        }
    }
}
