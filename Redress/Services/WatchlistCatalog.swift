import Foundation
import SwiftData

private struct WatchlistCaseDTO: Codable {
    let id: String
    let caseName: String
    let company: String
    let court: String
    let dateFiled: String
    let docketNumber: String
    let summary: String
    let docketURLString: String
    let sourceName: String
    let sourceURLString: String?
    let sourceDate: String?
}

private struct WatchlistFile: Codable {
    let watchlistVersion: Int
    let cases: [WatchlistCaseDTO]
}

/// Same version-upsert-and-remove discipline as SettlementCatalog, applied
/// to watchlist cases instead. No claim ever references a WatchlistCase
/// (there's nothing to claim yet), so removal never has an orphan-claim
/// concern the way Settlement removal does.
enum WatchlistCatalog {
    static let appliedVersionKey = "redress.appliedWatchlistVersion"

    static func loadIfNeeded(into context: ModelContext, fileURL: URL? = nil) {
        let url = fileURL ?? Bundle.main.url(forResource: "WatchlistCases", withExtension: "json")
        guard let url, let data = try? Data(contentsOf: url) else { return }
        guard let file = try? JSONDecoder().decode(WatchlistFile.self, from: data) else { return }

        let appliedVersion = UserDefaults.standard.integer(forKey: appliedVersionKey)
        guard file.watchlistVersion > appliedVersion else { return }

        let formatter = ISO8601DateFormatter()
        let existing = (try? context.fetch(FetchDescriptor<WatchlistCase>())) ?? []
        var existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        let fileIDs = Set(file.cases.map(\.id))

        for dto in file.cases {
            let dateFiled = formatter.date(from: dto.dateFiled) ?? Date()
            let sourceDate = dto.sourceDate.flatMap { formatter.date(from: $0) }

            if let record = existingByID[dto.id] {
                record.caseName = dto.caseName
                record.company = dto.company
                record.court = dto.court
                record.dateFiled = dateFiled
                record.docketNumber = dto.docketNumber
                record.summary = dto.summary
                record.docketURLString = dto.docketURLString
                record.sourceName = dto.sourceName
                record.sourceURLString = dto.sourceURLString
                record.sourceDate = sourceDate
            } else {
                let entry = WatchlistCase(
                    id: dto.id,
                    caseName: dto.caseName,
                    company: dto.company,
                    court: dto.court,
                    dateFiled: dateFiled,
                    docketNumber: dto.docketNumber,
                    summary: dto.summary,
                    docketURLString: dto.docketURLString,
                    sourceName: dto.sourceName,
                    sourceURLString: dto.sourceURLString,
                    sourceDate: sourceDate
                )
                context.insert(entry)
                existingByID[dto.id] = entry
            }
        }

        for (id, record) in existingByID where !fileIDs.contains(id) {
            context.delete(record)
        }

        context.saveOrLog()
        UserDefaults.standard.set(file.watchlistVersion, forKey: appliedVersionKey)
    }
}
