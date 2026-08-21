import SwiftUI
import SwiftData
import StoreKit

struct ClaimDetailView: View {
    @Bindable var claim: Claim
    @Environment(\.modelContext) private var context
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.requestReview) private var requestReview
    @State private var showingDocumentCapture = false
    @State private var showingPaywall = false
    @State private var settlement: Settlement?
    @State private var settlementLookupAttempted = false

    private var estimatedPayoutBinding: Binding<Double> {
        Binding(
            get: { claim.estimatedPayout ?? 0 },
            set: { claim.estimatedPayout = $0 == 0 ? nil : $0 }
        )
    }

    private var actualPayoutBinding: Binding<Double> {
        Binding(
            get: { claim.actualPayout ?? 0 },
            set: { claim.actualPayout = $0 == 0 ? nil : $0 }
        )
    }

    var body: some View {
        Form {
            Section("Status") {
                HStack {
                    ClaimStatusBadge(status: claim.status)
                    Spacer()
                }
                Picker("Status", selection: $claim.status) {
                    ForEach(ClaimStatus.allCases, id: \.self) { status in
                        Text(status.displayName).tag(status)
                    }
                }
            }

            Section("Payout") {
                HStack {
                    Text("Estimated")
                    Spacer()
                    TextField("$0", value: estimatedPayoutBinding, format: .currency(code: "USD"))
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                }
                HStack {
                    Text("Actual")
                    Spacer()
                    TextField("$0", value: actualPayoutBinding, format: .currency(code: "USD"))
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                }
            }

            Section("Notes") {
                TextField("Add a note about this claim", text: $claim.notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Proof documents") {
                ForEach(claim.documentFileNames, id: \.self) { fileName in
                    Text(String(fileName.prefix(24)) + "…")
                }
                .onDelete(perform: deleteDocuments)

                Button {
                    if subscriptions.isPlus {
                        showingDocumentCapture = true
                    } else {
                        showingPaywall = true
                    }
                } label: {
                    Label("Add document", systemImage: subscriptions.isPlus ? "doc.badge.plus" : "lock.fill")
                }

                Text("Documents are encrypted and stored only on this device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let settlement, let url = settlement.administratorPortalURL {
                Section("Submit") {
                    Link(destination: url) {
                        Label("Open official claim portal", systemImage: "arrow.up.right.square")
                    }
                    Text("Redress never transmits your documents — you submit directly to \(settlement.administratorName).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if settlementLookupAttempted {
                Section("Submit") {
                    Label("Settlement details unavailable", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text("The original settlement record for this claim couldn't be found, so there's no official portal link to show. Your claim and documents are unaffected.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button(role: .destructive) {
                    deleteClaim()
                } label: {
                    Label("Delete claim & documents", systemImage: "trash")
                }
            }
        }
        .navigationTitle(claim.settlementTitle)
        .sheet(isPresented: $showingDocumentCapture) {
            DocumentCaptureView(claim: claim)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(reason: "The document vault is a Redress Plus feature.")
        }
        .onAppear(perform: loadSettlement)
        .onChange(of: claim.status) { _, newValue in
            context.saveOrLog()
            if newValue == .paid, ReviewPrompt.shouldRequestAfterPaidClaim() {
                requestReview()
            }
        }
        .onChange(of: claim.estimatedPayout) { context.saveOrLog() }
        .onChange(of: claim.actualPayout) { context.saveOrLog() }
        .onChange(of: claim.notes) { context.saveOrLog() }
    }

    private func loadSettlement() {
        let targetID = claim.settlementID
        let descriptor = FetchDescriptor<Settlement>(predicate: #Predicate { $0.id == targetID })
        settlement = try? context.fetch(descriptor).first
        settlementLookupAttempted = true
    }

    private func deleteDocuments(at offsets: IndexSet) {
        let toDelete = offsets.map { claim.documentFileNames[$0] }
        toDelete.forEach { DocumentVault.delete(fileName: $0) }
        claim.documentFileNames.remove(atOffsets: offsets)
        context.saveOrLog()
    }

    private func deleteClaim() {
        DocumentVault.deleteAll(for: claim.documentFileNames)
        NotificationManager.cancelReminder(for: claim)
        context.delete(claim)
        context.saveOrLog()
    }
}
