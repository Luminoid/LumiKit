---
description: "LumiKit design system tokens: colors, spacing, typography — never hardcode"
alwaysApply: true
---

# Design Tokens

## Never Hardcode — Always Use Tokens

- **NEVER** hardcode colors, spacing, font sizes, corner radii, or shadow values
- **ALWAYS** use `LMKColor`, `LMKSpacing`, `LMKTypography`, `LMKCornerRadius`, `LMKShadow`, `LMKAlpha`, `LMKLayout`

## Color — Theme-Aware

```swift
// ✅ Good: semantic color via theme
view.backgroundColor = LMKColor.backgroundPrimary
label.textColor = LMKColor.textPrimary

// ❌ Bad: hardcoded
view.backgroundColor = .white
label.textColor = UIColor(red: 0.2, ...)
```

- Colors proxy through `LMKThemeManager.shared.current`
- Apps configure theme at launch: `LMKThemeManager.shared.apply(MyAppTheme())`
- `LMKTheme` protocol defines all semantic colors (primary, secondary, text, background, etc.)

## Spacing — 4pt Grid

| Token | Value |
|-------|-------|
| `LMKSpacing.xs` | 4pt |
| `LMKSpacing.small` | 8pt |
| `LMKSpacing.medium` | 12pt |
| `LMKSpacing.large` | 16pt |
| `LMKSpacing.xl` | 20pt |
| `LMKSpacing.xxl` | 24pt |

- **ALWAYS** use spacing tokens in SnapKit constraints
- Extend `LMKSpacing` for new values — do not introduce magic numbers

## Typography

- `LMKTypography.h1` through `LMKTypography.caption` with line height and letter spacing
- Use `LMKLabelFactory` for creating pre-styled labels

## Layout Constants

- `LMKLayout.minimumTouchTarget` = 44pt (HIG compliance)
- `LMKLayout.iconMedium` = 24pt
- `LMKLayout.pullThreshold` = 80pt

## Factories

- `LMKLabelFactory` — create labels with consistent typography
- `LMKButtonFactory` — create buttons with consistent styling
- `LMKCardFactory` — create card views with consistent shadows/corners
