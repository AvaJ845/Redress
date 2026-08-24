import SwiftUI
import UIKit

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
        case .appealPeriod: return Self.appealAmber
        case .paid: return .green
        case .rejected: return .red
        }
    }

    /// Raw `.yellow` as a foreground text color fails contrast on the
    /// app's light card surfaces — a known pitfall with systemYellow in
    /// particular. This is a deeper amber tuned for legible body text
    /// rather than Theme.gold, which is deliberately reserved for
    /// money-specific highlights only (see Theme.swift) and shouldn't be
    /// diluted into a general status color.
    private static var appealAmber: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.945, green: 0.831, blue: 0.573, alpha: 1)
                : UIColor(red: 0.616, green: 0.412, blue: 0.035, alpha: 1)
        })
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
