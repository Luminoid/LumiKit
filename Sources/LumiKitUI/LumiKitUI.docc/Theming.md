# Theming

One `LMKTheme` value carries every token category and the app-wide default `Style` of every component; applying it re-renders every window.

## The theme value

``LMKTheme`` is a `nonisolated` `Sendable` struct with nine categories:

| Property | Type | What it holds |
|---|---|---|
| `colors` | ``LMKColorTheme`` | Accent, text, background, and surface roles plus `highContrastBoost` |
| `typography` | ``LMKTypographyTheme`` | Font family or system design (`fontDesign`, `headingFontDesign`), sizes, weights, line heights, letter spacing, `maximumScale` |
| `spacing` | ``LMKSpacingTheme`` | The 4pt grid (`xxs` to `xxl`) and the canvas-tiered paddings |
| `cornerRadius` | ``LMKCornerRadiusTheme`` | `xs` to `xxl` |
| `shadow` | ``LMKShadowTheme`` | `level1` to `level5` and `iconOverlayOpacity` |
| `alpha` | ``LMKAlphaTheme`` | The seven-step ramp plus `dimming` and `disabled` |
| `layout` | ``LMKLayoutTheme`` | Touch target, icon and symbol scales, row heights, readable width |
| `animation` | ``LMKAnimationTheme`` | Seven durations, springs, press scale, default curve |
| `extensions` | ``LMKThemeExtensions`` | Type-keyed storage for component defaults and app-defined values |

Every initializer defaults every field, so an app theme names only what differs:

```swift
extension LMKTheme {
    static let myApp = LMKTheme(
        colors: LMKColorTheme(primary: .systemIndigo, onAccent: .white),
        typography: LMKTypographyTheme(fontFamily: "Inter"),
        spacing: LMKSpacingTheme(large: 20)
    )
}
```

A theme that keeps the system font can change its design instead of its family: `LMKTypographyTheme(fontDesign: .rounded)` draws every step in SF Rounded, and `headingFontDesign` limits a design to the heading steps.

## Applying and observing

- ``LMKTheme/apply(_:)`` stores the theme, stamps it onto every window of every connected scene, and notifies observers.
- ``LMKTheme/update(_:)`` copies the current theme, lets you mutate it, and applies the result.
- ``LMKTheme/reset()`` restores ``LMKTheme/default``.
- ``LMKTheme/current`` reads the process-wide theme from any isolation.
- ``LMKTheme/observe(_:)`` and ``LMKTheme/updates`` deliver each applied theme to a closure or an `AsyncStream`. Keep the ``LMKThemeObservation`` that `observe` returns: releasing it ends the observation.

## How propagation works

`apply` writes an ``LMKThemeReference`` into `window.traitOverrides.lmkTheme` (``LMKThemeTrait``). The trait is marked as affecting color appearance, so UIKit re-resolves every dynamic color in the window. Each ``LMKColor`` token is such a dynamic color, which is why a label holding `LMKColor.primary` follows the new theme with no re-assignment. Components conform to ``LMKThemeApplying``: `lmk_startApplyingTheme()` registers for the theme and content-size-category traits, and `applyTheme(_:)` resolves the component's `Style` against the theme passed in.

Layer colors (`CGColor` on shadows and borders) cannot re-resolve on their own. `lmk_applyShadow(_:)` and `lmk_applyBorder(color:width:)` keep their sources and re-stamp on theme, dark mode, and contrast changes.

## Component defaults

The theme has a slot for every component (`theme.button`, `theme.chip`, `theme.navigationBar`, `theme.toast`, `theme.monthCalendar`, and so on). Setting a field there changes the default for every instance that leaves the field `nil`:

```swift
LMKTheme.update { theme in
    theme.button.variant = .tinted
    theme.card.surface.shadow = .level(.level2)
    theme.toast.showsIcon = false
}
```

The cascade is token, then `theme.<component>`, then the instance's `style`. A component resolves every value against the theme handed to `applyTheme(_:)`, including spacing and sizes (`theme.spacing`, `theme.layout`), so a theme stamped on one window or subtree reaches its constraints too.

## App-defined values

Anything the kit has no vocabulary for conforms to ``LMKThemeExtension`` and lives on the theme without LumiKit knowing about it:

```swift
struct MyAccents: LMKThemeExtension {
    static let defaultValue = MyAccents()
    var favorite: UIColor = .systemPink
}

LMKTheme.update { $0[MyAccents.self].favorite = .systemOrange }
let favorite = LMKTheme.current[MyAccents.self].favorite
```

## Previewing a theme in one window

Stamp a reference on a window or a subtree instead of the process:

```swift
previewWindow.traitOverrides.lmkTheme = LMKThemeReference(candidate)
```

Detached views ignore trait overrides until they are in a window, and a window created outside a scene needs `LMKTheme.currentReference` stamped by hand.

## Increase Contrast

Accent colors apply `LMKColorTheme.highContrastBoost` when the trait collection's `accessibilityContrast` is high. Text drawn on a tinted fill goes through ``LMKColor/onFill(_:preferred:)``, which returns the preferred color normally and a black-or-white contrasting color under Increase Contrast.
