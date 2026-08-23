import SwiftUI
import SwiftData

/// The answer to "what money can I claim?" — synthesized entirely from
/// what's already on-device (settlements + claims already stored
/// locally), never a fetched personalized feed. No dollar total is ever
/// shown here: payoutText is deliberately free text — many settlements
/// have no fixed amount (see Breckenridge: "no fixed amount, no cap
/// stated") — so summing it would mean guessing across ranges and
/// conditionals this app has always refused to invent. The honest
/// version of "your money" is what's real: how many things exist, and
/// which ones need attention soonest.
struct HomeView: View {
    @Query(sort: \Settlement.claimDeadline) private var settlements: [Settlement]
    @Query(sort: \Claim.createdDate, order: .reverse) private var claims: [Claim]
    @Environment(\.modelContext) private var context

    private var trackedSettlementIDs: Set<String> {
        Set(claims.map(\.settlementID))
    }

    private var activeClaims: [Claim] {
        claims.filter { !$0.status.isTerminal }
    }

    /// Fully-verified settlements only — Home is where a first-time
    /// glance should build trust, not where the "pending review" tier
    /// (real but not yet detail-checked) makes its first impression.
    /// That tier still lives in Discover, one tap away.
    private var deadlineSoonSettlements: [Settlement] {
        settlements.filter { settlement in
            guard settlement.isFullyVerified else { return false }
            let days = Calendar.current.dateComponents([.day], from: Date(), to: settlement.claimDeadline).day ?? Int.max
            return (0...14).contains(days)
        }
    }

    private var newSettlements: [Settlement] {
        settlements.filter { $0.isFullyVerified && !trackedSettlementIDs.contains($0.id) }
    }

    private var hasNothingYet: Bool {
        settlements.isEmpty && claims.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header

                    if hasNothingYet {
                        ContentUnavailableView(
                            "Nothing yet",
                            systemImage: "tray",
                            description: Text("Real, verified settlements will appear here as they're reviewed.")
                        )
                        .padding(.top, 40)
                    } else {
                        if !deadlineSoonSettlements.isEmpty {
                            section(title: "Deadlines approaching", systemImage: "exclamationmark.triangle.fill", tint: .orange) {
                                ForEach(deadlineSoonSettlements, id: \.id) { settlement in
                                    NavigationLink {
                                        SettlementDetailView(settlement: settlement)
                                    } label: {
                                        HomeSettlementRow(settlement: settlement, isTracking: trackedSettlementIDs.contains(settlement.id))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        if !activeClaims.isEmpty {
                            section(title: "Continue your claims", systemImage: "checklist", tint: .accentColor) {
                                ForEach(activeClaims.prefix(4), id: \.id) { claim in
                                    NavigationLink {
                                        ClaimDetailView(claim: claim)
                                    } label: {
                                        HomeClaimRow(claim: claim)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        if !newSettlements.isEmpty {
                            section(title: "New settlements", systemImage: "sparkles", tint: .accentColor) {
                                ForEach(newSettlements.prefix(3), id: \.id) { settlement in
                                    NavigationLink {
                                        SettlementDetailView(settlement: settlement)
                                    } label: {
                                        HomeSettlementRow(settlement: settlement, isTracking: false)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Theme.pageBackground)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .profileToolbarButton()
            .onAppear {
                SettlementCatalog.loadSeedIfNeeded(into: context)
                WatchlistCatalog.loadIfNeeded(into: context)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Your money.")
                .font(.largeTitle.bold())
            Text(summaryText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var summaryText: String {
        var parts: [String] = []
        if !settlements.isEmpty {
            parts.append("\(settlements.count) open \(settlements.count == 1 ? "settlement" : "settlements")")
        }
        if !activeClaims.isEmpty {
            parts.append("\(activeClaims.count) active \(activeClaims.count == 1 ? "claim" : "claims")")
        }
        return parts.isEmpty ? "Nothing to claim right now" : parts.joined(separator: " · ")
    }

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(tint)
            VStack(spacing: 10) {
                content()
            }
        }
    }
}

private struct HomeSettlementRow: View {
    let settlement: Settlement
    let isTracking: Bool

    private var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: settlement.claimDeadline).day ?? 0
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(settlement.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    Spacer()
                    if isTracking {
                        Label("Tracking", systemImage: "checkmark.circle.fill")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.green)
                            .labelStyle(.iconOnly)
                            .accessibilityLabel("Tracking")
                    }
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
        }
    }
}

private struct HomeClaimRow: View {
    let claim: Claim

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                Text(claim.settlementTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                ClaimStatusBadge(status: claim.status)
            }
        }
    }
}
