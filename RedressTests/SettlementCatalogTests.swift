import XCTest
import SwiftData
@testable import Redress

final class SettlementCatalogTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([Settlement.self, Claim.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [configuration])
        context = ModelContext(container)
        UserDefaults.standard.removeObject(forKey: SettlementCatalog.appliedSeedVersionKey)
    }

    override func tearDownWithError() throws {
        UserDefaults.standard.removeObject(forKey: SettlementCatalog.appliedSeedVersionKey)
    }

    private func writeSeedFile(_ json: String) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        try! json.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func seedRecord(id: String, title: String, deadline: String = "2026-12-01T00:00:00Z") -> String {
        """
        {"id":"\(id)","title":"\(title)","brand":"Test Brand","description":"desc",
        "eligibilityCriteria":"criteria","proofRequirement":"none",
        "administratorName":"Admin","administratorPortalURLString":"https://example.com",
        "claimDeadline":"\(deadline)","isSampleData":false,"payoutText":"",
        "sourceName":"Test Source","sourceURLString":null,"sourceDate":null,
        "isFullyVerified":true}
        """
    }

    func testPayoutTextRoundTripsThroughSeeding() throws {
        let json = """
        {"id":"a","title":"First","brand":"Test Brand","description":"desc",
        "eligibilityCriteria":"criteria","proofRequirement":"none",
        "administratorName":"Admin","administratorPortalURLString":"https://example.com",
        "claimDeadline":"2026-12-01T00:00:00Z","isSampleData":false,
        "payoutText":"$50, no proof needed",
        "sourceName":"Test Source","sourceURLString":null,"sourceDate":null,
        "isFullyVerified":true}
        """
        let url = writeSeedFile(#"{"seedVersion":1,"settlements":[\#(json)]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: url)

        let result = try context.fetch(FetchDescriptor<Settlement>()).first
        XCTAssertEqual(result?.payoutText, "$50, no proof needed")
    }

    func testMissingIsFullyVerifiedFailsTheWholeLoadRatherThanDefaulting() throws {
        // isFullyVerified is the entire enforcement mechanism for the
        // two-tier trust model — a record that omits it must never
        // silently come through as verified (or as anything at all).
        // JSONDecoder fails the whole array on one bad element, so the
        // load is a clean no-op rather than partially applying.
        let json = """
        {"id":"a","title":"First","brand":"Test Brand","description":"desc",
        "eligibilityCriteria":"criteria","proofRequirement":"none",
        "administratorName":"Admin","administratorPortalURLString":"https://example.com",
        "claimDeadline":"2026-12-01T00:00:00Z","isSampleData":false,"payoutText":"",
        "sourceName":"Test Source","sourceURLString":null,"sourceDate":null}
        """
        let url = writeSeedFile(#"{"seedVersion":1,"settlements":[\#(json)]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: url)

        let results = try context.fetch(FetchDescriptor<Settlement>())
        XCTAssertTrue(results.isEmpty, "a seed file missing isFullyVerified on any record must not insert anything")
    }

    func testUpdatingAnUnverifiedSettlementCannotSilentlyBecomeVerified() throws {
        // The exact regression this test guards against: a human hand-
        // corrects one field (e.g. a deadline) on an already-unverified
        // record and the JSON edit still carries isFullyVerified:false —
        // the record must stay unverified, never flip to true implicitly.
        let v1 = """
        {"id":"a","title":"First","brand":"Test Brand","description":"desc",
        "eligibilityCriteria":"Not yet published on the administrator's public case page.",
        "proofRequirement":"none","administratorName":"Admin","administratorPortalURLString":"",
        "claimDeadline":"2026-12-01T00:00:00Z","isSampleData":false,"payoutText":"",
        "sourceName":"Test Source","sourceURLString":null,"sourceDate":null,
        "isFullyVerified":false}
        """
        let url1 = writeSeedFile(#"{"seedVersion":1,"settlements":[\#(v1)]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: url1)

        let v2 = """
        {"id":"a","title":"First","brand":"Test Brand","description":"desc",
        "eligibilityCriteria":"Not yet published on the administrator's public case page.",
        "proofRequirement":"none","administratorName":"Admin","administratorPortalURLString":"",
        "claimDeadline":"2027-01-15T00:00:00Z","isSampleData":false,"payoutText":"",
        "sourceName":"Test Source","sourceURLString":null,"sourceDate":null,
        "isFullyVerified":false}
        """
        let url2 = writeSeedFile(#"{"seedVersion":2,"settlements":[\#(v2)]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: url2)

        let result = try context.fetch(FetchDescriptor<Settlement>()).first
        XCTAssertEqual(result?.isFullyVerified, false)
    }

    func testIsFullyVerifiedFalseRoundTripsThroughSeeding() throws {
        let json = """
        {"id":"a","title":"First","brand":"Test Brand","description":"desc",
        "eligibilityCriteria":"criteria","proofRequirement":"none",
        "administratorName":"Admin","administratorPortalURLString":"",
        "claimDeadline":"2026-12-01T00:00:00Z","isSampleData":false,
        "payoutText":"","sourceName":"Test Source","sourceURLString":null,
        "sourceDate":null,"isFullyVerified":false}
        """
        let url = writeSeedFile(#"{"seedVersion":1,"settlements":[\#(json)]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: url)

        let result = try context.fetch(FetchDescriptor<Settlement>()).first
        XCTAssertEqual(result?.isFullyVerified, false)
    }

    func testFirstRunInsertsAllSettlements() throws {
        let url = writeSeedFile(#"{"seedVersion":1,"settlements":[\#(seedRecord(id: "a", title: "First"))]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: url)

        let results = try context.fetch(FetchDescriptor<Settlement>())
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "First")
    }

    func testSameVersionDoesNotReRun() throws {
        let url = writeSeedFile(#"{"seedVersion":1,"settlements":[\#(seedRecord(id: "a", title: "First"))]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: url)

        // Manually alter the record the way a user's on-device data might
        // diverge (e.g. hypothetically) — same-version reseed must not touch it.
        let existing = try context.fetch(FetchDescriptor<Settlement>()).first!
        existing.title = "User-visible state"
        context.saveOrLog()

        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: url)
        let results = try context.fetch(FetchDescriptor<Settlement>())
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "User-visible state", "same seedVersion must be a no-op")
    }

    func testHigherVersionAddsNewSettlementWithoutDuplicatingExisting() throws {
        let v1 = writeSeedFile(#"{"seedVersion":1,"settlements":[\#(seedRecord(id: "a", title: "First"))]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: v1)

        let v2 = writeSeedFile(#"{"seedVersion":2,"settlements":[\#(seedRecord(id: "a", title: "First")),\#(seedRecord(id: "b", title: "Second"))]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: v2)

        let results = try context.fetch(FetchDescriptor<Settlement>())
        XCTAssertEqual(results.count, 2, "existing record should be updated in place, not duplicated")
        XCTAssertTrue(results.contains { $0.id == "a" })
        XCTAssertTrue(results.contains { $0.id == "b" })
    }

    func testHigherVersionUpdatesExistingFieldsInPlace() throws {
        let v1 = writeSeedFile(#"{"seedVersion":1,"settlements":[\#(seedRecord(id: "a", title: "First", deadline: "2026-12-01T00:00:00Z"))]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: v1)

        let v2 = writeSeedFile(#"{"seedVersion":2,"settlements":[\#(seedRecord(id: "a", title: "Corrected Title", deadline: "2027-01-15T00:00:00Z"))]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: v2)

        let results = try context.fetch(FetchDescriptor<Settlement>())
        XCTAssertEqual(results.count, 1, "an id-matching record must be updated in place, not duplicated")
        XCTAssertEqual(results.first?.title, "Corrected Title")
    }

    func testUpdatingASettlementDoesNotOrphanAnExistingClaim() throws {
        let v1 = writeSeedFile(#"{"seedVersion":1,"settlements":[\#(seedRecord(id: "a", title: "First"))]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: v1)

        let claim = Claim(settlementID: "a", settlementTitle: "First")
        context.insert(claim)
        context.saveOrLog()

        let v2 = writeSeedFile(#"{"seedVersion":2,"settlements":[\#(seedRecord(id: "a", title: "Corrected Title"))]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: v2)

        let claims = try context.fetch(FetchDescriptor<Claim>())
        XCTAssertEqual(claims.count, 1, "claim must survive a settlement update")
        XCTAssertEqual(claims.first?.settlementID, "a")
    }

    func testSettlementDroppedFromSeedIsActuallyDeleted() throws {
        let v1 = writeSeedFile(#"{"seedVersion":1,"settlements":[\#(seedRecord(id: "a", title: "First")),\#(seedRecord(id: "b", title: "Second"))]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: v1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Settlement>()).count, 2)

        let v2 = writeSeedFile(#"{"seedVersion":2,"settlements":[\#(seedRecord(id: "a", title: "First"))]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: v2)

        let results = try context.fetch(FetchDescriptor<Settlement>())
        XCTAssertEqual(results.count, 1, "dropping a record from the seed file must actually remove it, not just stop updating it")
        XCTAssertEqual(results.first?.id, "a")
    }

    func testDeadlineChangeReschedulesReminderForExistingClaim() throws {
        let v1 = writeSeedFile(#"{"seedVersion":1,"settlements":[\#(seedRecord(id: "a", title: "First", deadline: "2026-12-01T00:00:00Z"))]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: v1)

        let claim = Claim(settlementID: "a", settlementTitle: "First")
        context.insert(claim)
        context.saveOrLog()

        var rescheduledClaimIDs: [UUID] = []
        var rescheduledDeadlines: [Date] = []

        let v2 = writeSeedFile(#"{"seedVersion":2,"settlements":[\#(seedRecord(id: "a", title: "First", deadline: "2027-03-15T00:00:00Z"))]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: v2) { rescheduledClaim, settlement in
            rescheduledClaimIDs.append(rescheduledClaim.id)
            rescheduledDeadlines.append(settlement.claimDeadline)
        }

        XCTAssertEqual(rescheduledClaimIDs, [claim.id], "the claim against the settlement whose deadline changed must be rescheduled")
        XCTAssertEqual(rescheduledDeadlines.first, ISO8601DateFormatter().date(from: "2027-03-15T00:00:00Z"))
    }

    func testUnchangedDeadlineDoesNotTriggerReschedule() throws {
        let v1 = writeSeedFile(#"{"seedVersion":1,"settlements":[\#(seedRecord(id: "a", title: "First", deadline: "2026-12-01T00:00:00Z"))]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: v1)

        let claim = Claim(settlementID: "a", settlementTitle: "First")
        context.insert(claim)
        context.saveOrLog()

        var rescheduleCallCount = 0

        // Same deadline, only the title changes — nothing about the
        // reminder itself needs to change, so it shouldn't be touched.
        let v2 = writeSeedFile(#"{"seedVersion":2,"settlements":[\#(seedRecord(id: "a", title: "Corrected Title", deadline: "2026-12-01T00:00:00Z"))]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: v2) { _, _ in
            rescheduleCallCount += 1
        }

        XCTAssertEqual(rescheduleCallCount, 0, "a title-only change must not trigger a reminder reschedule")
    }

    func testSettlementDroppedFromSeedIsKeptIfAClaimReferencesIt() throws {
        let v1 = writeSeedFile(#"{"seedVersion":1,"settlements":[\#(seedRecord(id: "a", title: "First"))]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: v1)

        let claim = Claim(settlementID: "a", settlementTitle: "First")
        context.insert(claim)
        context.saveOrLog()

        // "a" is dropped entirely from v2 — but a real user claim points at it.
        let v2 = writeSeedFile(#"{"seedVersion":2,"settlements":[]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: v2)

        let results = try context.fetch(FetchDescriptor<Settlement>())
        XCTAssertEqual(results.count, 1, "must not delete a settlement a user has an active claim against")
        XCTAssertEqual(results.first?.id, "a")
    }

    func testFirstEverLoadDoesNotNotify() throws {
        // Every settlement is "new" on a fresh install — that's just the
        // app having content, not a change worth interrupting anyone about.
        let url = writeSeedFile(#"{"seedVersion":1,"settlements":[\#(seedRecord(id: "a", title: "First"))]}"#)

        var notifiedSettlements: [Settlement]?
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: url) { _, _ in } notifyNewSettlements: { settlements in
            notifiedSettlements = settlements
        }

        XCTAssertNil(notifiedSettlements, "must not notify on the very first seed load")
    }

    func testSubsequentLoadNotifiesOnlyAboutGenuinelyNewSettlements() throws {
        let v1 = writeSeedFile(#"{"seedVersion":1,"settlements":[\#(seedRecord(id: "a", title: "First"))]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: v1)

        var notifiedSettlements: [Settlement]?
        let v2 = writeSeedFile(#"{"seedVersion":2,"settlements":[\#(seedRecord(id: "a", title: "First")),\#(seedRecord(id: "b", title: "Second"))]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: v2) { _, _ in } notifyNewSettlements: { settlements in
            notifiedSettlements = settlements
        }

        XCTAssertEqual(notifiedSettlements?.count, 1, "only the genuinely new settlement should be notified about")
        XCTAssertEqual(notifiedSettlements?.first?.id, "b")
    }

    /// Guards the real, shipped SeedSettlements.json — not a synthetic
    /// fixture — against the exact mistake the trust model depends on
    /// never happening: an "unverified" record accidentally carrying a
    /// fabricated payout, portal link, or eligibility fact. Runs against
    /// Bundle.main (the host app's real bundle, via TEST_HOST) rather
    /// than an injected seedFileURL, so it fails if a future hand-edit to
    /// the actual seed file introduces this, not just a test fixture.
    func testRealSeedFileNeverFabricatesDetailsOnUnverifiedSettlements() throws {
        SettlementCatalog.loadSeedIfNeeded(into: context)

        let results = try context.fetch(FetchDescriptor<Settlement>())
        let unverified = results.filter { !$0.isFullyVerified }
        XCTAssertFalse(unverified.isEmpty, "expected at least one pending-review settlement in the real seed file")

        for settlement in unverified {
            XCTAssertTrue(
                settlement.payoutText.isEmpty,
                "\(settlement.id) is unverified but has a payoutText — that implies a verified fact no one confirmed"
            )
            XCTAssertTrue(
                settlement.administratorPortalURLString.isEmpty,
                "\(settlement.id) is unverified but has a portal URL — that would let a user attempt a claim on unverified data"
            )
            XCTAssertEqual(
                settlement.eligibilityCriteria,
                "Not yet published on the administrator's public case page.",
                "\(settlement.id) is unverified but eligibilityCriteria reads like a confirmed fact, not the honest placeholder"
            )
        }
    }

    func testSubsequentLoadWithNoNewSettlementsDoesNotNotify() throws {
        let v1 = writeSeedFile(#"{"seedVersion":1,"settlements":[\#(seedRecord(id: "a", title: "First"))]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: v1)

        var notifiedSettlements: [Settlement]?
        // v2 only corrects the title of the existing settlement — no new ones.
        let v2 = writeSeedFile(#"{"seedVersion":2,"settlements":[\#(seedRecord(id: "a", title: "Corrected Title"))]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: v2) { _, _ in } notifyNewSettlements: { settlements in
            notifiedSettlements = settlements
        }

        XCTAssertNil(notifiedSettlements, "an update with no new settlements must not notify")
    }
}
