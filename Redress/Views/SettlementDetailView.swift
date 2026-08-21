import SwiftUI
import SwiftData

struct SettlementDetailView: View {
    let settlement: Settlement
    @Environment(\.modelContext) private var context
    @Environment(SubscriptionManager.self) private var subscriptions
    @Query private var claims: [Claim]
    @State private var showingPaywall = false

    private var existingClaim: Claim? {
        claims.first { $0.settlementID == settlement.id }
    }

    private var activeClaimCount: Int {
        claims.filter { !$0.status.isTerminal }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if settlement.isSampleData {
                    Label("Sample data — not a real settlement", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Text(settlement.title).font(.title2.bold())
                Text(settlement.brand).foregroundStyle(.secondary)

                GroupBox("Eligibility") {
                    Text(settlement.eligibilityCriteria)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                GroupBox("What you'll need") {
                    Label(settlement.proofRequirement.summary, systemImage: "doc.text")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                GroupBox("Deadline") {
                    Text(settlement.claimDeadline.formatted(date: .long, time: .omitted))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text(settlement.settlementDescription)
                    .font(.body)

                SourceProvenanceView(settlement: settlement)

                Button {
                    attemptStartClaim()
                } label: {
                    Label(existingClaim != nil ? "Claim started" : "Start Claim", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(existingClaim != nil)

                if !subscriptions.isPlus {
                    Text("Free plan tracks 1 claim at a time. Redress Plus tracks unlimited claims.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Settlement")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPaywall) {
            PaywallView(reason: "You're already tracking a claim on the free plan. Upgrade to track this one too.")
        }
    }

    private func attemptStartClaim() {
        guard existingClaim == nil else { return }
        if !subscriptions.isPlus && activeClaimCount >= 1 {
            showingPaywall = true
            return
        }
        startClaim()
    }

    private func startClaim() {
        let claim = Claim(settlementID: settlement.id, settlementTitle: settlement.title)
        context.insert(claim)
        context.saveOrLog()
        NotificationManager.scheduleDeadlineReminder(for: claim, settlement: settlement)
    }
}
