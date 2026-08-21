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
        "claimDeadline":"\(deadline)","isSampleData":false,
        "sourceName":"Test Source","sourceURLString":null,"sourceDate":null}
        """
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
