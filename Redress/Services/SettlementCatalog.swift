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
}

enum SettlementCatalog {
    static func loadSeedIfNeeded(into context: ModelContext) {
        let descriptor = FetchDescriptor<Settlement>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        guard let url = Bundle.main.url(forResource: "SeedSettlements", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }

        let formatter = ISO8601DateFormatter()
        guard let dtos = try? JSONDecoder().decode([SeedSettlementDTO].self, from: data) else { return }

        for dto in dtos {
            let deadline = formatter.date(from: dto.claimDeadline) ?? Date()
            let settlement = Settlement(
                id: dto.id,
                title: dto.title,
                brand: dto.brand,
                settlementDescription: dto.description,
                eligibilityCriteria: dto.eligibilityCriteria,
                proofRequirement: ProofRequirement(rawValue: dto.proofRequirement) ?? .none,
                administratorName: dto.administratorName,
                administratorPortalURLString: dto.administratorPortalURLString,
                claimDeadline: deadline,
                isSampleData: true
            )
            context.insert(settlement)
        }
        context.saveOrLog()
    }
}
