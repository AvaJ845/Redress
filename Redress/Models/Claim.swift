import Foundation
import SwiftData

@Model
final class Claim {
    @Attribute(.unique) var id: UUID
    var settlementID: String
    var settlementTitle: String
    var statusRaw: String
    var filedDate: Date?
    var estimatedPayout: Double?
    var actualPayout: Double?
    var notes: String
    var documentFileNames: [String]
    var createdDate: Date

    var status: ClaimStatus {
        get { ClaimStatus(rawValue: statusRaw) ?? .discovered }
        set { statusRaw = newValue.rawValue }
    }

    init(settlementID: String, settlementTitle: String) {
        self.id = UUID()
        self.settlementID = settlementID
        self.settlementTitle = settlementTitle
        self.statusRaw = ClaimStatus.discovered.rawValue
        self.filedDate = nil
        self.estimatedPayout = nil
        self.actualPayout = nil
        self.notes = ""
        self.documentFileNames = []
        self.createdDate = Date()
    }
}
