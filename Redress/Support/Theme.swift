import SwiftUI
import UIKit

/// Brand palette: Deep Emerald + Warm Ivory, replacing the previous
/// dark-teal accent (confirmed via the actual AccentColor asset values —
/// RGB(0.047, 0.290, 0.329) — it really did read as blue/teal, not a
/// deliberate choice worth keeping). Target mix is roughly 75% neutral
/// (ivory/white), 15% emerald (the brand signal — AccentColor itself,
/// see Assets.xcassets), 5% gold (money-specific highlights only, kept
/// rare on purpose), 5% system semantic colors (green reserved for
/// verified/success states, orange for caution, unchanged).
///
/// Dark mode deliberately does NOT try to invert ivory into a tinted
/// dark color — it falls back to Apple's own system backgrounds, which
/// are already contrast-tested, rather than inventing an unverified dark
/// palette from scratch. Only light mode gets the custom warm neutral;
/// the brand signal (AccentColor) is the one color pair actually tuned
/// for both appearances.
enum Theme {
    /// Warm Ivory (#FAF9F5) in light mode; system grouped background in
    /// dark mode.
    static var pageBackground: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.systemGroupedBackground
                : UIColor(red: 0.980, green: 0.976, blue: 0.961, alpha: 1)
        })
    }

    /// White in light mode (cards sit a level above ivory); system
    /// secondary grouped background in dark mode.
    static var cardBackground: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.secondarySystemGroupedBackground
                : UIColor.white
        })
    }

    /// Soft Gold (#E9C46A) — reserved for money-specific highlights only
    /// (the payout callout), never the general brand/action color. Kept
    /// rare so it stays a signal, not decoration.
    static var gold: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.945, green: 0.831, blue: 0.573, alpha: 1) // lightened for dark-background legibility
                : UIColor(red: 0.914, green: 0.769, blue: 0.416, alpha: 1)
        })
    }

    /// Fresh Mint (#DDF4EA) — the lightest emerald tint, for subtle
    /// highlight backgrounds. Falls back to a dark desaturated-green
    /// tint in dark mode rather than a literal mint (which wouldn't
    /// read correctly against a dark background).
    static var mintTint: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.086, green: 0.200, blue: 0.165, alpha: 1)
                : UIColor(red: 0.867, green: 0.957, blue: 0.918, alpha: 1)
        })
    }
}
