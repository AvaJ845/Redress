import Foundation

enum ProofRequirement: String, Codable, CaseIterable {
    case none
    case selfCertify
    case flexibleProof
    case strictProof

    var summary: String {
        switch self {
        case .none:
            return "No documentation needed"
        case .selfCertify:
            return "Certify eligibility — no documents required"
        case .flexibleProof:
            return "Receipt, bank statement, or email confirmation accepted"
        case .strictProof:
            return "Itemized receipt or proof of purchase required"
        }
    }
}
