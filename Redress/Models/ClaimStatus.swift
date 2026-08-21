import Foundation

enum ClaimStatus: String, Codable, CaseIterable {
    case discovered
    case filed
    case underReview
    case appealPeriod
    case paid
    case rejected

    var displayName: String {
        switch self {
        case .discovered: return "Not yet filed"
        case .filed: return "Filed"
        case .underReview: return "Under review"
        case .appealPeriod: return "Appeal period"
        case .paid: return "Paid"
        case .rejected: return "Rejected"
        }
    }

    var isTerminal: Bool {
        self == .paid || self == .rejected
    }
}
