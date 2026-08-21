import SwiftUI
import StoreKit

struct PaywallView: View {
    let reason: String
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(reason)
                        .font(.headline)

                    PlanComparisonView()

                    if let product = subscriptions.product {
                        Button {
                            purchase(product)
                        } label: {
                            HStack {
                                Text("Subscribe — \(product.displayPrice)/year")
                                if isPurchasing { Spacer(); ProgressView() }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isPurchasing)
                    } else if subscriptions.isLoading {
                        ProgressView("Loading price…")
                    } else {
                        VStack(spacing: 8) {
                            Text("Couldn't load subscription details. Check your connection and try again.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("Retry") {
                                Task { await subscriptions.loadProduct() }
                            }
                        }
                    }

                    Text("Annual only — no monthly plan, so there's nothing to double-bill. Cancel anytime in Settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button("Restore Purchases") {
                        Task {
                            await subscriptions.restore()
                            if subscriptions.isPlus { dismiss() }
                        }
                    }
                    .font(.footnote)
                }
                .padding()
            }
            .navigationTitle("Redress Plus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") { dismiss() }
                }
            }
            .onChange(of: subscriptions.isPlus) { _, newValue in
                if newValue { dismiss() }
            }
        }
    }

    private func purchase(_ product: Product) {
        isPurchasing = true
        errorMessage = nil
        Task {
            do {
                try await subscriptions.purchase()
            } catch {
                errorMessage = "Purchase failed. Please try again."
            }
            isPurchasing = false
        }
    }
}
