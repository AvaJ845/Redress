import XCTest
@testable import Redress

final class DocumentVaultTests: XCTestCase {

    func testSaveWriteReadDeleteRoundTrip() throws {
        let claimID = UUID()
        let payload = Data("test document contents".utf8)

        let fileName = try DocumentVault.save(data: payload, for: claimID)
        let url = DocumentVault.url(for: fileName)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(try Data(contentsOf: url), payload)

        DocumentVault.delete(fileName: fileName)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testDeleteAllRemovesEveryFile() throws {
        let claimID = UUID()
        let fileNames = try (0..<3).map { _ in
            try DocumentVault.save(data: Data("doc".utf8), for: claimID)
        }

        DocumentVault.deleteAll(for: fileNames)

        for fileName in fileNames {
            XCTAssertFalse(FileManager.default.fileExists(atPath: DocumentVault.url(for: fileName).path))
        }
    }

    func testDeletingMissingFileDoesNotThrow() {
        DocumentVault.delete(fileName: "does-not-exist.dat")
    }
}
