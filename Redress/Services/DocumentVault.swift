import Foundation

enum DocumentVault {
    private static var vaultDirectory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("ProofDocuments", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(
                at: dir,
                withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.completeUnlessOpen]
            )
        }
        return dir
    }

    static func save(data: Data, for claimID: UUID) throws -> String {
        let fileName = "\(claimID.uuidString)-\(UUID().uuidString).dat"
        let url = vaultDirectory.appendingPathComponent(fileName)
        try data.write(to: url, options: [.completeFileProtectionUnlessOpen])
        return fileName
    }

    static func url(for fileName: String) -> URL {
        vaultDirectory.appendingPathComponent(fileName)
    }

    static func delete(fileName: String) {
        try? FileManager.default.removeItem(at: url(for: fileName))
    }

    static func deleteAll(for fileNames: [String]) {
        fileNames.forEach { delete(fileName: $0) }
    }
}
