---
description: "LumiKit design system tokens: colors, spacing, typography — never hardcode"
alwaysApply: true
---

# Design Tokens

## Never Hardcode — Always Use Tokens

- **NEVER** hardcode colors, spacing, font sizes, corner radii, shadows, alphas, or layout constants
- **ALWAYS** use `LMKColor`, `LMKSpacing`, `LMKTypography`, `LMKCornerRadius`, `LMKShadow`, `LMKAlpha`, `LMKLayout`

## Architecture: Config Struct -> Proxy Enum -> ThemeManager

```swift
// 1. Config struct (nonisolated, Sendable — safe from any context)
public nonisolated struct LMKSpacingTheme: Sendable { ... }

// 2. Proxy enum (MainActor — accessed from UI code)
public enum LMKSpacing {
    private static var config: LMKSpacingTheme { LMKThemeManager.shared.spacing }
    public static var large: CGFloat { config.large }
}

// 3. App configures at launch
LMKThemeManager.shared.apply(spacing: .init(large: 20))
```

## Color — Theme-Aware

```swift
// ✅ Good: semantic color via theme
view.backgroundColor = LMKColor.backgroundPrimary
label.textColor = LMKColor.textPrimary

// ❌ Bad: hardcoded
view.backgroundColor = .white
label.textColor = UIColor(red: 0.2, ...)
```

- Colors proxy through `LMKThemeManager.shared.current` (conforms to `LMKTheme` protocol)
- Semantic colors: `primary`, `primaryDark`, `secondary`, `success`, `warning`, `error`, `info`
- Background: `backgroundPrimary`, `backgroundSecondary`, `backgroundTertiary`
- Text: `textPrimary`, `textSecondary`, `textTertiary`
- Surface: `divider`, `separator`, `graySoft`, `grayMuted`, `white`, `black`

## Spacing — 4pt Grid

| Token | Value |
|-------|-------|
| `LMKSpacing.xxs` | 2pt |
| `LMKSpacing.xs` | 4pt |
| `LMKSpacing.small` | 8pt |
| `LMKSpacing.medium` | 12pt |
| `LMKSpacing.large` | 16pt |
| `LMKSpacing.xl` | 20pt |
| `LMKSpacing.xxl` | 24pt |
| `LMKSpacing.iconSpacing` | 6pt |
| `LMKSpacing.cardPadding` | Adaptive (device-dependent) |
| `LMKSpacing.cellPaddingVertical` | Adaptive (device-dependent) |

## Typography

Full set of font tokens with configurable font family, sizes, weights, and line heights:

- **Headings**: `LMKTypography.h1`, `.h2`, `.h3`, `.h4`
- **Body**: `.body`, `.bodyMedium`, `.bodyBold`
- **Subbody**: `.subbodyMedium`
- **Caption**: `.caption`, `.captionMedium`
- **Small**: `.small`, `.smallMedium`
- **Extra Small**: `.extraSmall`, `.extraSmallMedium`, `.extraSmallSemibold`
- **Extra Extra Small**: `.extraExtraSmall`, `.extraExtraSmallSemibold`
- **Italic**: `.italicBody`, `.italicCaption`

Use `LMKLabelFactory` for creating pre-styled labels with correct attributed string formatting.

## Alpha

| Token | Default | Purpose |
|-------|---------|---------|
| `LMKAlpha.overlay` | 0.4 | Standard overlay |
| `LMKAlpha.overlayStrong` | 0.6 | Strong overlay |
| `LMKAlpha.overlayOpaque` | 0.85 | Near-opaque overlay |
| `LMKAlpha.disabled` | 0.4 | Disabled state |
| `LMKAlpha.dimmingOverlay` | 0.3 | Dimming background |
| `LMKAlpha.overlayLight` | 0.15 | Subtle overlay |
| `LMKAlpha.overlayDark` | 0.7 | Dark overlay |
| `LMKAlpha.overlayMedium` | 0.5 | Medium overlay |

## Layout Constants

| Token | Default | Purpose |
|-------|---------|---------|
| `LMKLayout.minimumTouchTarget` | 44pt | HIG compliance |
| `LMKLayout.iconExtraSmall` | 16pt | Extra small icons |
| `LMKLayout.iconSmall` | 20pt | Small icons |
| `LMKLayout.iconMedium` | 24pt | Standard icons |
| `LMKLayout.cellHeightMin` | 100pt | Minimum cell height |
| `LMKLayout.searchBarHeight` | 36pt | Search bar height |
| `LMKLayout.searchBarIconSize` | 18pt | Search bar icon |
| `LMKLayout.clearButtonSize` | 22pt | Clear button |
| `LMKLayout.pullThreshold` | 80pt | Pull-to-refresh threshold |

## Corner Radius

| Token | Default |
|-------|---------|
| `LMKCornerRadius.xs` | 4pt |
| `LMKCornerRadius.small` | 8pt |
| `LMKCornerRadius.medium` | 12pt |
| `LMKCornerRadius.large` | 16pt |
| `LMKCornerRadius.xl` | 20pt |

## Shadow Presets

- `LMKShadow.cellCard()` — subtle cell shadow
- `LMKShadow.card()` — standard card shadow
- `LMKShadow.button()` — button shadow
- `LMKShadow.small()` — small shadow
- **ALWAYS** use `view.lmk_applyShadow(LMKShadow.card())` to apply

## Animation Duration Tokens

All animation durations are customizable via `LMKAnimationTheme`:

- `LMKAnimationHelper.Duration.buttonPress` (0.1s)
- `Duration.uiShort` / `Duration.photoLoad` (0.15s)
- `Duration.alert` (0.2s)
- `Duration.actionSheet` (0.25s)
- `Duration.modalPresentation` / `Duration.listUpdate` / `Duration.cardTransition` (0.3s)
- `Duration.screenTransition` (0.35s)
- `Duration.errorShake` (0.4s)
- `Duration.successFeedback` (0.5s)
- **ALWAYS** check `LMKAnimationHelper.shouldAnimate` to respect Reduce Motion

## Factories

- `LMKLabelFactory` — labels with typography tokens and attributed string formatting
- `LMKButtonFactory` — primary, secondary, destructive, warning buttons
- `LMKCardFactory` — card views with shadow and corner radius
