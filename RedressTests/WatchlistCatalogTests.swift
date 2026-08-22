import XCTest
import SwiftData
@testable import Redress

final class WatchlistCatalogTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([Settlement.self, Claim.self, WatchlistCase.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [configuration])
        context = ModelContext(container)
        UserDefaults.standard.removeObject(forKey: WatchlistCatalog.appliedVersionKey)
    }

    override func tearDownWithError() throws {
        UserDefaults.standard.removeObject(forKey: WatchlistCatalog.appliedVersionKey)
    }

    private func writeFile(_ json: String) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        try! json.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func caseRecord(id: String, name: String) -> String {
        """
        {"id":"\(id)","caseName":"\(name)","company":"Test Co","court":"N.D. Cal.",
        "dateFiled":"2026-08-20T00:00:00Z","docketNumber":"1:26-cv-00001",
        "summary":"A proposed class action was filed.",
        "docketURLString":"https://www.courtlistener.com/docket/1/",
        "sourceName":"Test Source","sourceURLString":null,"sourceDate":null}
        """
    }

    func testFirstRunInsertsAllCases() throws {
        let url = writeFile(#"{"watchlistVersion":1,"cases":[\#(caseRecord(id: "a", name: "First"))]}"#)
        WatchlistCatalog.loadIfNeeded(into: context, fileURL: url)

        let results = try context.fetch(FetchDescriptor<WatchlistCase>())
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.caseName, "First")
    }

    func testSameVersionDoesNotReRun() throws {
        let url = writeFile(#"{"watchlistVersion":1,"cases":[\#(caseRecord(id: "a", name: "First"))]}"#)
        WatchlistCatalog.loadIfNeeded(into: context, fileURL: url)

        let existing = try context.fetch(FetchDescriptor<WatchlistCase>()).first!
        existing.caseName = "User-visible state"
        context.saveOrLog()

        WatchlistCatalog.loadIfNeeded(into: context, fileURL: url)
        let results = try context.fetch(FetchDescriptor<WatchlistCase>())
        XCTAssertEqual(results.first?.caseName, "User-visible state")
    }

    func testHigherVersionUpsertsAndRemoves() throws {
        let v1 = writeFile(#"{"watchlistVersion":1,"cases":[\#(caseRecord(id: "a", name: "First")),\#(caseRecord(id: "b", name: "Second"))]}"#)
        WatchlistCatalog.loadIfNeeded(into: context, fileURL: v1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<WatchlistCase>()).count, 2)

        // "a" dropped, "b" corrected, "c" added
        let v2 = writeFile(#"{"watchlistVersion":2,"cases":[\#(caseRecord(id: "b", name: "Second Corrected")),\#(caseRecord(id: "c", name: "Third"))]}"#)
        WatchlistCatalog.loadIfNeeded(into: context, fileURL: v2)

        let results = try context.fetch(FetchDescriptor<WatchlistCase>())
        XCTAssertEqual(results.count, 2, "dropped case must actually be removed, corrected case updated in place")
        XCTAssertFalse(results.contains { $0.id == "a" })
        XCTAssertTrue(results.contains { $0.id == "b" && $0.caseName == "Second Corrected" })
        XCTAssertTrue(results.contains { $0.id == "c" })
    }
}
