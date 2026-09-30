# Styling

Every component's appearance is a nested `Style` struct: all-optional fields, a shared surface vocabulary, per-state overrides, and escape hatches for what the Style does not cover.

## The Style pattern

```swift
var chip = LMKChipView.Style()
chip.variant = .filled
chip.tintColor = .systemPink
chip.surface.corners = .fixed(8)
chip.selected = LMKControlStateStyle(foregroundColor: .white)

let view = LMKChipView(title: "Sale", style: chip)
view.style = view.style.merging(.outlined)   // other's non-nil fields win
```

Rules that hold for every component:

- A field is on the Style when a designer decides it and it has no side effect beyond appearance: colors, text styles, radii, insets, sizes, shadow level, border width, variant and size enums, chrome visibility.
- A value stays a property of the instance when it is content or runtime state: text, icons, `isSelected`, `isLoading`, `isEnabled`, handlers, durations, placeholders.
- `nil` means "resolve from the theme at apply time", so a theme switch keeps flowing through fields you did not override.
- Presets (`.filled(.primary)`, `.outlined`, `.elevated`) set only their variant and never read tokens.
- Each Style conforms to ``LMKThemeExtension`` and has a slot on the theme, so `theme.<component>` is the app-wide default.

## The surface vocabulary

``LMKSurfaceStyle`` is embedded in every Style that draws a surface (cards, chips, badges, toasts, tips, sheets, panels, text fields, the navigation bar, list rows, calendar cells, and more):

| Field | Type | Options |
|---|---|---|
| `background` | ``LMKBackgroundStyle`` | `clear`, `solid(color)`, `gradient(colors:direction:locations:)`, `blur(style)`, `glass(variant, tint:)` |
| `corners` | ``LMKCornerStyle`` | `none`, `fixed(radius, corners:curve:)`, `capsule`, `circle`, `concentric(minimum:)` |
| `border` | ``LMKBorderStyle`` | `solid(color, width:)`, `dashed(pattern, color:width:)`, an `inset` for a stroke inside the bounds |
| `shadow` | ``LMKShadowSource`` | `none`, `level(.level1 ... .level5)`, `custom(LMKShadowStyle)` |
| `contentInsets` | `NSDirectionalEdgeInsets` | Padding around the content |

`UIView.lmk_apply(surface:defaults:)` applies one to any view: it installs the background (a color, a gradient layer, or an effect view), applies the corner style, and routes border and shadow through the re-stamping layer helpers. When a masking corner and a shadow are both present, the shadow goes on the view's layer and the content is clipped by an inner container.

## Per-state overrides

Controls carry ``LMKControlStateStyle`` fields named `highlighted`, `selected`, `disabled`, and `focused`. Each has optional `background`, `foregroundColor`, `border`, `alpha`, `scale`, and `shadow`; a `nil` state derives from the base look (a darkened background while pressed, the disabled alpha, and so on). Text inputs use the same idea keyed by ``LMKValidationState``: ``LMKTextInputStyle`` holds a state style for normal, focused, warning, error, and success.

## Text

Text never sets `.font` directly. `lmk_apply(_:color:)` on `UILabel`, `UITextField`, and `UITextView` takes an ``LMKTextStyle`` (`h1` to `h4`, `body`, `bodyMedium`, `bodyBold`, `subbodyMedium`, `caption`, `captionMedium`, `small`, `smallMedium`, the extra-small steps, italics, or `custom(LMKFontSpec)`), turns on Dynamic Type scaling, applies line height and kerning, and re-applies on theme and content-size changes. ``LMKTypographyTheme/maximumScale`` caps chrome at accessibility sizes. Heights in the kit are floors, never fixed values.

## Escape hatches

1. Every component exposes its structural subviews as `public private(set)` (`titleLabel`, `iconView`, `contentView`, `backgroundView`, ...).
2. Every component has `didApplyStyle: ((Self) -> Void)?`, invoked at the end of `applyTheme(_:)` and therefore re-run on every theme, dark mode, contrast, and text-size change. A host tweak placed there survives a theme switch.
3. `applyTheme(_:)` is `open` on the `open` classes (the base controllers, `LMKButton`, `LMKCalendarDayCell`).
4. `Style.merging(_:)` builds hierarchies: `base.merging(.outlined).merging(brandOverrides)`.

## Writing a component

Conform to ``LMKThemeApplying``, resolve everything in `applyTheme(_:)`, and call `lmk_startApplyingTheme()` as the last line of `init`:

```swift
public final class TagView: UIView, LMKThemeApplying {
    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        public var surface = LMKSurfaceStyle()
        public var textStyle: LMKTextStyle?
        public static let defaultValue = Style()
        public func merging(_ other: Style) -> Style { /* other's non-nil fields win */ }
    }

    public var style = Style() { didSet { applyTheme(traitCollection.lmkTheme) } }
    public private(set) lazy var label = UILabel()
    public var didApplyStyle: ((TagView) -> Void)?

    public init(style: Style = Style()) {
        self.style = style
        super.init(frame: .zero)
        addSubview(label)
        lmk_startApplyingTheme()
    }

    public func applyTheme(_ theme: LMKTheme) {
        let resolved = theme[Style.self].merging(style)
        lmk_apply(surface: resolved.surface, defaults: LMKSurfaceStyle(corners: .capsule))
        label.lmk_apply(resolved.textStyle ?? .captionMedium)
        didApplyStyle?(self)
    }
}
```
