import Foundation
import StoreKit
import Observation

@MainActor
@Observable
final class SubscriptionManager {
    static let plusProductID = "AvaResearchLLC.Redress.plus.annual"

    private(set) var isPlus = false
    private(set) var product: Product?
    private(set) var isLoading = true

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
        Task {
            await loadProduct()
            await refreshEntitlement()
            isLoading = false
        }
    }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.plusProductID])
            product = products.first
        } catch {
            product = nil
        }
    }

    func refreshEntitlement() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.productID == Self.plusProductID {
                active = true
            }
        }
        isPlus = active
    }

    func purchase() async throws {
        guard let product else { return }
        let result = try await product.purchase()
        if case .success(let verification) = result {
            await handle(verification)
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlement()
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        await transaction.finish()
        await refreshEntitlement()
    }
}
