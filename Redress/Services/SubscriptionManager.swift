import Foundation
import StoreKit
import Observation

@MainActor
@Observable
final class SubscriptionManager {
    static let plusProductID = "AvaResearchLLC.Redress.plus.annual"
    private static let debugForcePlusKey = "redress.debugForcePlus"

    private(set) var isPlus = false
    private(set) var product: Product?
    private(set) var isLoading = true

    private var updatesTask: Task<Void, Never>?
    private let isTestFlightBuild: Bool

    /// TestFlight and an App Store release distribute the exact same
    /// compiled binary — there is no compile-time way to include code in
    /// one and not the other, only a runtime check. The receipt file name
    /// is Apple's own documented way to tell them apart: TestFlight's
    /// receipt is "sandboxReceipt", an App Store release's is "receipt".
    /// A local Xcode Debug run with no receipt at all also reads false
    /// here — the debug-force toggle exists for TestFlight testers
    /// specifically, not local development (which already has the
    /// Redress.storekit config for that).
    nonisolated static var isRunningInTestFlight: Bool {
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }

    init(isTestFlightBuild: Bool = SubscriptionManager.isRunningInTestFlight) {
        self.isTestFlightBuild = isTestFlightBuild
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

    /// A TestFlight-only debug override so testers can exercise
    /// Plus-gated features without a real purchase. Both the getter and
    /// setter check isTestFlightBuild independently — not just the
    /// Settings UI that exposes the toggle — so even a stray leftover
    /// UserDefaults value from a prior TestFlight install can never grant
    /// Plus in an App Store release.
    var debugForcePlusEnabled: Bool {
        get { isTestFlightBuild && UserDefaults.standard.bool(forKey: Self.debugForcePlusKey) }
        set {
            guard isTestFlightBuild else { return }
            UserDefaults.standard.set(newValue, forKey: Self.debugForcePlusKey)
            Task { await refreshEntitlement() }
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
        isPlus = active || debugForcePlusEnabled
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
