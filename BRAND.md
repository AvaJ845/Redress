# Redress Brand Guide

On-device personal settlement assistant. Emerald / Money Green palette. No “free money” or rewards-app visual language.

## Palette

| Token | Hex | Role |
|---|---|---|
| Deep Emerald | `#0B6B50` | Primary brand accent, actions, icon checkmark. |
| Fresh Mint | `#DDF4EA` | Subtle highlight backgrounds. |
| Warm Ivory | `#FAF9F5` | Light-mode page background. |
| Ink | `#17211D` | High-emphasis text on light backgrounds. |
| Soft Gold | `#E9C46A` | Money-only moments: payouts, recovered total, premium value. |
| System Green | reserved | Verified/success states only (e.g., claim paid, tracking active). |
| White | `#FFFFFF` | Card surfaces on top of Warm Ivory. |

Mix target: ~75% neutral, 15% Deep Emerald, 5% Soft Gold, 5% system semantic colors.

## App icon

The icon is a shield containing a checkmark, with a thin Soft Gold outline and a small gold seal dot at the bottom tip. It ships in three variants in `Redress/Assets.xcassets/AppIcon.appiconset/`:

- `AppIcon-light-1024.png` — light mode and App Store
- `AppIcon-dark-1024.png` — iOS 18 dark mode
- `AppIcon-tinted-1024.png` — iOS 18 tinted mode

Regenerate all three from `Tools/make_icon.py`.

## Launch screen

`Redress/Assets.xcassets/LaunchLogo.imageset/` contains a centered shield glyph for the launch screen. `Redress/App/Info.plist` references it via `UILaunchScreen` / `UIImageName`. The background color is `LaunchBackground`.

## In-app color tokens

Use `Theme.pageBackground`, `Theme.cardBackground`, `Theme.gold`, `Theme.mintTint`, and `Theme.ink` from `Redress/Support/Theme.swift`. Do not use `Theme.gold` for buttons, links, or navigation — only for money-specific callouts.

## Typography

Use the system font stack. Hierarchy:

- Large titles: `.largeTitle.bold()` in `Theme.ink`
- Headlines: `.headline` or `.title2.bold()` in `Theme.ink`
- Body: `.body` in `.primary`
- Metadata: `.caption` in `.secondary`
- Money labels: `.subheadline.weight(.semibold)` in `Theme.gold`

## What to avoid

- Coin stacks, dollar bills, wallet icons, or confetti as primary branding.
- Purple, orange, or terracotta gradients.
- “Free money,” “guaranteed,” or “earn” language.
- Using Soft Gold for general UI chrome.
- Using color alone to indicate status — always pair icon + text.

## Regenerating assets

```bash
python3 Tools/make_icon.py
```

The generator is portable and writes to `Redress/Assets.xcassets/AppIcon.appiconset/` relative to the repo root.
