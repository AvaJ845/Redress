import SwiftUI

/// Soft-tint circle + SF Symbol, the same "category glyph" treatment iOS
/// system apps (Reminders, Health) use to make list rows scannable without
/// any real imagery — no logos are used since Redress has no rights to
/// reproduce any settlement's brand mark.
struct CategoryIconBadge: View {
    let category: SettlementCategory
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle()
                .fill(category.tint.opacity(0.16))
            Image(systemName: category.systemImage)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(category.tint)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
