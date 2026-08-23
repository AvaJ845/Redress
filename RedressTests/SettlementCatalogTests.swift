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
        "sourceName":"Test Source","sourceURLString":null,"sourceDate":null}
        """
    }

    func testPayoutTextRoundTripsThroughSeeding() throws {
        let json = """
        {"id":"a","title":"First","brand":"Test Brand","description":"desc",
        "eligibilityCriteria":"criteria","proofRequirement":"none",
        "administratorName":"Admin","administratorPortalURLString":"https://example.com",
        "claimDeadline":"2026-12-01T00:00:00Z","isSampleData":false,
        "payoutText":"$50, no proof needed",
        "sourceName":"Test Source","sourceURLString":null,"sourceDate":null}
        """
        let url = writeSeedFile(#"{"seedVersion":1,"settlements":[\#(json)]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: url)

        let result = try context.fetch(FetchDescriptor<Settlement>()).first
        XCTAssertEqual(result?.payoutText, "$50, no proof needed")
    }

    func testIsFullyVerifiedDefaultsToTrueWhenAbsentFromSeedJSON() throws {
        // seedRecord()'s fixture doesn't include isFullyVerified at all —
        // every settlement seeded before this field existed must still
        // come through fully verified, not silently downgraded.
        let url = writeSeedFile(#"{"seedVersion":1,"settlements":[\#(seedRecord(id: "a", title: "First"))]}"#)
        SettlementCatalog.loadSeedIfNeeded(into: context, seedFileURL: url)

        let result = try context.fetch(FetchDescriptor<Settlement>()).first
        XCTAssertEqual(result?.isFullyVerified, true)
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
}
