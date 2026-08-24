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
///
/// A fixed-width 3-column table only works at normal text sizes — at
/// accessibility Dynamic Type sizes it clips. Switches to a fully
/// vertical, per-plan layout when the user has an accessibility text
/// size set, rather than clipping or truncating.
struct PlanComparisonView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Card {
            if dynamicTypeSize.isAccessibilitySize {
                AccessibilityComparisonList()
            } else {
                CompactComparisonTable()
            }
        }
    }
}

private struct CompactComparisonTable: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("").frame(maxWidth: .infinity, alignment: .leading)
                Text("Free").font(.caption.weight(.semibold)).frame(minWidth: 64)
                Text("Plus").font(.caption.weight(.semibold)).foregroundStyle(.tint).frame(minWidth: 64)
            }
            .accessibilityHidden(true)
            .padding(.bottom, 8)

            ForEach(rows) { row in
                HStack {
                    Text(row.label)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    columnCell(included: row.freeIncluded, text: row.free, plan: "Free")
                        .frame(minWidth: 64)
                    columnCell(included: row.plusIncluded, text: row.plus, plan: "Plus", tinted: true)
                        .frame(minWidth: 64)
                }
                .padding(.vertical, 8)

                if row.id != rows.last?.id {
                    Divider()
                }
            }
        }
    }

    @ViewBuilder
    private func columnCell(included: Bool, text: String, plan: String, tinted: Bool = false) -> some View {
        VStack(spacing: 2) {
            Image(systemName: included ? "checkmark.circle.fill" : "minus.circle")
                .foregroundStyle(included ? (tinted ? Color.accentColor : .green) : .secondary)
                .font(.footnote)
            Text(text)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        // One coherent VoiceOver announcement ("Plus: Unlimited") instead
        // of the icon and text being read as two separate, unlabeled elements.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(plan): \(text)")
    }
}

private struct AccessibilityComparisonList: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            planSection(title: "Free", tinted: false) { $0.free }
            Divider()
            planSection(title: "Plus", tinted: true) { $0.plus }
        }
    }

    @ViewBuilder
    private func planSection(title: String, tinted: Bool, value: @escaping (ComparisonRow) -> String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(tinted ? Color.accentColor : .primary)
            ForEach(rows) { row in
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.label)
                        .font(.subheadline)
                    Text(value(row))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(row.label): \(value(row))")
            }
        }
    }
}
