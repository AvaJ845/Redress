import SwiftUI
import SwiftData

struct SettlementDetailView: View {
    let settlement: Settlement
    @Environment(\.modelContext) private var context
    @Environment(SubscriptionManager.self) private var subscriptions
    @Query private var claims: [Claim]
    @State private var showingPaywall = false
    @State private var claimJustStarted = false

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

                if !settlement.isFullyVerified {
                    Label("Pending review", systemImage: "clock.badge.questionmark")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.orange)
                }

                Text(settlement.title).font(.title2.bold())
                Text(settlement.brand).foregroundStyle(.secondary)

                if !settlement.payoutText.isEmpty {
                    PayoutCallout(text: settlement.payoutText)
                }

                if settlement.isFullyVerified {
                    Card {
                        VStack(alignment: .leading, spacing: 14) {
                            detailRow(title: "Eligibility", systemImage: "person.fill.checkmark", text: settlement.eligibilityCriteria)
                            Divider()
                            detailRow(title: "What you'll need", systemImage: "doc.text", text: settlement.proofRequirement.summary)
                            Divider()
                            detailRow(title: "Deadline", systemImage: "calendar", text: settlement.claimDeadline.formatted(date: .long, time: .omitted))
                        }
                    }
                } else {
                    Card {
                        detailRow(title: "Deadline", systemImage: "calendar", text: settlement.claimDeadline.formatted(date: .long, time: .omitted))
                    }
                }

                Text(settlement.settlementDescription)
                    .font(.body)

                SourceProvenanceView(settlement: settlement)

                if settlement.isFullyVerified {
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
                } else if let sourceURL = settlement.sourceURL {
                    Link(destination: sourceURL) {
                        Label("View official source", systemImage: "arrow.up.right.square")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Text("This settlement's existence and deadline are confirmed directly by the administrator, but Redress hasn't independently verified eligibility, proof requirements, or a claim link yet — there's nothing to start here until that review happens. Check the official source above for the latest details.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .background(Theme.pageBackground)
        .navigationTitle("Settlement")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPaywall) {
            PaywallView(reason: "You're already tracking a claim on the free plan. Upgrade to track this one too.")
        }
        .sensoryFeedback(.success, trigger: claimJustStarted)
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
        claimJustStarted.toggle()
    }
}

/// The one place Gold appears: this is the single most prominent "your
/// money" moment on the screen, so it gets the rare, money-specific
/// accent instead of the everyday brand color — kept deliberately scarce
/// (see Theme.swift) rather than reused throughout the app.
private struct PayoutCallout: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.title3)
                .foregroundStyle(Theme.gold)
            VStack(alignment: .leading, spacing: 2) {
                Text("Potential payout")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(text)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.gold.opacity(0.15))
        )
        .accessibilityElement(children: .combine)
    }
}
