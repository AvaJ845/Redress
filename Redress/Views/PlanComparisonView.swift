import SwiftUI

private struct ComparisonRow: Identifiable {
    let id = UUID()
    let label: String
    let free: String
    let plus: String
    let freeIncluded: Bool
    let plusIncluded: Bool
}

private let rows: [ComparisonRow] = [
    ComparisonRow(label: "Browse open settlements", free: "Unlimited", plus: "Unlimited",
                   freeIncluded: true, plusIncluded: true),
    ComparisonRow(label: "Track a claim", free: "1 at a time", plus: "Unlimited",
                   freeIncluded: true, plusIncluded: true),
    ComparisonRow(label: "Encrypted document vault", free: "—", plus: "Included",
                   freeIncluded: false, plusIncluded: true),
    ComparisonRow(label: "Deadline reminders", free: "Your 1 claim", plus: "Every claim",
                   freeIncluded: true, plusIncluded: true),
    ComparisonRow(label: "Payout & value tracking", free: "—", plus: "Included",
                   freeIncluded: false, plusIncluded: true),
]

/// Built to make the paid tier's actual value legible at a glance, not
/// to talk anyone into it — every row is something Plus genuinely does
/// that Free doesn't, no padding rows for the sake of a longer list.
struct PlanComparisonView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("").frame(maxWidth: .infinity, alignment: .leading)
                Text("Free").font(.caption.weight(.semibold)).frame(width: 64)
                Text("Plus").font(.caption.weight(.semibold)).foregroundStyle(.tint).frame(width: 64)
            }
            .padding(.bottom, 8)

            ForEach(rows) { row in
                HStack {
                    Text(row.label)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    columnCell(included: row.freeIncluded, text: row.free)
                        .frame(width: 64)
                    columnCell(included: row.plusIncluded, text: row.plus, tinted: true)
                        .frame(width: 64)
                }
                .padding(.vertical, 8)

                if row.id != rows.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func columnCell(included: Bool, text: String, tinted: Bool = false) -> some View {
        VStack(spacing: 2) {
            Image(systemName: included ? "checkmark.circle.fill" : "minus.circle")
                .foregroundStyle(included ? (tinted ? Color.accentColor : .green) : .secondary)
                .font(.footnote)
            Text(text)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
