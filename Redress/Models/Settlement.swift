import Foundation
import SwiftData

@Model
final class Settlement {
    @Attribute(.unique) var id: String
    var title: String
    var brand: String
    var settlementDescription: String
    var eligibilityCriteria: String
    var proofRequirementRaw: String
    var administratorName: String
    var administratorPortalURLString: String
    var claimDeadline: Date
    var isSampleData: Bool

    /// True for the app's original, strict tier: a human independently
    /// verified eligibility, proof requirements, and a real claim-form
    /// URL directly on the official site before this record ever shipped.
    /// False marks a second, explicitly looser tier — the settlement's
    /// *existence* and deadline are confirmed directly by a ground-truth
    /// source (the administrator's own case page, a court, or an agency),
    /// but eligibility/proof/claim-URL haven't been independently
    /// reviewed yet. The UI must never show a "Start Claim" action for a
    /// `false` record — the loosened bar is about surfacing more real,
    /// confirmed-to-exist settlements sooner, never about letting a user
    /// act on unverified specifics. Defaults true so every record from
    /// before this field existed is unaffected.
    var isFullyVerified: Bool = true

    /// Plain-language payout description, e.g. "$50 (no proof needed), or
    /// documented losses + up to $150 for lost time." Every figure here
    /// must trace to something directly verified on the official site —
    /// never an aggregator's summary number. Empty string, not a guess,
    /// when a program has no fixed or estimable amount.
    var payoutText: String = ""

    /// Provenance — shown in the UI so a user can judge freshness/trust
    /// themselves rather than relying on hidden certainty. sourceName is
    /// e.g. "California Attorney General" or "Redress team (manually
    /// verified)"; sourceURL points at the original announcement/docket,
    /// not the claims portal; sourceDate is when that source was published.
    var sourceName: String = "Unknown"
    var sourceURLString: String?
    var sourceDate: Date?

    var proofRequirement: ProofRequirement {
        get { ProofRequirement(rawValue: proofRequirementRaw) ?? .none }
        set { proofRequirementRaw = newValue.rawValue }
    }

    var administratorPortalURL: URL? {
        URL(string: administratorPortalURLString)
    }

    var sourceURL: URL? {
        sourceURLString.flatMap(URL.init(string:))
    }

    init(
        id: String,
        title: String,
        brand: String,
        settlementDescription: String,
        eligibilityCriteria: String,
        proofRequirement: ProofRequirement,
        administratorName: String,
        administratorPortalURLString: String,
        claimDeadline: Date,
        isSampleData: Bool,
        payoutText: String = "",
        sourceName: String = "Unknown",
        sourceURLString: String? = nil,
        sourceDate: Date? = nil,
        isFullyVerified: Bool = true
    ) {
        self.id = id
        self.title = title
        self.brand = brand
        self.settlementDescription = settlementDescription
        self.eligibilityCriteria = eligibilityCriteria
        self.proofRequirementRaw = proofRequirement.rawValue
        self.administratorName = administratorName
        self.administratorPortalURLString = administratorPortalURLString
        self.claimDeadline = claimDeadline
        self.isSampleData = isSampleData
        self.payoutText = payoutText
        self.sourceName = sourceName
        self.sourceURLString = sourceURLString
        self.sourceDate = sourceDate
        self.isFullyVerified = isFullyVerified
    }
}
