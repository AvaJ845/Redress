import Foundation
import SwiftData

/// A lawsuit that was just filed — not a settlement. No deadline, no
/// administrator, no claim form, because none of those exist yet for a
/// case at this stage. Deliberately a separate model from Settlement,
/// not a lower-confidence Settlement, so the UI can never accidentally
/// render "Start Claim" for something there is nothing to claim yet.
@Model
final class WatchlistCase {
    @Attribute(.unique) var id: String
    var caseName: String
    var company: String
    var court: String
    var dateFiled: Date
    var docketNumber: String
    var summary: String
    var docketURLString: String
    var sourceName: String
    var sourceURLString: String?
    var sourceDate: Date?

    var docketURL: URL? {
        URL(string: docketURLString)
    }

    var sourceURL: URL? {
        sourceURLString.flatMap(URL.init(string:))
    }

    init(
        id: String,
        caseName: String,
        company: String,
        court: String,
        dateFiled: Date,
        docketNumber: String,
        summary: String,
        docketURLString: String,
        sourceName: String,
        sourceURLString: String? = nil,
        sourceDate: Date? = nil
    ) {
        self.id = id
        self.caseName = caseName
        self.company = company
        self.court = court
        self.dateFiled = dateFiled
        self.docketNumber = docketNumber
        self.summary = summary
        self.docketURLString = docketURLString
        self.sourceName = sourceName
        self.sourceURLString = sourceURLString
        self.sourceDate = sourceDate
    }
}
