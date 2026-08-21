import SwiftUI

extension ClaimStatus {
    var badgeIcon: String {
        switch self {
        case .discovered: return "circle"
        case .filed: return "paperplane.fill"
        case .underReview: return "hourglass"
        case .appealPeriod: return "exclamationmark.triangle.fill"
        case .paid: return "checkmark.seal.fill"
        case .rejected: return "xmark.seal.fill"
        }
    }

    var badgeTint: Color {
        switch self {
        case .discovered: return .secondary
        case .filed: return .blue
        case .underReview: return .orange
        case .appealPeriod: return .yellow
        case .paid: return .green
        case .rejected: return .red
        }
    }
}

/// Status is always shown as an icon+text pair, never color alone —
/// color-blind users need the shape, not just the tint, to tell claims apart.
struct ClaimStatusBadge: View {
    let status: ClaimStatus

    var body: some View {
        Label(status.displayName, systemImage: status.badgeIcon)
            .font(.caption.weight(.medium))
            .foregroundStyle(status.badgeTint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.badgeTint.opacity(0.15), in: Capsule())
    }
}
