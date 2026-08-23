import Foundation
import SwiftData

private struct SeedSettlementDTO: Codable {
    let id: String
    let title: String
    let brand: String
    let description: String
    let eligibilityCriteria: String
    let proofRequirement: String
    let administratorName: String
    let administratorPortalURLString: String
    let claimDeadline: String
    let isSampleData: Bool
    let payoutText: String
    let sourceName: String
    let sourceURLString: String?
    let sourceDate: String?
    /// Optional (not required in the JSON) and defaults to true when
    /// absent — matches Settlement's own default, so existing seed
    /// entries never need editing just because this field was added.
    let isFullyVerified: Bool?
}

private struct SeedFile: Codable {
    let seedVersion: Int
    let settlements: [SeedSettlementDTO]
}

enum SettlementCatalog {
    /// Bumping `seedVersion` in SeedSettlements.json is how new real
    /// settlements (or corrections to existing ones) reach installs that
    /// already have data — previously this only ran once ever per
    /// install, which meant a future app update with real settlements
    /// would silently do nothing for anyone who'd already launched the
    /// app. Upserts by id, so it never touches a user's Claims (which
    /// reference settlementID, not the Settlement object itself).
    static let appliedSeedVersionKey = "redress.appliedSeedVersion"

    static func loadSeedIfNeeded(
        into context: ModelContext,
        seedFileURL: URL? = nil,
        rescheduleReminder: (Claim, Settlement) -> Void = NotificationManager.scheduleDeadlineReminder
    ) {
        let url = seedFileURL ?? Bundle.main.url(forResource: "SeedSettlements", withExtension: "json")
        guard let url, let data = try? Data(contentsOf: url) else { return }
        guard let seedFile = try? JSONDecoder().decode(SeedFile.self, from: data) else { return }

        let appliedVersion = UserDefaults.standard.integer(forKey: appliedSeedVersionKey)
        guard seedFile.seedVersion > appliedVersion else { return }

        let formatter = ISO8601DateFormatter()
        let existing = (try? context.fetch(FetchDescriptor<Settlement>())) ?? []
        var existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

        for dto in seedFile.settlements {
            let deadline = formatter.date(from: dto.claimDeadline) ?? Date()
            let sourceDate = dto.sourceDate.flatMap { formatter.date(from: $0) }
            let proofRequirement = ProofRequirement(rawValue: dto.proofRequirement) ?? .none

            if let record = existingByID[dto.id] {
                let previousDeadline = record.claimDeadline

                record.title = dto.title
                record.brand = dto.brand
                record.settlementDescription = dto.description
                record.eligibilityCriteria = dto.eligibilityCriteria
                record.proofRequirement = proofRequirement
                record.administratorName = dto.administratorName
                record.administratorPortalURLString = dto.administratorPortalURLString
                record.claimDeadline = deadline
                record.sourceName = dto.sourceName
                record.sourceURLString = dto.sourceURLString
                record.sourceDate = sourceDate
                record.isSampleData = dto.isSampleData
                record.payoutText = dto.payoutText
                record.isFullyVerified = dto.isFullyVerified ?? true

                if deadline != previousDeadline {
                    rescheduleRemindersForClaims(against: record, context: context, reschedule: rescheduleReminder)
                }
            } else {
                let settlement = Settlement(
                    id: dto.id,
                    title: dto.title,
                    brand: dto.brand,
                    settlementDescription: dto.description,
                    eligibilityCriteria: dto.eligibilityCriteria,
                    proofRequirement: proofRequirement,
                    administratorName: dto.administratorName,
                    administratorPortalURLString: dto.administratorPortalURLString,
                    claimDeadline: deadline,
                    isSampleData: dto.isSampleData,
                    payoutText: dto.payoutText,
                    sourceName: dto.sourceName,
                    sourceURLString: dto.sourceURLString,
                    sourceDate: sourceDate,
                    isFullyVerified: dto.isFullyVerified ?? true
                )
                context.insert(settlement)
                existingByID[dto.id] = settlement
            }
        }

        removeSettlementsNoLongerInSeed(seedFile: seedFile, existingByID: existingByID, context: context)

        context.saveOrLog()
        UserDefaults.standard.set(seedFile.seedVersion, forKey: appliedSeedVersionKey)
    }

    /// A settlement dropped from the seed file (e.g. a sample record
    /// removed once real data exists) should actually go away, not just
    /// stop being updated — otherwise "remove sample data" silently does
    /// nothing for anyone who already has the app. But never delete one a
    /// user has an active Claim against: that would orphan real user data
    /// over a catalog change they had nothing to do with. ClaimDetailView
    /// already handles a missing settlement gracefully, but leaving the
    /// record in place — stale, unupdated, but intact — is strictly better
    /// for a claim someone is actively tracking.
    private static func removeSettlementsNoLongerInSeed(
        seedFile: SeedFile,
        existingByID: [String: Settlement],
        context: ModelContext
    ) {
        let seedIDs = Set(seedFile.settlements.map(\.id))
        let claimedSettlementIDs = Set(((try? context.fetch(FetchDescriptor<Claim>())) ?? []).map(\.settlementID))

        for (id, settlement) in existingByID where !seedIDs.contains(id) {
            guard !claimedSettlementIDs.contains(id) else { continue }
            context.delete(settlement)
        }
    }

    /// A settlement's deadline can be corrected by a real-world update
    /// (extended, or moved up) after a user has already started a claim
    /// against it — and `NotificationManager` already scheduled a local
    /// reminder based on the *old* deadline at that point. Without this,
    /// the reminder would silently keep pointing at a date that's no
    /// longer real, which is exactly the kind of confidently-wrong
    /// behavior the rest of this app (see `SourceProvenanceView`) exists
    /// to avoid. `rescheduleReminder` defaults to the real
    /// `NotificationManager` call but is injectable so tests can verify
    /// this without touching `UNUserNotificationCenter`.
    private static func rescheduleRemindersForClaims(
        against settlement: Settlement,
        context: ModelContext,
        reschedule: (Claim, Settlement) -> Void
    ) {
        let settlementID = settlement.id
        let descriptor = FetchDescriptor<Claim>(predicate: #Predicate { $0.settlementID == settlementID })
        let claims = (try? context.fetch(descriptor)) ?? []
        for claim in claims {
            reschedule(claim, settlement)
        }
    }
}
