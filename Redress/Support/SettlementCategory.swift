import SwiftUI

/// Best-effort visual categorization from case text — purely cosmetic (an
/// icon + tint so list rows are scannable at a glance), never used for
/// eligibility, trust, or any decision a user relies on. Falls back to a
/// neutral "legal" icon when nothing matches, so an unrecognized case
/// never renders as visually broken.
enum SettlementCategory {
    case dataBreach
    case financial
    case pharmaceutical
    case telecom
    case consumer
    case general

    static func classify(title: String, brand: String, description: String) -> SettlementCategory {
        let text = "\(title) \(brand) \(description)".lowercased()
        if text.contains("data breach") || text.contains("cybersecurity") || text.contains("privacy") {
            return .dataBreach
        }
        if text.contains("securities") || text.contains("mutual fund") || text.contains("cash sweep") || text.contains("investment") {
            return .financial
        }
        if text.contains("pharmaceutical") || text.contains("duloxetine") || text.contains(" drug") || text.contains("recall") || text.contains("medication") {
            return .pharmaceutical
        }
        if text.contains("xfinity") || text.contains("comcast") || text.contains("cable") || text.contains("wireless") || text.contains("telecom") {
            return .telecom
        }
        if text.contains("tan") || text.contains("forklift") || text.contains("retail") || text.contains("purchase") {
            return .consumer
        }
        return .general
    }

    var systemImage: String {
        switch self {
        case .dataBreach: return "lock.shield.fill"
        case .financial: return "chart.line.uptrend.xyaxis"
        case .pharmaceutical: return "pills.fill"
        case .telecom: return "antenna.radiowaves.left.and.right"
        case .consumer: return "bag.fill"
        case .general: return "building.columns.fill"
        }
    }

    /// Distinct from Theme.gold (reserved for money-specific highlights
    /// only) and from orange (already reserved for urgency/pending-review
    /// semantics elsewhere) — these exist purely to differentiate
    /// categories from one another, not to carry meaning on their own.
    var tint: Color {
        switch self {
        case .dataBreach: return .indigo
        case .financial: return .brown
        case .pharmaceutical: return .purple
        case .telecom: return .teal
        case .consumer: return .pink
        case .general: return .gray
        }
    }
}
