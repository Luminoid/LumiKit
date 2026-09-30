---
description: "LumiKit design system: tokens, the LMKTheme value, the Style pattern; never hard-code values, never read the theme store inside components"
alwaysApply: true
---

# Design Tokens and Styles

## Never Hard-Code, Always Tokens

- **NEVER** hard-code colors, spacing, font sizes, corner radii, shadows, alphas, or layout constants
- **ALWAYS** use `LMKColor`, `LMKTextStyle` (through `lmk_apply` / `UILabel.lmk_make`), `LMKSpacing`, `LMKCornerRadius` / `LMKCornerStyle`, `LMKShadow`, `LMKAlpha`, `LMKLayout`
- **NEVER** set `.font =` on a label, field, or text view; `lmk_apply(_ style: LMKTextStyle, color:)` scales with Dynamic Type and re-applies on theme changes
- Heights are floors (`greaterThanOrEqualTo`), never fixed values

## The Theme Is a Value

```swift
extension LMKTheme { static let myApp = LMKTheme(colors: LMKColorTheme(primary: .systemIndigo)) }
LMKTheme.apply(.myApp)                        // re-renders every window
LMKTheme.update { $0.chip.variant = .filled } // app-wide default for one component
LMKTheme.current.spacing.large                // nonisolated read
```

- `LMKColor.*` are dynamic colors resolved through the `lmkTheme` trait: a view holding one re-resolves on theme, dark mode, and Increase Contrast changes
- `CGColor` sinks go through `lmk_applyShadow` / `lmk_applyBorder`, which re-stamp on trait changes
- **NEVER** read `LMKTheme.current` inside `Components/` or `Controls/` (SwiftLint `no_theme_store_in_components`); resolve against the `theme` passed to `applyTheme(_:)` so per-window scoping works
- Preview a theme in one window with `window.traitOverrides.lmkTheme = LMKThemeReference(candidate)`

## The Style Pattern

Every component has a nested `Style`:

```swift
public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
    public var variant: Variant?                 // nil = the theme decides
    public var surface = LMKSurfaceStyle()       // background, corners, border, shadow, contentInsets
    public var highlighted, selected, disabled, focused: LMKControlStateStyle?   // controls only
    public static let defaultValue = Style()
    public func merging(_ other: Style) -> Style // other's non-nil fields win
}
public var style = Style() { didSet { applyTheme(traitCollection.lmkTheme) } }
public func applyTheme(_ theme: LMKTheme) { let resolved = theme.<slot>.merging(style); /* every appearance assignment */ didApplyStyle?(self) }
```

- A value is a Style field when a designer decides it and it has no side effect beyond appearance; it stays a property when it is content or runtime state
- Presets set only their variant and never read tokens
- Every component exposes its structural subviews and a `didApplyStyle` hook; `applyTheme(_:)` is idempotent and is the only place that assigns appearance
- Call `lmk_startApplyingTheme()` last in `init` (views) or in `viewDidLoad` (view controllers)

## Token Reference

| Category | Enum | Theme struct | Values |
|---|---|---|---|
| Colors | `LMKColor` | `LMKColorTheme` | `primary`, `primaryVariant`, `secondary`, `tertiary`, `success`, `warning`, `error`, `info`, `onAccent`, `textPrimary/Secondary/Tertiary`, `link`, `backgroundPrimary/Secondary/Tertiary`, `divider`, `outline`, `fill`, `fillStrong`, `scrim`, `pressedOverlay`, `selection`; `highContrastBoost` |
| Typography | `LMKTypography` / `LMKTextStyle` | `LMKTypographyTheme` | `h1`...`h4`, `body`, `bodyMedium`, `bodyBold`, `subbodyMedium`, `caption`, `captionMedium`, `small`, `smallMedium`, extra-small steps, italics, `custom(LMKFontSpec)`; `maximumScale` |
| Spacing | `LMKSpacing` | `LMKSpacingTheme` | `xxs` 2, `xs` 4, `small` 8, `medium` 12, `large` 16, `xl` 20, `xxl` 24; `cardPadding` / `cellPaddingVertical` tier by canvas |
| Corner radius | `LMKCornerRadius` / `LMKCornerStyle` | `LMKCornerRadiusTheme` | `xs` 4, `small` 8, `medium` 12, `large` 16, `xl` 20, `xxl` 40; styles `none`, `fixed`, `capsule`, `circle`, `concentric(minimum:)` |
| Alpha | `LMKAlpha` | `LMKAlphaTheme` | `xxs` 0.10, `xs` 0.15, `small` 0.20, `medium` 0.30, `large` 0.50, `xl` 0.70, `xxl` 0.80; `dimming` 0.40, `disabled` 0.38 |
| Shadow | `LMKShadow` | `LMKShadowTheme` | `LMKShadow.Level` `level1`...`level5`, `style(for:)`, `iconOverlayOpacity`; apply with `lmk_applyShadow(_:)` |
| Layout | `LMKLayout` | `LMKLayoutTheme` | `minimumTouchTarget` 44, `iconExtraSmall/Small/Medium/Large`, `iconCircle`, `symbolMicro`...`symbolHero`, `rowHeightCompact/rowHeight/rowHeightComfortable/rowHeightEstimated`, `readableContentMaxWidth`, `hairline(for:)` (display physics, not themeable) |
| Animation | `LMKAnimation` | `LMKAnimationTheme` | `Duration.instant/fast/normal/moderate/slow/emphasis/shimmer`, `spring`, `pressSpring`, `pressScale`, `Curve`; **ALWAYS** check `LMKAnimation.shouldAnimate` |

- Every component's `Style` is also a slot on the theme (`theme.button`, `theme.chip`, `theme.navigationBar`, ...); app-defined values conform to `LMKThemeExtension` and live in `theme[MyType.self]`
