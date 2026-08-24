import XCTest
@testable import Redress

/// SubscriptionManager's init kicks off real async StoreKit calls
/// (Product.products(for:), Transaction.updates) that this test target has
/// no StoreKit configuration for — they fail gracefully (loadProduct's own
/// do/catch already handles that) rather than crash, so constructing the
/// manager here is safe. These tests only assert on debugForcePlusEnabled,
/// which is synchronous and doesn't depend on those calls completing.
@MainActor
final class SubscriptionManagerTests: XCTestCase {
    private let debugForcePlusKey = "redress.debugForcePlus"

    override func tearDownWithError() throws {
        UserDefaults.standard.removeObject(forKey: debugForcePlusKey)
    }

    func testDebugForcePlusHasNoEffectOutsideTestFlight() {
        let subscriptions = SubscriptionManager(isTestFlightBuild: false)

        subscriptions.debugForcePlusEnabled = true

        XCTAssertFalse(
            subscriptions.debugForcePlusEnabled,
            "the setter must be a no-op outside a TestFlight build, even if called directly"
        )
    }

    func testDebugForcePlusWorksInTestFlightBuild() {
        let subscriptions = SubscriptionManager(isTestFlightBuild: true)

        subscriptions.debugForcePlusEnabled = true
        XCTAssertTrue(subscriptions.debugForcePlusEnabled)

        subscriptions.debugForcePlusEnabled = false
        XCTAssertFalse(subscriptions.debugForcePlusEnabled)
    }

    func testStaleUserDefaultsValueIsIgnoredOutsideTestFlight() {
        // Simulates a real-world case: a device was once a TestFlight
        // install with the toggle left on, then received an App Store
        // release build (same UserDefaults suite, different receipt).
        // The stored `true` must never leak into isPlus once the app
        // is no longer a TestFlight build.
        UserDefaults.standard.set(true, forKey: debugForcePlusKey)

        let subscriptions = SubscriptionManager(isTestFlightBuild: false)

        XCTAssertFalse(subscriptions.debugForcePlusEnabled)
    }
}
