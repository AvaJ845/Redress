import SwiftUI

/// Shown on every settlement so a user can judge freshness/trust
/// themselves rather than relying on hidden certainty — "per California
/// Attorney General, Aug 20 2026" is more honest than a bare listing.
struct SourceProvenanceView: View {
    let settlement: Settlement

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                if let sourceURL = settlement.sourceURL {
                    Link(destination: sourceURL) {
                        sourceLine
                    }
                } else {
                    sourceLine
                }
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var sourceLine: Text {
        if let date = settlement.sourceDate {
            return Text("Source: \(settlement.sourceName), \(date.formatted(date: .abbreviated, time: .omitted))")
        } else {
            return Text("Source: \(settlement.sourceName)")
        }
    }
}
